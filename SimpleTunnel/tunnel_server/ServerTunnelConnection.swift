/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ServerTunnelConnection class. The ServerTunnelConnection class handles the encapsulation and decapsulation of IP packets in the server side of the SimpleTunnel tunneling protocol.
*/

import Foundation
import Darwin

/// An object that provides a bridge between a logical flow of packets in the SimpleTunnel protocol and a UTUN interface.
class ServerTunnelConnection: Connection {

	// MARK: Properties

	/// The virtual address of the tunnel.
	var tunnelAddress: String?

	/// The name of the UTUN interface.
	var utunName: String?

	/// A dispatch source for the UTUN interface socket.
	var utunSource: dispatch_source_t?

	/// A flag indicating if reads from the UTUN interface are suspended.
	var isSuspended = false

	// MARK: Interface

	/// Send an "open result" message with optionally the tunnel settings.
	func sendOpenResult(result: TunnelConnectionOpenResult, extraProperties: [String: AnyObject] = [:]) {
		guard let serverTunnel = tunnel else { return }

		var resultProperties = extraProperties
		resultProperties[TunnelMessageKey.ResultCode.rawValue] = result.rawValue

		let properties = createMessagePropertiesForConnection(identifier, commandType: .OpenResult, extraProperties: resultProperties)

		serverTunnel.sendMessage(properties)
	}

	/// "Open" the connection by setting up the UTUN interface.
	func open() -> Bool {

		// Allocate the tunnel virtual address.
		guard let address = ServerTunnel.configuration.addressPool?.allocateAddress() else {
			simpleTunnelLog("Failed to allocate a tunnel address")
			sendOpenResult(.Refused)
			return false
		}

		// Create the virtual interface and assign the address.
		guard setupVirtualInterface(address) else {
			simpleTunnelLog("Failed to set up the virtual interface")
			ServerTunnel.configuration.addressPool?.deallocateAddress(address)
			sendOpenResult(.InternalError)
			return false
		}

		tunnelAddress = address

		var response = [String: AnyObject]()

		// Create a copy of the configuration, so that it can be personalized with the tunnel virtual interface.
		var personalized = ServerTunnel.configuration.configuration
		guard let IPv4Dictionary = personalized[SettingsKey.IPv4.rawValue] as? [NSObject: AnyObject] else {
			simpleTunnelLog("No IPv4 Settings available")
			sendOpenResult(.InternalError)
			return false
		}

		// Set up the "IPv4" sub-dictionary to contain the tunne virtual address and network mask.
		var newIPv4Dictionary = IPv4Dictionary
		newIPv4Dictionary[SettingsKey.Address.rawValue] = tunnelAddress
		newIPv4Dictionary[SettingsKey.Netmask.rawValue] = "255.255.255.255"
		personalized[SettingsKey.IPv4.rawValue] = newIPv4Dictionary
		response[TunnelMessageKey.Configuration.rawValue] = personalized

		// Send the personalized configuration along with the "open result" message.
		sendOpenResult(.Success, extraProperties: response)

		return true
	}

	/// Create a UTUN interface.
	func createTUNInterface() -> Int32 {

		let utunSocket = socket(PF_SYSTEM, SOCK_DGRAM, SYSPROTO_CONTROL)
		guard utunSocket >= 0 else {
			simpleTunnelLog("Failed to open a kernel control socket")
			return -1
		}

		let controlIdentifier = getUTUNControlIdentifier(utunSocket)
		guard controlIdentifier > 0 else {
			simpleTunnelLog("Failed to get the control ID for the utun kernel control")
			close(utunSocket)
			return -1
		}

		// Connect the socket to the UTUN kernel control.
		var socketAddressControl = sockaddr_ctl(sc_len: UInt8(sizeof(sockaddr_ctl.self)), sc_family: UInt8(AF_SYSTEM), ss_sysaddr: UInt16(AF_SYS_CONTROL), sc_id: controlIdentifier, sc_unit: 0, sc_reserved: (0, 0, 0, 0, 0))

		let connectResult = withUnsafePointer(&socketAddressControl) {
			connect(utunSocket, UnsafePointer<sockaddr>($0), socklen_t(sizeofValue(socketAddressControl)))
		}

		if let errorString = String(UTF8String: strerror(errno)) where connectResult < 0 {
			simpleTunnelLog("Failed to create a utun interface: \(errorString)")
			close(utunSocket)
			return -1
		}

		return utunSocket
	}

	/// Get the name of a UTUN interface the associated socket.
	func getTUNInterfaceName(utunSocket: Int32) -> String? {
		var buffer = [Int8](count: Int(IFNAMSIZ), repeatedValue: 0)
		var bufferSize: socklen_t = socklen_t(buffer.count)
		let resultCode = getsockopt(utunSocket, SYSPROTO_CONTROL, getUTUNNameOption(), &buffer, &bufferSize)
		if let errorString = String(UTF8String: strerror(errno)) where resultCode < 0 {
			simpleTunnelLog("getsockopt failed while getting the utun interface name: \(errorString)")
			return nil
		}
		return String(UTF8String: &buffer)
	}

	/// Set up the UTUN interface, start reading packets.
	func setupVirtualInterface(address: String) -> Bool {
		let utunSocket = createTUNInterface()
		guard let interfaceName = getTUNInterfaceName(utunSocket)
			where utunSocket >= 0 &&
			setUTUNAddress(interfaceName, address)
			else { return false }

		startTunnelSource(utunSocket)
		utunName = interfaceName
		return true
	}

	/// Read packets from the UTUN interface.
	func readPackets() {
		guard let source = utunSource else { return }
		var packets = [NSData]()
		var protocols = [NSNumber]()

		// We use a 2-element iovec list. The first iovec points to the protocol number of the packet, the second iovec points to the buffer where the packet should be read.
		var buffer = [UInt8](count: Tunnel.packetSize, repeatedValue:0)
		var protocolNumber: UInt32 = 0
		var iovecList = [ iovec(iov_base: &protocolNumber, iov_len: sizeofValue(protocolNumber)), iovec(iov_base: &buffer, iov_len: buffer.count) ]
		let iovecListPointer = UnsafeBufferPointer<iovec>(start: &iovecList, count: iovecList.count)
		let utunSocket = Int32(dispatch_source_get_handle(source))

		repeat {
			let readCount = readv(utunSocket, iovecListPointer.baseAddress, Int32(iovecListPointer.count))

			guard readCount > 0 || errno == EAGAIN else {
				if let errorString = String(UTF8String: strerror(errno)) where readCount < 0 {
					simpleTunnelLog("Got an error on the utun socket: \(errorString)")
				}
				dispatch_source_cancel(source)
				break
			}

			guard readCount > sizeofValue(protocolNumber) else { break }

			if protocolNumber.littleEndian == protocolNumber {
				protocolNumber = protocolNumber.byteSwapped
			}
			protocols.append(NSNumber(unsignedInt: protocolNumber))
			packets.append(NSData(bytes: &buffer, length: readCount - sizeofValue(protocolNumber)))

			// Buffer up packets so that we can include multiple packets per message. Once we reach a per-message maximum send a "packets" message.
			if packets.count == Tunnel.maximumPacketsPerMessage {
				tunnel?.sendPackets(packets, protocols: protocols, forConnection: identifier)
				packets = [NSData]()
				protocols = [NSNumber]()
				if isSuspended { break } // If the entire message could not be sent and the connection is suspended, stop reading packets.
			}
		} while true

		// If there are unsent packets left over, send them now.
		if packets.count > 0 {
			tunnel?.sendPackets(packets, protocols: protocols, forConnection: identifier)
		}
	}

	/// Start reading packets from the UTUN interface.
	func startTunnelSource(utunSocket: Int32) {
		guard setSocketNonBlocking(utunSocket) else { return }
		guard let newSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(utunSocket), 0, dispatch_get_main_queue()) else { return }
		dispatch_source_set_cancel_handler(newSource) {
			close(utunSocket)
			return
		}

		dispatch_source_set_event_handler(newSource) {
			self.readPackets()
		}

		dispatch_resume(newSource)
		utunSource = newSource
	}

	// MARK: Connection

	/// Abort the connection.
	override func abort(error: Int = 0) {
		super.abort(error)
		closeConnection(.All)
	}

	/// Close the connection.
	override func closeConnection(direction: TunnelConnectionCloseDirection) {
		super.closeConnection(direction)

		if currentCloseDirection == .All {
			if utunSource != nil {
				dispatch_source_cancel(utunSource!)
			}
			// De-allocate the address.
			if tunnelAddress != nil {
				ServerTunnel.configuration.addressPool?.deallocateAddress(tunnelAddress!)
			}
			utunName = nil
		}
	}

	/// Stop reading packets from the UTUN interface.
	override func suspend() {
		isSuspended = true
		if let source = utunSource {
			dispatch_suspend(source)
		}
	}

	/// Resume reading packets from the UTUN interface.
	override func resume() {
		isSuspended = false
		if let source = utunSource {
			dispatch_resume(source)
			readPackets()
		}
	}

	/// Write packets and associated protocols to the UTUN interface.
	override func sendPackets(packets: [NSData], protocols: [NSNumber]) {
		guard let source = utunSource else { return }
		let utunSocket = Int32(dispatch_source_get_handle(source))

		for (index, packet) in packets.enumerate() {
			guard index < protocols.count else { break }

			var protocolNumber = protocols[index].unsignedIntValue.bigEndian

			let buffer = UnsafeMutablePointer<Void>(packet.bytes)
			var iovecList = [ iovec(iov_base: &protocolNumber, iov_len: sizeofValue(protocolNumber)), iovec(iov_base: buffer, iov_len: packet.length) ]

			let writeCount = writev(utunSocket, &iovecList, Int32(iovecList.count))
			if writeCount < 0 {
				if let errorString = String(UTF8String: strerror(errno)) {
					simpleTunnelLog("Got an error while writing to utun: \(errorString)")
				}
			}
			else if writeCount < packet.length + sizeofValue(protocolNumber) {
				simpleTunnelLog("Wrote \(writeCount) bytes of a \(packet.length) byte packet to utun")
			}
		}
	}
}

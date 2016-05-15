/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ClientTunnel class. The ClientTunnel class implements the client side of the SimpleTunnel tunneling protocol.
*/

import Foundation
import NetworkExtension

/// Make NEVPNStatus convertible to a string
extension NWTCPConnectionState: CustomStringConvertible {
	public var description: String {
		switch self {
			case .Cancelled: return "Cancelled"
			case .Connected: return "Connected"
			case .Connecting: return "Connecting"
			case .Disconnected: return "Disconnected"
			case .Invalid: return "Invalid"
			case .Waiting: return "Waiting"
		}
	}
}

/// The client-side implementation of the SimpleTunnel protocol.
public class ClientTunnel: Tunnel {

	// MARK: Properties

	/// The tunnel connection.
	public var connection: NWTCPConnection?

	/// The last error that occurred on the tunnel.
	public var lastError: NSError?

	/// The previously-received incomplete message data.
	var previousData: NSMutableData?

	/// The address of the tunnel server.
	public var remoteHost: String?

	// MARK: Interface

	/// Start the TCP connection to the tunnel server.
	public func startTunnel(provider: NETunnelProvider) -> SimpleTunnelError? {

		guard let serverAddress = provider.protocolConfiguration.serverAddress else {
			return .BadConfiguration
		}

		let endpoint: NWEndpoint

		if let colonRange = serverAddress.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: ":"), options: [], range: nil) {
			// The server is specified in the configuration as <host>:<port>.
            
            let hostname = serverAddress.substringWithRange(serverAddress.startIndex..<colonRange.startIndex)
			let portString = serverAddress.substringWithRange(colonRange.startIndex.successor()..<serverAddress.endIndex)

			guard !hostname.isEmpty && !portString.isEmpty else {
				return .BadConfiguration
			}

			endpoint = NWHostEndpoint(hostname:hostname, port:portString)
		}
		else {
			// The server is specified in the configuration as a Bonjour service name.
			endpoint = NWBonjourServiceEndpoint(name: serverAddress, type:Tunnel.serviceType, domain:Tunnel.serviceDomain)
		}

		// Kick off the connection to the server.
		connection = provider.createTCPConnectionToEndpoint(endpoint, enableTLS:false, TLSParameters:nil, delegate:nil)

		// Register for notificationes when the connection status changes.
		connection!.addObserver(self, forKeyPath: "state", options: .Initial, context: &connection)

		return nil
	}

	/// Close the tunnel.
	public func closeTunnelWithError(error: NSError?) {
		lastError = error
		closeTunnel()
	}

	/// Read a SimpleTunnel packet from the tunnel connection.
	func readNextPacket() {
		guard let targetConnection = connection else {
			closeTunnelWithError(SimpleTunnelError.BadConnection as NSError)
			return
		}

		// First, read the total length of the packet.
		targetConnection.readMinimumLength(sizeof(UInt32), maximumLength: sizeof(UInt32)) { data, error in
			if let readError = error {
				simpleTunnelLog("Got an error on the tunnel connection: \(readError)")
				self.closeTunnelWithError(readError)
				return
			}

			guard let lengthData = data else {
				// EOF
				simpleTunnelLog("Got EOF on the tunnel connection")
				self.closeTunnel()
				return
			}

			guard lengthData.length == sizeof(UInt32) else {
				simpleTunnelLog("Length data length (\(lengthData.length)) != sizeof(UInt32) (\(sizeof(UInt32))")
				self.closeTunnelWithError(SimpleTunnelError.InternalError as NSError)
				return
			}

			var totalLength: UInt32 = 0
			lengthData.getBytes(&totalLength, length: sizeof(UInt32))

			if totalLength > UInt32(Tunnel.maximumMessageSize) {
				simpleTunnelLog("Got a length that is too big: \(totalLength)")
				self.closeTunnelWithError(SimpleTunnelError.InternalError as NSError)
				return
			}

			totalLength -= UInt32(sizeof(UInt32))

			// Second, read the packet payload.
			targetConnection.readMinimumLength(Int(totalLength), maximumLength: Int(totalLength)) { data, error in
				if let payloadReadError = error {
					simpleTunnelLog("Got an error on the tunnel connection: \(payloadReadError)")
					self.closeTunnelWithError(payloadReadError)
					return
				}

				guard let payloadData = data else {
					// EOF
					self.closeTunnel()
					return
				}

				guard payloadData.length == Int(totalLength) else {
					simpleTunnelLog("Payload data length (\(payloadData.length)) != payload length (\(totalLength)")
					self.closeTunnelWithError(SimpleTunnelError.InternalError as NSError)
					return
				}

				self.handlePacket(payloadData)

				self.readNextPacket()
			}
		}
	}

	/// Send a message to the tunnel server.
	public func sendMessage(messageProperties: [String: AnyObject], completionHandler: (NSError?) -> Void) {
		guard let messageData = serializeMessage(messageProperties) else {
			completionHandler(SimpleTunnelError.InternalError as NSError)
			return
		}

		connection?.write(messageData, completionHandler: completionHandler)
	}

	// MARK: NSObject

	/// Handle changes to the tunnel connection state.
	public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
		guard keyPath == "state" && UnsafeMutablePointer<NWTCPConnection?>(context).memory == connection else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}

		simpleTunnelLog("Tunnel connection state changed to \(connection!.state)")

		switch connection!.state {
			case .Connected:
				if let remoteAddress = self.connection!.remoteAddress as? NWHostEndpoint {
					remoteHost = remoteAddress.hostname
				}

				// Start reading messages from the tunnel connection.
				readNextPacket()

				// Let the delegate know that the tunnel is open
				delegate?.tunnelDidOpen(self)

			case .Disconnected:
				closeTunnelWithError(connection!.error)

			case .Cancelled:
				connection!.removeObserver(self, forKeyPath:"state", context:&connection)
				connection = nil
				delegate?.tunnelDidClose(self)

			default:
				break
		}
	}

	// MARK: Tunnel

	/// Close the tunnel.
	override public func closeTunnel() {
		super.closeTunnel()
		// Close the tunnel connection.
		if let TCPConnection = connection {
			TCPConnection.cancel()
		}

	}

	/// Write data to the tunnel connection.
	override func writeDataToTunnel(data: NSData, startingAtOffset: Int) -> Int {
		connection?.write(data) { error in
			if error != nil {
				self.closeTunnelWithError(error)
			}
		}
		return data.length
	}

	/// Handle a message received from the tunnel server.
	override func handleMessage(commandType: TunnelCommand, properties: [String: AnyObject], connection: Connection?) -> Bool {
		var success = true

		switch commandType {
			case .OpenResult:
				// A logical connection was opened successfully.
				guard let targetConnection = connection,
					resultCodeNumber = properties[TunnelMessageKey.ResultCode.rawValue] as? Int,
					resultCode = TunnelConnectionOpenResult(rawValue: resultCodeNumber)
					else
				{
					success = false
					break
				}

				targetConnection.handleOpenCompleted(resultCode, properties:properties)

			case .FetchConfiguration:
				guard let configuration = properties[TunnelMessageKey.Configuration.rawValue] as? [String: AnyObject]
					else { break }

				delegate?.tunnelDidSendConfiguration(self, configuration: configuration)
			
			default:
				simpleTunnelLog("Tunnel received an invalid command")
				success = false
		}
		return success
	}

	/// Send a FetchConfiguration message on the tunnel connection.
	public func sendFetchConfiguation() {
		let properties = createMessagePropertiesForConnection(0, commandType: .FetchConfiguration)
		if !sendMessage(properties) {
			simpleTunnelLog("Failed to send a fetch configuration message")
		}
	}
}

/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ClientTunnelConnection class. The ClientTunnelConnection class handles the encapsulation and decapsulation of IP packets in the client side of the SimpleTunnel tunneling protocol.
*/

import Foundation
import SimpleTunnelServices
import NetworkExtension

// MARK: Protocols

/// The delegate protocol for ClientTunnelConnection.
protocol ClientTunnelConnectionDelegate {
	/// Handle the connection being opened.
	func tunnelConnectionDidOpen(connection: ClientTunnelConnection, configuration: [NSObject: AnyObject])
	/// Handle the connection being closed.
	func tunnelConnectionDidClose(connection: ClientTunnelConnection, error: NSError?)
}

/// An object used to tunnel IP packets using the SimpleTunnel protocol.
class ClientTunnelConnection: Connection {

	// MARK: Properties

	/// The connection delegate.
	let delegate: ClientTunnelConnectionDelegate

	/// The flow of IP packets.
	let packetFlow: NEPacketTunnelFlow

	// MARK: Initializers

	init(tunnel: ClientTunnel, clientPacketFlow: NEPacketTunnelFlow, connectionDelegate: ClientTunnelConnectionDelegate) {
		delegate = connectionDelegate
		packetFlow = clientPacketFlow
		let newConnectionIdentifier = arc4random()
		super.init(connectionIdentifier: Int(newConnectionIdentifier), parentTunnel: tunnel)
	}

	// MARK: Interface

	/// Open the connection by sending a "connection open" message to the tunnel server.
	func open() {
		guard let clientTunnel = tunnel as? ClientTunnel else { return }

		let properties = createMessagePropertiesForConnection(identifier, commandType: .Open, extraProperties:[
				TunnelMessageKey.TunnelType.rawValue: TunnelLayer.IP.rawValue
			])

		clientTunnel.sendMessage(properties) { error in
			if let error = error {
				self.delegate.tunnelConnectionDidClose(self, error: error)
			}
		}
	}

	/// Handle packets coming from the packet flow.
	func handlePackets(packets: [NSData], protocols: [NSNumber]) {
		guard let clientTunnel = tunnel as? ClientTunnel else { return }

		let properties = createMessagePropertiesForConnection(identifier, commandType: .Packets, extraProperties:[
				TunnelMessageKey.Packets.rawValue: packets,
				TunnelMessageKey.Protocols.rawValue: protocols
			])

		clientTunnel.sendMessage(properties) { error in
			if let sendError = error {
				self.delegate.tunnelConnectionDidClose(self, error: sendError)
				return
			}

			// Read more packets.
			self.packetFlow.readPacketsWithCompletionHandler { inPackets, inProtocols in
				self.handlePackets(inPackets, protocols: inProtocols)
			}
		}
	}

	/// Make the initial readPacketsWithCompletionHandler call.
	func startHandlingPackets() {
		packetFlow.readPacketsWithCompletionHandler { inPackets, inProtocols in
			self.handlePackets(inPackets, protocols: inProtocols)
		}
	}

	// MARK: Connection

	/// Handle the event of the connection being established.
	override func handleOpenCompleted(resultCode: TunnelConnectionOpenResult, properties: [NSObject: AnyObject]) {
		guard resultCode == .Success else {
			delegate.tunnelConnectionDidClose(self, error: SimpleTunnelError.BadConnection as NSError)
			return
		}

		// Pass the tunnel network settings to the delegate.
		if let configuration = properties[TunnelMessageKey.Configuration.rawValue] as? [NSObject: AnyObject] {
			delegate.tunnelConnectionDidOpen(self, configuration: configuration)
		}
		else {
			delegate.tunnelConnectionDidOpen(self, configuration: [:])
		}
	}

	/// Send packets to the virtual interface to be injected into the IP stack.
	override func sendPackets(packets: [NSData], protocols: [NSNumber]) {
		packetFlow.writePackets(packets, withProtocols: protocols)
	}
}

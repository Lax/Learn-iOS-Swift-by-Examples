/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the PacketTunnelProvider class. The PacketTunnelProvider class is a sub-class of NEPacketTunnelProvider, and is the integration point between the Network Extension framework and the SimpleTunnel tunneling protocol.
*/

import NetworkExtension
import SimpleTunnelServices

/// A packet tunnel provider object.
class PacketTunnelProvider: NEPacketTunnelProvider, TunnelDelegate, ClientTunnelConnectionDelegate {

	// MARK: Properties

	/// A reference to the tunnel object.
	var tunnel: ClientTunnel?

	/// The single logical flow of packets through the tunnel.
	var tunnelConnection: ClientTunnelConnection?

	/// The completion handler to call when the tunnel is fully established.
	var pendingStartCompletion: (NSError? -> Void)?

	/// The completion handler to call when the tunnel is fully disconnected.
	var pendingStopCompletion: (Void -> Void)?

	// MARK: NEPacketTunnelProvider

	/// Begin the process of establishing the tunnel.
	override func startTunnelWithOptions(options: [String : NSObject]?, completionHandler: (NSError?) -> Void) {
		let newTunnel = ClientTunnel()
		newTunnel.delegate = self

		if let error = newTunnel.startTunnel(self) {
			completionHandler(error as NSError)
		}
		else {
			// Save the completion handler for when the tunnel is fully established.
			pendingStartCompletion = completionHandler
			tunnel = newTunnel
		}
	}

	/// Begin the process of stopping the tunnel.
	override func stopTunnelWithReason(reason: NEProviderStopReason, completionHandler: () -> Void) {
		// Clear out any pending start completion handler.
		pendingStartCompletion = nil

		// Save the completion handler for when the tunnel is fully disconnected.
		pendingStopCompletion = completionHandler
		tunnel?.closeTunnel()
	}

	/// Handle IPC messages from the app.
	override func handleAppMessage(messageData: NSData, completionHandler: ((NSData?) -> Void)?) {
		guard let messageString = NSString(data: messageData, encoding: NSUTF8StringEncoding) else {
			completionHandler?(nil)
			return
		}

		simpleTunnelLog("Got a message from the app: \(messageString)")

		let responseData = "Hello app".dataUsingEncoding(NSUTF8StringEncoding)
		completionHandler?(responseData)
	}

	// MARK: TunnelDelegate

	/// Handle the event of the tunnel connection being established.
	func tunnelDidOpen(targetTunnel: Tunnel) {
		// Open the logical flow of packets through the tunnel.
		let newConnection = ClientTunnelConnection(tunnel: tunnel!, clientPacketFlow: packetFlow, connectionDelegate: self)
		newConnection.open()
		tunnelConnection = newConnection
	}

	/// Handle the event of the tunnel connection being closed.
	func tunnelDidClose(targetTunnel: Tunnel) {
		if pendingStartCompletion != nil {
			// Closed while starting, call the start completion handler with the appropriate error.
			pendingStartCompletion?(tunnel?.lastError)
			pendingStartCompletion = nil
		}
		else if pendingStopCompletion != nil {
			// Closed as the result of a call to stopTunnelWithReason, call the stop completion handler.
			pendingStopCompletion?()
			pendingStopCompletion = nil
		}
		else {
			// Closed as the result of an error on the tunnel connection, cancel the tunnel.
			cancelTunnelWithError(tunnel?.lastError)
		}
		tunnel = nil
	}

	/// Handle the server sending a configuration.
	func tunnelDidSendConfiguration(targetTunnel: Tunnel, configuration: [String : AnyObject]) {
	}

	// MARK: ClientTunnelConnectionDelegate

	/// Handle the event of the logical flow of packets being established through the tunnel.
	func tunnelConnectionDidOpen(connection: ClientTunnelConnection, configuration: [NSObject: AnyObject]) {

		// Create the virtual interface settings.
		guard let settings = createTunnelSettingsFromConfiguration(configuration) else {
			pendingStartCompletion?(SimpleTunnelError.InternalError as NSError)
			pendingStartCompletion = nil
			return
		}

		// Set the virtual interface settings.
		setTunnelNetworkSettings(settings) { error in
			var startError: NSError?
			if let error = error {
				simpleTunnelLog("Failed to set the tunnel network settings: \(error)")
				startError = SimpleTunnelError.BadConfiguration as NSError
			}
			else {
				// Now we can start reading and writing packets to/from the virtual interface.
				self.tunnelConnection?.startHandlingPackets()
			}

			// Now the tunnel is fully established, call the start completion handler.
			self.pendingStartCompletion?(startError)
			self.pendingStartCompletion = nil
		}
	}

	/// Handle the event of the logical flow of packets being torn down.
	func tunnelConnectionDidClose(connection: ClientTunnelConnection, error: NSError?) {
		tunnelConnection = nil
		tunnel?.closeTunnelWithError(error)
	}

	/// Create the tunnel network settings to be applied to the virtual interface.
	func createTunnelSettingsFromConfiguration(configuration: [NSObject: AnyObject]) -> NEPacketTunnelNetworkSettings? {
		guard let tunnelAddress = tunnel?.remoteHost,
			address = getValueFromPlist(configuration, keyArray: [.IPv4, .Address]) as? String,
			netmask = getValueFromPlist(configuration, keyArray: [.IPv4, .Netmask]) as? String
			else { return nil }

		let newSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelAddress)
		var fullTunnel = true

		newSettings.IPv4Settings = NEIPv4Settings(addresses: [address], subnetMasks: [netmask])

		if let routes = getValueFromPlist(configuration, keyArray: [.IPv4, .Routes]) as? [[String: AnyObject]] {
			var includedRoutes = [NEIPv4Route]()
			for route in routes {
				if let netAddress = route[SettingsKey.Address.rawValue] as? String,
					netMask = route[SettingsKey.Netmask.rawValue] as? String
				{
					includedRoutes.append(NEIPv4Route(destinationAddress: netAddress, subnetMask: netMask))
				}
			}
			newSettings.IPv4Settings?.includedRoutes = includedRoutes
			fullTunnel = false
		}
		else {
			// No routes specified, use the default route.
			newSettings.IPv4Settings?.includedRoutes = [NEIPv4Route.defaultRoute()]
		}

		if let DNSDictionary = configuration[SettingsKey.DNS.rawValue] as? [String: AnyObject],
			DNSServers = DNSDictionary[SettingsKey.Servers.rawValue] as? [String]
		{
			newSettings.DNSSettings = NEDNSSettings(servers: DNSServers)
			if let DNSSearchDomains = DNSDictionary[SettingsKey.SearchDomains.rawValue] as? [String] {
				newSettings.DNSSettings?.searchDomains = DNSSearchDomains
				if !fullTunnel {
					newSettings.DNSSettings?.matchDomains = DNSSearchDomains
				}
			}
		}

		newSettings.tunnelOverheadBytes = 150

		return newSettings
	}
}

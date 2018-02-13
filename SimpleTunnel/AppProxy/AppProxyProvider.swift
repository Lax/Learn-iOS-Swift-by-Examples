/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the AppProxyProvider class. The AppProxyProvider class is a sub-class of NEAppProxyProvider, and is the integration point between the Network Extension framework and the SimpleTunnel tunneling protocol.
*/

import NetworkExtension
import SimpleTunnelServices

/// A NEAppProxyProvider sub-class that implements the client side of the SimpleTunnel tunneling protocol.
class AppProxyProvider: NEAppProxyProvider, TunnelDelegate {

	// MARK: Properties

	/// A reference to the tunnel object.
	var tunnel: ClientTunnel?

	/// The completion handler to call when the tunnel is fully established.
	var pendingStartCompletion: ((NSError?) -> Void)?

	/// The completion handler to call when the tunnel is fully disconnected.
	var pendingStopCompletion: ((Void) -> Void)?

	// MARK: NEAppProxyProvider

	/// Begin the process of establishing the tunnel.
	override func startProxy(options: [String : Any]?, completionHandler: @escaping (Error?) -> Void) {

		let newTunnel = ClientTunnel()
		newTunnel.delegate = self

		if let error = newTunnel.startTunnel(self) {
			completionHandler(error as NSError)
			return
		}

		pendingStartCompletion = completionHandler
		tunnel = newTunnel
	}

	/// Begin the process of stopping the tunnel.
	override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {

		// Clear out any pending start completion handler.
		pendingStartCompletion = nil

		pendingStopCompletion = completionHandler
		tunnel?.closeTunnel()
	}

	/// Handle a new flow of network data created by an application.
	override func handleNewFlow(_ flow: (NEAppProxyFlow?)) -> Bool {
		var newConnection: ClientAppProxyConnection?

		guard let clientTunnel = tunnel else { return false }

		if let TCPFlow = flow as? NEAppProxyTCPFlow {
			newConnection = ClientAppProxyTCPConnection(tunnel: clientTunnel, newTCPFlow: TCPFlow)
		}
		else if let UDPFlow = flow as? NEAppProxyUDPFlow {
			newConnection = ClientAppProxyUDPConnection(tunnel: clientTunnel, newUDPFlow: UDPFlow)
		}

		guard newConnection != nil else { return false }

		newConnection!.open()

		return true
	}

	// MARK: TunnelDelegate

	/// Handle the event of the tunnel being fully established.
	func tunnelDidOpen(_ targetTunnel: Tunnel) {
		guard let clientTunnel = targetTunnel as? ClientTunnel else {
			pendingStartCompletion?(SimpleTunnelError.internalError as NSError)
			pendingStartCompletion = nil
			return
		}
		simpleTunnelLog("Tunnel opened, fetching configuration")
		clientTunnel.sendFetchConfiguation()
	}

	/// Handle the event of the tunnel being fully disconnected.
	func tunnelDidClose(_ targetTunnel: Tunnel) {

		// Call the appropriate completion handler depending on the current pending tunnel operation.
		if pendingStartCompletion != nil {
			pendingStartCompletion?(tunnel?.lastError)
			pendingStartCompletion = nil
		}
		else if pendingStopCompletion != nil {
			pendingStopCompletion?()
			pendingStopCompletion = nil
		}
		else {
			// No completion handler, so cancel the proxy.
			cancelProxyWithError(tunnel?.lastError)
		}
		tunnel = nil
	}

	/// Handle the server sending a configuration.
	func tunnelDidSendConfiguration(_ targetTunnel: Tunnel, configuration: [String : AnyObject]) {
		simpleTunnelLog("Server sent configuration: \(configuration)")

		guard let tunnelAddress = tunnel?.remoteHost else {
			let error = SimpleTunnelError.badConnection
			pendingStartCompletion?(error as NSError)
			pendingStartCompletion = nil
			return
		}

		guard let DNSDictionary = configuration[SettingsKey.DNS.rawValue] as? [String: AnyObject], let DNSServers = DNSDictionary[SettingsKey.Servers.rawValue] as? [String] else {
			self.pendingStartCompletion?(nil)
			self.pendingStartCompletion = nil
			return
		}

		let newSettings = NETunnelNetworkSettings(tunnelRemoteAddress: tunnelAddress)

		newSettings.dnsSettings = NEDNSSettings(servers: DNSServers)
		if let DNSSearchDomains = DNSDictionary[SettingsKey.SearchDomains.rawValue] as? [String] {
			newSettings.dnsSettings?.searchDomains = DNSSearchDomains
		}

		simpleTunnelLog("Calling setTunnelNetworkSettings")

		self.setTunnelNetworkSettings(newSettings) { error in
			if error != nil {
				let startError = SimpleTunnelError.badConfiguration
				self.pendingStartCompletion?(startError as NSError)
				self.pendingStartCompletion = nil
			}
			else {
				self.pendingStartCompletion?(nil)
				self.pendingStartCompletion = nil
			}
		}
	}
}

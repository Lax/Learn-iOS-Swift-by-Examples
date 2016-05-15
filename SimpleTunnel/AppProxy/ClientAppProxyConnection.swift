/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ClientAppProxyTCPConnection and ClientAppProxyUDPConnection classes. The ClientAppProxyTCPConnection class handles the encapsulation and decapsulation of a stream of application network data in the client side of the SimpleTunnel tunneling protocol. The ClientAppProxyUDPConnection class handles the encapsulation and decapsulation of a sequence of datagrams containing application network data in the client side of the SimpleTunnel tunneling protocol.
*/

import Foundation
import SimpleTunnelServices
import NetworkExtension

/// An object representing the client side of a logical flow of network data in the SimpleTunnel tunneling protocol.
class ClientAppProxyConnection : Connection {

	// MARK: Properties

	/// The NEAppProxyFlow object corresponding to this connection.
	let appProxyFlow: NEAppProxyFlow

	/// A dispatch queue used to regulate the sending of the connection's data through the tunnel connection.
	lazy var queue: dispatch_queue_t = dispatch_queue_create("ClientConnection Handle Data queue", nil)

	// MARK: Initializers

	init(tunnel: ClientTunnel, flow: NEAppProxyFlow) {
		appProxyFlow = flow
		super.init(connectionIdentifier: flow.hash, parentTunnel: tunnel)
	}

	// MARK: Interface

	/// Send an "Open" message to the SimpleTunnel server, to begin the process of establishing a flow of data in the SimpleTunnel protocol.
	func open() {
		open([:])
	}

	/// Send an "Open" message to the SimpleTunnel server, to begin the process of establishing a flow of data in the SimpleTunnel protocol.
	func open(extraProperties: [String: AnyObject]) {
		guard let clientTunnel = tunnel as? ClientTunnel else {
			// Close the NEAppProxyFlow.
			let error: SimpleTunnelError = .BadConnection
			appProxyFlow.closeReadWithError(error as NSError)
			appProxyFlow.closeWriteWithError(error as NSError)
			return
		}

		let properties = createMessagePropertiesForConnection(identifier, commandType:.Open, extraProperties:extraProperties)

		clientTunnel.sendMessage(properties) { error in
			if let error = error {
				// Close the NEAppProxyFlow.
				self.appProxyFlow.closeReadWithError(error)
				self.appProxyFlow.closeWriteWithError(error)
			}
		}
	}

	/// Handle the result of sending a data message to the SimpleTunnel server.
	func handleSendResult(error: NSError?) {
	}

	/// Handle errors that occur on the connection.
	func handleErrorCondition(flowError: NEAppProxyFlowError? = nil, notifyServer: Bool = true) {

		guard !isClosedCompletely else { return }

		tunnel?.sendCloseType(.All, forConnection: identifier)

		closeConnection(.All)
	}

	/// Send a "Data" message to the SimpleTunnel server.
	func sendDataMessage(data: NSData, extraProperties: [String: AnyObject] = [:]) {
		dispatch_async(queue) {

			guard let clientTunnel = self.tunnel as? ClientTunnel else { return }

			// Suspend further writes to the tunnel until this write operation is completed.
			dispatch_suspend(self.queue)

			var dataProperties = extraProperties
			dataProperties[TunnelMessageKey.Data.rawValue] = data

			let properties = createMessagePropertiesForConnection(self.identifier, commandType: .Data, extraProperties:dataProperties)

			clientTunnel.sendMessage(properties) { error in

				// Resume the queue to allow subsequent writes.
				dispatch_resume(self.queue)

				// This will schedule another read operation on the NEAppProxyFlow.
				self.handleSendResult(error)
			}
		}
	}

	// MARK: Connection

	/// Handle the "Open Completed" message received from the SimpleTunnel server for this connection.
	override func handleOpenCompleted(resultCode: TunnelConnectionOpenResult, properties: [NSObject: AnyObject]) {
		guard resultCode == .Success else {
			simpleTunnelLog("Failed to open \(identifier), result = \(resultCode)")
			handleErrorCondition(.PeerReset, notifyServer: false)
			return
		}

		guard let localAddress = (tunnel as? ClientTunnel)?.connection!.localAddress as? NWHostEndpoint else {
			simpleTunnelLog("Failed to get localAddress.")
			handleErrorCondition(.Internal)
			return
		}

		// Now that the SimpleTunnel connection is open, indicate that we are ready to handle data on the NEAppProxyFlow.
		appProxyFlow.openWithLocalEndpoint(localAddress) { error in
			self.handleSendResult(error)
		}
	}

	override func closeConnection(direction: TunnelConnectionCloseDirection) {
		self.closeConnection(direction, flowError: nil)
	}

	func closeConnection(direction: TunnelConnectionCloseDirection, flowError: NEAppProxyFlowError?) {
		super.closeConnection(direction)

		var error: NSError?
		if let ferror = flowError {
			error = NSError(domain: NEAppProxyErrorDomain, code: ferror.rawValue, userInfo: nil)
		}

		if isClosedForWrite {
			appProxyFlow.closeWriteWithError(error)
		}
		if isClosedForRead {
			appProxyFlow.closeReadWithError(error)
		}
	}
}

/// An object representing the client side of a logical flow of TCP network data in the SimpleTunnel tunneling protocol.
class ClientAppProxyTCPConnection : ClientAppProxyConnection {

	// MARK: Properties

	/// The NEAppProxyTCPFlow object corresponding to this connection
	var TCPFlow: NEAppProxyTCPFlow {
		return (appProxyFlow as! NEAppProxyTCPFlow)
	}

	// MARK: Initializers

	init(tunnel: ClientTunnel, newTCPFlow: NEAppProxyTCPFlow) {
		super.init(tunnel: tunnel, flow: newTCPFlow)
	}

	// MARK: ClientAppProxyConnection

	/// Send an "Open" message to the SimpleTunnel server, to begin the process of establishing a flow of data in the SimpleTunnel protocol.
	override func open() {
		open([
				TunnelMessageKey.TunnelType.rawValue: TunnelLayer.App.rawValue,
				TunnelMessageKey.Host.rawValue: (TCPFlow.remoteEndpoint as! NWHostEndpoint).hostname,
				TunnelMessageKey.Port.rawValue: Int((TCPFlow.remoteEndpoint as! NWHostEndpoint).port)!,
				TunnelMessageKey.AppProxyFlowType.rawValue: AppProxyFlowKind.TCP.rawValue
			])
	}

	/// Handle the result of sending a "Data" message to the SimpleTunnel server.
	override func handleSendResult(error: NSError?) {
		if let sendError = error {
			simpleTunnelLog("Failed to send Data Message to the Tunnel Server. error = \(sendError)")
			handleErrorCondition(.HostUnreachable)
			return
		}

		// Read another chunk of data from the source application.
		TCPFlow.readDataWithCompletionHandler { data, readError in
			guard let readData = data where readError == nil else {
				simpleTunnelLog("Failed to read data from the TCP flow. error = \(readError)")
				self.handleErrorCondition(.PeerReset)
				return
			}

			guard readData.length > 0 else {
				simpleTunnelLog("\(self.identifier): received EOF on the TCP flow. Closing the flow...")
				self.tunnel?.sendCloseType(.Write, forConnection: self.identifier)
				self.TCPFlow.closeReadWithError(nil)
				return
			}

			self.sendDataMessage(readData)
		}
	}

	/// Send data received from the SimpleTunnel server to the destination application, using the NEAppProxyTCPFlow object.
	override func sendData(data: NSData) {
		TCPFlow.writeData(data) { error in
			if let writeError = error {
				simpleTunnelLog("Failed to write data to the TCP flow. error = \(writeError)")
				self.tunnel?.sendCloseType(.Read, forConnection: self.identifier)
				self.TCPFlow.closeWriteWithError(nil)
			}
		}
	}
}

/// An object representing the client side of a logical flow of UDP network data in the SimpleTunnel tunneling protocol.
class ClientAppProxyUDPConnection : ClientAppProxyConnection {

	// MARK: Properties

	/// The NEAppProxyUDPFlow object corresponding to this connection.
	var UDPFlow: NEAppProxyUDPFlow {
		return (appProxyFlow as! NEAppProxyUDPFlow)
	}

	/// The number of "Data" messages scheduled to be written to the tunnel that have not been actually sent out on the network yet.
	var datagramsOutstanding = 0

	// MARK: Initializers

	init(tunnel: ClientTunnel, newUDPFlow: NEAppProxyUDPFlow) {
		super.init(tunnel: tunnel, flow: newUDPFlow)
	}

	// MARK: ClientAppProxyConnection

	/// Send an "Open" message to the SimpleTunnel server, to begin the process of establishing a flow of data in the SimpleTunnel protocol.
	override func open() {
		open([
				TunnelMessageKey.TunnelType.rawValue: TunnelLayer.App.rawValue,
				TunnelMessageKey.AppProxyFlowType.rawValue: AppProxyFlowKind.UDP.rawValue
			])
	}

	/// Handle the result of sending a "Data" message to the SimpleTunnel server.
	override func handleSendResult(error: NSError?) {

		if let sendError = error {
			simpleTunnelLog("Failed to send message to Tunnel Server. error = \(sendError)")
			handleErrorCondition(.HostUnreachable)
			return
		}

		if datagramsOutstanding > 0 {
			datagramsOutstanding -= 1
		}

		// Only read more datagrams from the source application if all outstanding datagrams have been sent on the network.
		guard datagramsOutstanding == 0 else { return }

		// Read a new set of datagrams from the source application.
		UDPFlow.readDatagramsWithCompletionHandler { datagrams, remoteEndPoints, readError in

			guard let readDatagrams = datagrams,
				readEndpoints = remoteEndPoints
				where readError == nil else
			{
				simpleTunnelLog("Failed to read data from the UDP flow. error = \(readError)")
				self.handleErrorCondition(.PeerReset)
				return
			}

			guard !readDatagrams.isEmpty && readEndpoints.count == readDatagrams.count else {
				simpleTunnelLog("\(self.identifier): Received EOF on the UDP flow. Closing the flow...")
				self.tunnel?.sendCloseType(.Write, forConnection: self.identifier)
				self.UDPFlow.closeReadWithError(nil)
				return
			}

			self.datagramsOutstanding = readDatagrams.count

			for (index, datagram) in readDatagrams.enumerate() {
				guard let endpoint = readEndpoints[index] as? NWHostEndpoint else { continue }

				simpleTunnelLog("(\(self.identifier)): Sending a \(datagram.length)-byte datagram to \(endpoint.hostname):\(endpoint.port)")

				// Send a data message to the SimpleTunnel server.
				self.sendDataMessage(datagram, extraProperties:[
						TunnelMessageKey.Host.rawValue: endpoint.hostname,
						TunnelMessageKey.Port.rawValue: Int(endpoint.port)!
					])
			}
		}
	}

	/// Send a datagram received from the SimpleTunnel server to the destination application.
	override func sendDataWithEndPoint(data: NSData, host: String, port: Int) {
		let datagrams = [ data ]
		let endpoints = [ NWHostEndpoint(hostname: host, port: String(port)) ]

		// Send the datagram to the destination application.
		UDPFlow.writeDatagrams(datagrams, sentByEndpoints: endpoints) { error in
			if let error = error {
				simpleTunnelLog("Failed to write datagrams to the UDP Flow: \(error)")
				self.tunnel?.sendCloseType(.Read, forConnection: self.identifier)
				self.UDPFlow.closeWriteWithError(nil)
			}
		}
	}
}



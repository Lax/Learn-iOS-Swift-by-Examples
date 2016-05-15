/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the Connection class. The Connection class is an abstract base class that handles a single flow of network data in the SimpleTunnel tunneling protocol.
*/


import Foundation

/// The directions in which a flow can be closed for further data.
public enum TunnelConnectionCloseDirection: Int, CustomStringConvertible {
	case None = 1
	case Read = 2
	case Write = 3
	case All = 4

	public var description: String {
		switch self {
			case .None: return "none"
			case .Read: return "reads"
			case .Write: return "writes"
			case .All: return "reads and writes"
		}
	}
}

/// The results of opening a connection.
public enum TunnelConnectionOpenResult: Int {
	case Success = 0
	case InvalidParam
	case NoSuchHost
	case Refused
	case Timeout
	case InternalError
}

/// A logical connection (or flow) of network data in the SimpleTunnel protocol.
public class Connection: NSObject {

	// MARK: Properties

	/// The connection identifier.
	public let identifier: Int

	/// The tunnel that contains the connection.
	public var tunnel: Tunnel?

	/// The list of data that needs to be written to the connection when possible.
	let savedData = SavedData()

	/// The direction(s) in which the connection is closed.
	var currentCloseDirection = TunnelConnectionCloseDirection.None

	/// Indicates if the tunnel is being used by this connection exclusively.
	let isExclusiveTunnel: Bool

	/// Indicates if the connection cannot be read from.
	public var isClosedForRead: Bool {
		return currentCloseDirection != .None && currentCloseDirection != .Write
	}

	/// Indicates if the connection cannot be written to.
	public var isClosedForWrite: Bool {
		return currentCloseDirection != .None && currentCloseDirection != .Read
	}

	/// Indicates if the connection is fully closed.
	public var isClosedCompletely: Bool {
		return currentCloseDirection == .All
	}

	// MARK: Initializers

	public init(connectionIdentifier: Int, parentTunnel: Tunnel) {
		tunnel = parentTunnel
		identifier = connectionIdentifier
		isExclusiveTunnel = false
		super.init()
		if let t = tunnel {
			// Add this connection to the tunnel's set of connections.
			t.addConnection(self)
		}

	}

	public init(connectionIdentifier: Int) {
		isExclusiveTunnel = true
		identifier = connectionIdentifier
	}

	// MARK: Interface

	/// Set a new tunnel for the connection.
	func setNewTunnel(newTunnel: Tunnel) {
		tunnel = newTunnel
		if let t = tunnel {
			t.addConnection(self)
		}
	}

	/// Close the connection.
	public func closeConnection(direction: TunnelConnectionCloseDirection) {
		if direction != .None && direction != currentCloseDirection {
			currentCloseDirection = .All
		}
		else {
			currentCloseDirection = direction
		}

		guard let currentTunnel = tunnel where currentCloseDirection == .All else { return }

		if isExclusiveTunnel {
			currentTunnel.closeTunnel()
		}
		else {
			currentTunnel.dropConnection(self)
			tunnel = nil
		}
	}

	/// Abort the connection.
	public func abort(error: Int = 0) {
		savedData.clear()
	}

	/// Send data on the connection.
	public func sendData(data: NSData) {
	}

	/// Send data and the destination host and port on the connection.
	public func sendDataWithEndPoint(data: NSData, host: String, port: Int) {
	}

	/// Send a list of IP packets and their associated protocols on the connection.
	public func sendPackets(packets: [NSData], protocols: [NSNumber]) {
	}

	/// Send an indication to the remote end of the connection that the caller will not be reading any more data from the connection for a while.
	public func suspend() {
	}

	/// Send an indication to the remote end of the connection that the caller is going to start reading more data from the connection.
	public func resume() {
	}

	/// Handle the "open completed" message sent by the SimpleTunnel server.
	public func handleOpenCompleted(resultCode: TunnelConnectionOpenResult, properties: [NSObject: AnyObject]) {
	}
}

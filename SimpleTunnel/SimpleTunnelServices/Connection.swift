/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the Connection class. The Connection class is an abstract base class that handles a single flow of network data in the SimpleTunnel tunneling protocol.
*/


import Foundation

/// The directions in which a flow can be closed for further data.
public enum TunnelConnectionCloseDirection: Int, CustomStringConvertible {
	case none = 1
	case read = 2
	case write = 3
	case all = 4

	public var description: String {
		switch self {
			case .none: return "none"
			case .read: return "reads"
			case .write: return "writes"
			case .all: return "reads and writes"
		}
	}
}

/// The results of opening a connection.
public enum TunnelConnectionOpenResult: Int {
	case success = 0
	case invalidParam
	case noSuchHost
	case refused
	case timeout
	case internalError
}

/// A logical connection (or flow) of network data in the SimpleTunnel protocol.
open class Connection: NSObject {

	// MARK: Properties

	/// The connection identifier.
	open let identifier: Int

	/// The tunnel that contains the connection.
	open var tunnel: Tunnel?

	/// The list of data that needs to be written to the connection when possible.
	let savedData = SavedData()

	/// The direction(s) in which the connection is closed.
	var currentCloseDirection = TunnelConnectionCloseDirection.none

	/// Indicates if the tunnel is being used by this connection exclusively.
	let isExclusiveTunnel: Bool

	/// Indicates if the connection cannot be read from.
	open var isClosedForRead: Bool {
		return currentCloseDirection != .none && currentCloseDirection != .write
	}

	/// Indicates if the connection cannot be written to.
	open var isClosedForWrite: Bool {
		return currentCloseDirection != .none && currentCloseDirection != .read
	}

	/// Indicates if the connection is fully closed.
	open var isClosedCompletely: Bool {
		return currentCloseDirection == .all
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
	func setNewTunnel(_ newTunnel: Tunnel) {
		tunnel = newTunnel
		if let t = tunnel {
			t.addConnection(self)
		}
	}

	/// Close the connection.
	open func closeConnection(_ direction: TunnelConnectionCloseDirection) {
		if direction != .none && direction != currentCloseDirection {
			currentCloseDirection = .all
		}
		else {
			currentCloseDirection = direction
		}

		guard let currentTunnel = tunnel , currentCloseDirection == .all else { return }

		if isExclusiveTunnel {
			currentTunnel.closeTunnel()
		}
		else {
			currentTunnel.dropConnection(self)
			tunnel = nil
		}
	}

	/// Abort the connection.
	open func abort(_ error: Int = 0) {
		savedData.clear()
	}

	/// Send data on the connection.
	open func sendData(_ data: Data) {
	}

	/// Send data and the destination host and port on the connection.
	open func sendDataWithEndPoint(_ data: Data, host: String, port: Int) {
	}

	/// Send a list of IP packets and their associated protocols on the connection.
	open func sendPackets(_ packets: [Data], protocols: [NSNumber]) {
	}

	/// Send an indication to the remote end of the connection that the caller will not be reading any more data from the connection for a while.
	open func suspend() {
	}

	/// Send an indication to the remote end of the connection that the caller is going to start reading more data from the connection.
	open func resume() {
	}

	/// Handle the "open completed" message sent by the SimpleTunnel server.
	open func handleOpenCompleted(_ resultCode: TunnelConnectionOpenResult, properties: [NSObject: AnyObject]) {
	}
}

/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the Tunnel class. The Tunnel class is an abstract base class that implements all of the common code between the client and server sides of the SimpleTunnel tunneling protocol.
*/

import Foundation

/// Command types in the SimpleTunnel protocol
public enum TunnelCommand: Int, CustomStringConvertible {
	case Data = 1
	case Suspend = 2
	case Resume = 3
	case Close = 4
	case DNS = 5
	case Open = 6
	case OpenResult = 7
	case Packets = 8
	case FetchConfiguration = 9

	public var description: String {
		switch self {
			case Data: return "Data"
			case Suspend: return "Suspend"
			case Resume: return "Resume"
			case Close: return "Close"
			case DNS: return "DNS"
			case Open: return "Open"
			case OpenResult: return "OpenResult"
			case Packets: return "Packets"
			case FetchConfiguration: return "FetchConfiguration"
		}
	}
}

/// Keys in SimpleTunnel message dictionaries.
public enum TunnelMessageKey: String {
	case Identifier = "identifier"
	case Command = "command"
	case Data = "data"
	case CloseDirection = "close-type"
	case DNSPacket = "dns-packet"
	case DNSPacketSource = "dns-packet-source"
	case ResultCode = "result-code"
	case TunnelType = "tunnel-type"
	case Host = "host"
	case Port = "port"
	case Configuration = "configuration"
	case Packets = "packets"
	case Protocols = "protocols"
	case AppProxyFlowType = "app-proxy-flow-type"
}

/// The layer at which the tunnel tunnels traffic.
public enum TunnelLayer: Int {
	case App = 0
	case IP = 1
}

/// For App Layer tunnel, the type of socket being tunneled.
public enum AppProxyFlowKind: Int {
    case TCP = 1
    case UDP = 3
}

/// The tunnel delegate protocol.
public protocol TunnelDelegate: class {
	func tunnelDidOpen(targetTunnel: Tunnel)
	func tunnelDidClose(targetTunnel: Tunnel)
	func tunnelDidSendConfiguration(targetTunnel: Tunnel, configuration: [String: AnyObject])
}

/// The base class that implements common behavior and data structure for both sides of the SimpleTunnel protocol.
public class Tunnel: NSObject {

	// MARK: Properties

	/// The tunnel delegate.
    public weak var delegate: TunnelDelegate?

	/// The current set of logical connections open within the tunnel.
    var connections = [Int: Connection]()

	/// The list of data that needs to be written to the tunnel connection when possible.
	let savedData = SavedData()

	/// The SimpleTunnel Bonjour service type.
	class var serviceType: String { return "_tunnelserver._tcp" }

	/// The SimpleTunnel Bonjour service domain.
	class var serviceDomain: String { return "local" }

	/// The maximum size of a SimpleTunnel message.
	class var maximumMessageSize: Int { return 128 * 1024 }

	/// The maximum size of a single tunneled IP packet.
	class var packetSize: Int { return 8192 }

	/// The maximum number of IP packets in a single SimpleTunnel data message.
	class var maximumPacketsPerMessage: Int { return 32 }

	/// A list of all tunnels.
	static var allTunnels = [Tunnel]()

	// MARK: Initializers

	override public init() {
		super.init()
		Tunnel.allTunnels.append(self)
	}

	// MARK: Interface

	/// Close the tunnel.
	func closeTunnel() {
		for connection in connections.values {
			connection.tunnel = nil
			connection.abort()
		}
		connections.removeAll(keepCapacity: false)
		
		savedData.clear()

		if let index = Tunnel.allTunnels.indexOf({ return $0 === self }) {
			Tunnel.allTunnels.removeAtIndex(index)
		}
	}
	
	/// Add a connection to the set.
	func addConnection(connection: Connection) {
		connections[connection.identifier] = connection
	}

	/// Remove a connection from the set.
	func dropConnection(connection: Connection) {
		connections.removeValueForKey(connection.identifier)
	}

	/// Close all open tunnels.
	class func closeAll() {
		for tunnel in Tunnel.allTunnels {
			tunnel.closeTunnel()
		}
		Tunnel.allTunnels.removeAll(keepCapacity: false)
	}

	/// Write some data (i.e., a serialized message) to the tunnel.
    func writeDataToTunnel(data: NSData, startingAtOffset: Int) -> Int {
        simpleTunnelLog("writeDataToTunnel called on abstract base class")
        return -1
    }

	/// Serialize a message
	func serializeMessage(messageProperties: [String: AnyObject]) -> NSData? {
		var messageData: NSMutableData?
		do {
			/*
			 * Message format:
			 * 
			 *  0 1 2 3 4 ... Length
			 * +-------+------------+
             * |Length | Payload    |
             * +-------+------------+
			 *
			 */
			let payload = try NSPropertyListSerialization.dataWithPropertyList(messageProperties, format: .BinaryFormat_v1_0, options: 0)
			var totalLength: UInt32 = UInt32(payload.length + sizeof(UInt32.self))
			messageData = NSMutableData(capacity: Int(totalLength))
			messageData?.appendBytes(&totalLength, length: sizeof(UInt32.self))
			messageData?.appendData(payload)
		}
		catch {
			simpleTunnelLog("Failed to create a data object from a message property list: \(messageProperties)")
		}
		return messageData
	}

	/// Send a message on the tunnel connection.
	func sendMessage(messageProperties: [String: AnyObject]) -> Bool {
		var written: Int = 0

        guard let messageData = serializeMessage(messageProperties) else {
            simpleTunnelLog("Failed to create message data")
            return false
        }
                
        if savedData.isEmpty {
			// There is nothing queued up to be sent, to directly write to the tunnel.
            written = writeDataToTunnel(messageData, startingAtOffset:0)
            if written < 0 {
                closeTunnel()
            }
        }

		// If not all of the data was written, save the message data to be sent when possible.
        if written < messageData.length {
            savedData.append(messageData, offset: written)

			// Suspend all connections until the saved data can be written.
            for connection in connections.values {
                connection.suspend()
            }
        }
            
        return true
	}

	/// Send a Data message on the tunnel connection.
	func sendData(data: NSData, forConnection connectionIdentifier: Int) {
		let properties = createMessagePropertiesForConnection(connectionIdentifier, commandType: .Data, extraProperties:[
				TunnelMessageKey.Data.rawValue : data
			])

		if !sendMessage(properties) {
			simpleTunnelLog("Failed to send a data message for connection \(connectionIdentifier)")
		}
	}

	/// Send a Data message with an associated endpoint.
	func sendDataWithEndPoint(data: NSData, forConnection connectionIdentifier: Int, host: String, port: Int ) {
		let properties = createMessagePropertiesForConnection(connectionIdentifier, commandType: .Data, extraProperties:[
				TunnelMessageKey.Data.rawValue: data,
				TunnelMessageKey.Host.rawValue: host,
				TunnelMessageKey.Port.rawValue: port
			])

		if !sendMessage(properties) {
			simpleTunnelLog("Failed to send a data message for connection \(connectionIdentifier)")
		}
	}

	/// Send a Suspend message on the tunnel connection.
	func sendSuspendForConnection(connectionIdentifier: Int) {
		let properties = createMessagePropertiesForConnection(connectionIdentifier, commandType: .Suspend)
		if !sendMessage(properties) {
			simpleTunnelLog("Failed to send a suspend message for connection \(connectionIdentifier)")
		}
	}

	/// Send a Resume message on the tunnel connection.
	func sendResumeForConnection(connectionIdentifier: Int) {
		let properties = createMessagePropertiesForConnection(connectionIdentifier, commandType: .Resume)
		if !sendMessage(properties) {
			simpleTunnelLog("Failed to send a resume message for connection \(connectionIdentifier)")
		}
	}

	/// Send a Close message on the tunnel connection.
	public func sendCloseType(type: TunnelConnectionCloseDirection, forConnection connectionIdentifier: Int) {
		let properties = createMessagePropertiesForConnection(connectionIdentifier, commandType: .Close, extraProperties:[
				TunnelMessageKey.CloseDirection.rawValue: type.rawValue
			])
			
		if !sendMessage(properties) {
			simpleTunnelLog("Failed to send a close message for connection \(connectionIdentifier)")
		}
	}

	/// Send a Packets message on the tunnel connection.
	func sendPackets(packets: [NSData], protocols: [NSNumber], forConnection connectionIdentifier: Int) {
		let properties = createMessagePropertiesForConnection(connectionIdentifier, commandType: .Packets, extraProperties:[
				TunnelMessageKey.Packets.rawValue: packets,
				TunnelMessageKey.Protocols.rawValue: protocols
			])

		if !sendMessage(properties) {
			simpleTunnelLog("Failed to send a packet message")
		}
	}

	/// Process a message payload.
	func handlePacket(packetData: NSData) -> Bool {
		let properties: [String: AnyObject]
		do {
			properties = try NSPropertyListSerialization.propertyListWithData(packetData, options: [.Immutable], format: nil) as! [String: AnyObject]
		}
		catch {
			simpleTunnelLog("Failed to create the message properties from the packet")
			return false
		}

		guard let command = properties[TunnelMessageKey.Command.rawValue] as? Int else {
			simpleTunnelLog("Message command type is missing")
			return false
		}
		guard let commandType = TunnelCommand(rawValue: command) else {
			simpleTunnelLog("Message command type \(command) is invalid")
			return false
		}
		var connection: Connection?

		if let connectionIdentifierNumber = properties[TunnelMessageKey.Identifier.rawValue] as? Int
			where commandType != .Open && commandType != .DNS
		{
			connection = connections[connectionIdentifierNumber]
		}

		guard let targetConnection = connection else {
			return handleMessage(commandType, properties: properties, connection: connection)
		}

		switch commandType {
			case .Data:
				guard let data = properties[TunnelMessageKey.Data.rawValue] as? NSData else { break }

				/* check if the message has properties for host and port */
				if let host = properties[TunnelMessageKey.Host.rawValue] as? String,
					port = properties[TunnelMessageKey.Port.rawValue] as? Int
				{
					simpleTunnelLog("Received data for connection \(connection?.identifier) from \(host):\(port)")
					/* UDP case : send peer's address along with data */
					targetConnection.sendDataWithEndPoint(data, host: host, port: port)
				}
				else {
					targetConnection.sendData(data)
				}

			case .Suspend:
				targetConnection.suspend()

			case .Resume:
				targetConnection.resume()

			case .Close:
				if let closeDirectionNumber = properties[TunnelMessageKey.CloseDirection.rawValue] as? Int,
					closeDirection = TunnelConnectionCloseDirection(rawValue: closeDirectionNumber)
				{
					simpleTunnelLog("\(connection?.identifier): closing \(closeDirection)")
					targetConnection.closeConnection(closeDirection)
				} else {
					simpleTunnelLog("\(connection?.identifier): closing reads and writes")
					targetConnection.closeConnection(.All)
				}

			case .Packets:
				if let packets = properties[TunnelMessageKey.Packets.rawValue] as? [NSData],
					protocols = properties[TunnelMessageKey.Protocols.rawValue] as? [NSNumber]
					where packets.count == protocols.count
				{
					targetConnection.sendPackets(packets, protocols: protocols)
				}

			default:
				return handleMessage(commandType, properties: properties, connection: connection)
		}

		return true
	}

	/// Handle a recieved message.
	func handleMessage(command: TunnelCommand, properties: [String: AnyObject], connection: Connection?) -> Bool {
		simpleTunnelLog("handleMessage called on abstract base class")
		return false
	}
}

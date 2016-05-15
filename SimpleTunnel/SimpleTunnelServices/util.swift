/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains some utility classes and functions used by various parts of the SimpleTunnel project.
*/

import Foundation
import Darwin

/// SimpleTunnel errors
public enum SimpleTunnelError: ErrorType {
    case BadConfiguration
    case BadConnection
	case InternalError
}

/// A queue of blobs of data
class SavedData {

	// MARK: Properties

	/// Each item in the list contains a data blob and an offset (in bytes) within the data blob of the data that is yet to be written.
	var chain = [(data: NSData, offset: Int)]()

	/// A convenience property to determine if the list is empty.
	var isEmpty: Bool {
		return chain.isEmpty
	}

	// MARK: Interface

	/// Add a data blob and offset to the end of the list.
	func append(data: NSData, offset: Int) {
		chain.append(data: data, offset: offset)
	}

	/// Write as much of the data in the list as possible to a stream
	func writeToStream(stream: NSOutputStream) -> Bool {
		var result = true
		var stopIndex: Int?

		for (chainIndex, record) in chain.enumerate() {
			let written = writeData(record.data, toStream: stream, startingAtOffset:record.offset)
			if written < 0 {
				result = false
				break
			}
			if written < (record.data.length - record.offset) {
				// Failed to write all of the remaining data in this blob, update the offset.
				chain[chainIndex] = (record.data, record.offset + written)
				stopIndex = chainIndex
				break
			}
		}

		if let removeEnd = stopIndex {
			// We did not write all of the data, remove what was written.
			if removeEnd > 0 {
				chain.removeRange(0..<removeEnd)
			}
		} else {
			// All of the data was written.
			chain.removeAll(keepCapacity: false)
		}

		return result
	}

	/// Remove all data from the list.
	func clear() {
		chain.removeAll(keepCapacity: false)
	}
}

/// A object containing a sockaddr_in6 structure.
class SocketAddress6 {

	// MARK: Properties

	/// The sockaddr_in6 structure.
	var sin6: sockaddr_in6

	/// The IPv6 address as a string.
	var stringValue: String? {
		return withUnsafePointer(&sin6) { saToString(UnsafePointer<sockaddr>($0)) }
	}

	// MARK: Initializers

	init() {
		sin6 = sockaddr_in6()
		sin6.sin6_len = __uint8_t(sizeof(sockaddr_in6))
		sin6.sin6_family = sa_family_t(AF_INET6)
		sin6.sin6_port = in_port_t(0)
		sin6.sin6_addr = in6addr_any
		sin6.sin6_scope_id = __uint32_t(0)
		sin6.sin6_flowinfo = __uint32_t(0)
	}

	convenience init(otherAddress: SocketAddress6) {
		self.init()
		sin6 = otherAddress.sin6
	}

	/// Set the IPv6 address from a string.
	func setFromString(str: String) -> Bool {
		return str.withCString({ cs in inet_pton(AF_INET6, cs, &sin6.sin6_addr) }) == 1
	}

	/// Set the port.
	func setPort(port: Int) {
		sin6.sin6_port = in_port_t(UInt16(port).bigEndian)
	}
}

/// An object containing a sockaddr_in structure.
class SocketAddress {

	// MARK: Properties

	/// The sockaddr_in structure.
	var sin: sockaddr_in

	/// The IPv4 address in string form.
	var stringValue: String? {
		return withUnsafePointer(&sin) { saToString(UnsafePointer<sockaddr>($0)) }
	}

	// MARK: Initializers

	init() {
		sin = sockaddr_in(sin_len:__uint8_t(sizeof(sockaddr_in.self)), sin_family:sa_family_t(AF_INET), sin_port:in_port_t(0), sin_addr:in_addr(s_addr: 0), sin_zero:(Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0)))
	}

	convenience init(otherAddress: SocketAddress) {
		self.init()
		sin = otherAddress.sin
	}

	/// Set the IPv4 address from a string.
	func setFromString(str: String) -> Bool {
		return str.withCString({ cs in inet_pton(AF_INET, cs, &sin.sin_addr) }) == 1
	}

	/// Set the port.
	func setPort(port: Int) {
		sin.sin_port = in_port_t(UInt16(port).bigEndian)
	}

	/// Increment the address by a given amount.
	func increment(amount: UInt32) {
		let networkAddress = sin.sin_addr.s_addr.byteSwapped + amount
		sin.sin_addr.s_addr = networkAddress.byteSwapped
	}

	/// Get the difference between this address and another address.
	func difference(otherAddress: SocketAddress) -> Int64 {
		return Int64(sin.sin_addr.s_addr.byteSwapped - otherAddress.sin.sin_addr.s_addr.byteSwapped)
	}
}

// MARK: Utility Functions

/// Convert a sockaddr structure to a string.
func saToString(sa: UnsafePointer<sockaddr>) -> String? {
	var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue:0)
	var portBuffer = [CChar](count: Int(NI_MAXSERV), repeatedValue:0)

	guard getnameinfo(sa, socklen_t(sa.memory.sa_len), &hostBuffer, socklen_t(hostBuffer.count), &portBuffer, socklen_t(portBuffer.count), NI_NUMERICHOST | NI_NUMERICSERV) == 0
		else { return nil }

	return String.fromCString(hostBuffer)
}

/// Write a blob of data to a stream starting from a particular offset.
func writeData(data: NSData, toStream stream: NSOutputStream, startingAtOffset offset: Int) -> Int {
	var written = 0
	var currentOffset = offset
	while stream.hasSpaceAvailable && currentOffset < data.length {

		let writeResult = stream.write(UnsafePointer<UInt8>(data.bytes) + currentOffset, maxLength: data.length - currentOffset)
		guard writeResult >= 0 else { return writeResult }

		written += writeResult
		currentOffset += writeResult
	}
	
	return written
}

/// Create a SimpleTunnel protocol message dictionary.
public func createMessagePropertiesForConnection(connectionIdentifier: Int, commandType: TunnelCommand, extraProperties: [String: AnyObject] = [:]) -> [String: AnyObject] {
	// Start out with the "extra properties" that the caller specified.
	var properties = extraProperties

	// Add in the standard properties common to all messages.
	properties[TunnelMessageKey.Identifier.rawValue] = connectionIdentifier
	properties[TunnelMessageKey.Command.rawValue] = commandType.rawValue
	
	return properties
}

/// Keys in the tunnel server configuration plist.
public enum SettingsKey: String {
	case IPv4 = "IPv4"
	case DNS = "DNS"
	case Proxies = "Proxies"
	case Pool = "Pool"
	case StartAddress = "StartAddress"
	case EndAddress = "EndAddress"
	case Servers = "Servers"
	case SearchDomains = "SearchDomains"
	case Address = "Address"
	case Netmask = "Netmask"
	case Routes = "Routes"
}

/// Get a value from a plist given a list of keys.
public func getValueFromPlist(plist: [NSObject: AnyObject], keyArray: [SettingsKey]) -> AnyObject? {
	var subPlist = plist
	for (index, key) in keyArray.enumerate() {
		if index == keyArray.count - 1 {
			return subPlist[key.rawValue]
		}
		else if let subSubPlist = subPlist[key.rawValue] as? [NSObject: AnyObject] {
			subPlist = subSubPlist
		}
		else {
			break
		}
	}

	return nil
}

/// Create a new range by incrementing the start of the given range by a given ammount.
func rangeByMovingStartOfRange(range: Range<Int>, byCount: Int) -> Range<Int> {
	return (range.startIndex + byCount)..<range.endIndex
}

public func simpleTunnelLog(message: String) {
	NSLog(message)
}

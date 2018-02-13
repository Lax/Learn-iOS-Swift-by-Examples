/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains some utility classes and functions used by various parts of the SimpleTunnel project.
*/

import Foundation
import Darwin

/// SimpleTunnel errors
public enum SimpleTunnelError: Error {
    case badConfiguration
    case badConnection
	case internalError
}

/// A queue of blobs of data
class SavedData {

	// MARK: Properties

	/// Each item in the list contains a data blob and an offset (in bytes) within the data blob of the data that is yet to be written.
	var chain = [(data: Data, offset: Int)]()

	/// A convenience property to determine if the list is empty.
	var isEmpty: Bool {
		return chain.isEmpty
	}

	// MARK: Interface

	/// Add a data blob and offset to the end of the list.
	func append(_ data: Data, offset: Int) {
		chain.append(data: data, offset: offset)
	}

	/// Write as much of the data in the list as possible to a stream
	func writeToStream(_ stream: OutputStream) -> Bool {
		var result = true
		var stopIndex: Int?

		for (chainIndex, record) in chain.enumerated() {
			let written = writeData(record.data, toStream: stream, startingAtOffset:record.offset)
			if written < 0 {
				result = false
				break
			}
			if written < (record.data.count - record.offset) {
				// Failed to write all of the remaining data in this blob, update the offset.
				chain[chainIndex] = (record.data, record.offset + written)
				stopIndex = chainIndex
				break
			}
		}

		if let removeEnd = stopIndex {
			// We did not write all of the data, remove what was written.
			if removeEnd > 0 {
				chain.removeSubrange(0..<removeEnd)
			}
		} else {
			// All of the data was written.
			chain.removeAll(keepingCapacity: false)
		}

		return result
	}

	/// Remove all data from the list.
	func clear() {
		chain.removeAll(keepingCapacity: false)
	}
}

/// A object containing a sockaddr_in6 structure.
class SocketAddress6 {

	// MARK: Properties

	/// The sockaddr_in6 structure.
	var sin6: sockaddr_in6

	/// The IPv6 address as a string.
	var stringValue: String? {
    return withUnsafePointer(to: &sin6) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { saToString($0) } }
	}

	// MARK: Initializers

	init() {
		sin6 = sockaddr_in6()
		sin6.sin6_len = __uint8_t(MemoryLayout<sockaddr_in6>.size)
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
	func setFromString(_ str: String) -> Bool {
		return str.withCString({ cs in inet_pton(AF_INET6, cs, &sin6.sin6_addr) }) == 1
	}

	/// Set the port.
	func setPort(_ port: Int) {
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
    return withUnsafePointer(to: &sin) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { saToString($0) } }
	}

	// MARK: Initializers

	init() {
		sin = sockaddr_in(sin_len:__uint8_t(MemoryLayout<sockaddr_in>.size), sin_family:sa_family_t(AF_INET), sin_port:in_port_t(0), sin_addr:in_addr(s_addr: 0), sin_zero:(Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0), Int8(0)))
	}

	convenience init(otherAddress: SocketAddress) {
		self.init()
		sin = otherAddress.sin
	}

	/// Set the IPv4 address from a string.
	func setFromString(_ str: String) -> Bool {
		return str.withCString({ cs in inet_pton(AF_INET, cs, &sin.sin_addr) }) == 1
	}

	/// Set the port.
	func setPort(_ port: Int) {
		sin.sin_port = in_port_t(UInt16(port).bigEndian)
	}

	/// Increment the address by a given amount.
	func increment(_ amount: UInt32) {
		let networkAddress = sin.sin_addr.s_addr.byteSwapped + amount
		sin.sin_addr.s_addr = networkAddress.byteSwapped
	}

	/// Get the difference between this address and another address.
	func difference(_ otherAddress: SocketAddress) -> Int64 {
		return Int64(sin.sin_addr.s_addr.byteSwapped - otherAddress.sin.sin_addr.s_addr.byteSwapped)
	}
}

// MARK: Utility Functions

/// Convert a sockaddr structure to a string.
func saToString(_ sa: UnsafePointer<sockaddr>) -> String? {
	var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
	var portBuffer = [CChar](repeating: 0, count: Int(NI_MAXSERV))

	guard getnameinfo(sa, socklen_t(sa.pointee.sa_len), &hostBuffer, socklen_t(hostBuffer.count), &portBuffer, socklen_t(portBuffer.count), NI_NUMERICHOST | NI_NUMERICSERV) == 0
		else { return nil }

	return String(cString: hostBuffer)
}

/// Write a blob of data to a stream starting from a particular offset.
func writeData(_ data: Data, toStream stream: OutputStream, startingAtOffset offset: Int) -> Int {
	var written = 0
	var currentOffset = offset
	while stream.hasSpaceAvailable && currentOffset < data.count {

		let writeResult = stream.write((data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count) + currentOffset, maxLength: data.count - currentOffset)
		guard writeResult >= 0 else { return writeResult }

		written += writeResult
		currentOffset += writeResult
	}
	
	return written
}

/// Create a SimpleTunnel protocol message dictionary.
public func createMessagePropertiesForConnection(_ connectionIdentifier: Int, commandType: TunnelCommand, extraProperties: [String: AnyObject] = [:]) -> [String: AnyObject] {
	// Start out with the "extra properties" that the caller specified.
	var properties = extraProperties

	// Add in the standard properties common to all messages.
	properties[TunnelMessageKey.Identifier.rawValue] = connectionIdentifier as AnyObject?
	properties[TunnelMessageKey.Command.rawValue] = commandType.rawValue as AnyObject?
	
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
public func getValueFromPlist(_ plist: [NSObject: AnyObject], keyArray: [SettingsKey]) -> AnyObject? {
	var subPlist = plist
	for (index, key) in keyArray.enumerated() {
		if index == keyArray.count - 1 {
			return subPlist[key.rawValue as NSString]
		}
		else if let subSubPlist = subPlist[key.rawValue as NSString] as? [NSObject: AnyObject] {
			subPlist = subSubPlist
		}
		else {
			break
		}
	}

	return nil
}

/// Create a new range by incrementing the start of the given range by a given ammount.
func rangeByMovingStartOfRange(_ range: Range<Int>, byCount: Int) -> CountableRange<Int> {
	return (range.lowerBound + byCount)..<range.upperBound
}

public func simpleTunnelLog(_ message: String) {
	NSLog(message)
}

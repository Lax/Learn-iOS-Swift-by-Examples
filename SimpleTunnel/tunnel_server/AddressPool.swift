/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the AddressPool class. The AddressPool class is used to manage a pool of IP addresses.
*/

import Foundation

/// An object that contains a pool of IP addresses to assign to tunnel clients.
class AddressPool {

	// MARK: Properties

	/// The start address of the pool.
	let baseAddress: SocketAddress

	/// The number of addresses in the pool.
	var size: UInt64 = 0

	/// A list of flags indicating which addresses in the pool are currently allocated to clients.
	var inUseMask: [Bool]

	/// A dispatch queue for serializing access to the pool.
	let queue: dispatch_queue_t

	// MARK: Initializers
	
	init(startAddress: String, endAddress: String) {
		baseAddress = SocketAddress()
		inUseMask = [Bool](count: 0, repeatedValue: false)
		queue = dispatch_queue_create("AddressPoolQueue", nil)

		let start = SocketAddress()
		let end = SocketAddress()

		// Verify that the address pool is specified correctly.

		guard start.setFromString(startAddress) &&
			end.setFromString(endAddress) &&
			start.sin.sin_family == end.sin.sin_family
			else { return }

		guard start.sin.sin_family == sa_family_t(AF_INET) else {
			simpleTunnelLog("IPv6 is not currently supported")
			return
		}
		guard (start.sin.sin_addr.s_addr & 0xffff) == (end.sin.sin_addr.s_addr & 0xffff) else {
			simpleTunnelLog("start address (\(startAddress)) is not in the same class B network as end address (\(endAddress)) ")
			return
		}

		let difference = end.difference(start)
		guard difference >= 0 else {
			simpleTunnelLog("start address (\(startAddress)) is greater than end address (\(endAddress))")
			return
		}

		baseAddress.sin = start.sin
		size = UInt64(difference)
		inUseMask = [Bool](count: Int(size), repeatedValue: false)
	}

	/// Allocate an address from the pool.
	func allocateAddress() -> String? {
		var result: String?

		dispatch_sync(queue) {
			let address = SocketAddress(otherAddress: self.baseAddress)

			// Look for an address that is not currently allocated
			for (index, inUse) in self.inUseMask.enumerate() {
				if !inUse {
					address.increment(UInt32(index))
					self.inUseMask[index] = true
					result = address.stringValue
					break
				}
			}
		}

		simpleTunnelLog("Allocated address \(result)")
		return result
	}

	/// Deallocate an address in the pool.
	func deallocateAddress(addrString: String) {
		dispatch_sync(queue) {
			let address = SocketAddress()

			guard address.setFromString(addrString) else { return }

			let difference = address.difference(self.baseAddress)
			if difference >= 0 && difference < Int64(self.inUseMask.count) {
				self.inUseMask[Int(difference)] = false
			}
		}
	}
}
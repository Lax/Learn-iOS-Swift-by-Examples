//
//  AppProxyClientTunnel.swift
//  SimpleTunnel
//
//  Created by Paresh Sawant on 5/6/15.
//  Copyright © 2015 Apple Inc. All rights reserved.
//

import Foundation
import NetworkExtension
import SimpleTunnelServices

public class AppProxyClientTunnel : ClientTunnel {
    public func sendDataToTunnel(queue: dispatch_queue_t, data: NSData, startingAtOffset: Int) -> Int {
		self.connection?.write(data) {
			error in
			if error != nil {
                self.closeTunnelWithError(error)
                
			}
			dispatch_resume(queue)
		}
		dispatch_suspend(queue)
        //return super.writeDataToTunnel(data: data, startingAtOffset: startingAtOffset)
		return data.length
	}
}
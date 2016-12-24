/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ServiceCell` displays a service and information about it.
*/

import UIKit
import HomeKit

/// A `UITableViewCell` subclass for displaying a service and the room and accessory where it resides.
class ServiceCell: UITableViewCell {
    
    // MARK: Properties
    var includeAccessoryText = true
    
    /// Required init.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
        The cell's service.
        
        When the service is set, the cell's `textLabel` will contain the service's name
        or the accessory's name if the service has no name.
        The detail text will contain information about where this service lives.
    */
    var service: HMService? {
        didSet {
            if let service = service,
                    accessory = service.accessory {
                textLabel?.text = service.name ?? accessory.name
                let accessoryName = accessory.name
                let roomName = accessory.room!.name
                if includeAccessoryText {
                    let inIdentifier = NSLocalizedString("%@ in %@", comment: "Accessory in Room")
                    detailTextLabel?.text = String(format: inIdentifier, accessoryName, roomName)
                }
                else {
                    detailTextLabel?.text = ""
                }
            }
        }
    }
}
/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ActionCell` displays a characteristic and a target value.
*/

import UIKit
import HomeKit

/// A `UITableViewCell` subclass that displays a characteristic's 'target value'.
class ActionCell: UITableViewCell {
    /// Ignores the passed-in style and overrides it with `.Subtitle`.
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
        selectionStyle = .None
        detailTextLabel?.textColor = UIColor.lightGrayColor()
        accessoryType = .None
    }
    
    /// Required init.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
        Sets the cell's text to represent a characteristic and target value.
        For example, "Brightness → 60%"
        Sets the subtitle to the service and accessory that this characteristic represents.
        
        - parameter characteristic: The characteristic this cell represents.
        - parameter targetValue:    The target value from this action.
    */
    func setCharacteristic(characteristic: HMCharacteristic, targetValue: AnyObject) {
        let targetDescription = "\(characteristic.localizedDescription) → \(characteristic.localizedDescriptionForValue(targetValue))"
        textLabel?.text = targetDescription
        
        let contextDescription = NSLocalizedString("%@ in %@", comment: "Service in Accessory")
        if let service = characteristic.service, accessory = service.accessory {
            detailTextLabel?.text = String(format: contextDescription, service.name, accessory.name)
        }
        else {
            detailTextLabel?.text = NSLocalizedString("Unknown Characteristic", comment: "Unknown Characteristic")
        }
    }
}

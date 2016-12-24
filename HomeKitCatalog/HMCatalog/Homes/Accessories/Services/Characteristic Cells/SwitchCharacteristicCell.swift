/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `SwitchCharacteristicCell` displays Boolean characteristics.
*/

import UIKit
import HomeKit

/**
    A `CharacteristicCell` subclass that contains a single switch.
    Used for Boolean characteristics.
*/
class SwitchCharacteristicCell: CharacteristicCell {
    // MARK: Properties
    
    @IBOutlet weak var valueSwitch: UISwitch!
    
    override var characteristic: HMCharacteristic! {
        didSet {
            valueSwitch.alpha = enabled ? 1.0 : CharacteristicCell.DisabledAlpha
            valueSwitch.userInteractionEnabled = enabled
        }
    }
    
    /// If notify is false, sets the switch to the value.
    override func setValue(newValue: AnyObject?, notify: Bool) {
        super.setValue(newValue, notify: notify)
        
        if !notify {
            if let boolValue = newValue as? Bool {
                valueSwitch.setOn(boolValue, animated: true)
            }
        }
    }
    
    /**
        Responds to the switch updating and sets the
        value to the switch's value.
        
        - parameter valueSwitch: The switch that updated.
    */
    func didChangeSwitchValue(valueSwitch: UISwitch) {
        setValue(valueSwitch.on, notify: true)
    }
    
}

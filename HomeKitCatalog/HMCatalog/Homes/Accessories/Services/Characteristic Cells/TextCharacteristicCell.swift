/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TextCharacteristicCell` represents text-input characteristics.
*/

import UIKit
import HomeKit

/**
    A `CharacteristicCell` subclass that contains a text field.
    Used for text-input characteristics.
*/
class TextCharacteristicCell: CharacteristicCell, UITextFieldDelegate {
    // MARK: Properties
    
    @IBOutlet weak var textField: UITextField!
    
    override var characteristic: HMCharacteristic! {
        didSet {
            textField.alpha = enabled ? 1.0 : CharacteristicCell.DisabledAlpha
            textField.userInteractionEnabled = enabled
        }
    }
    
    /// If notify is false, sets the text field's text from the value.
    override func setValue(newValue: AnyObject?, notify: Bool) {
        super.setValue(newValue, notify: notify)
        if !notify {
            if let newStringValue = newValue as? String {
                textField.text = newStringValue
            }
        }
    }
    
    /// Dismiss the keyboard when "Go" is clicked
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /// Sets the value of the characteristic when editing is complete.
    func textFieldDidEndEditing(textField: UITextField) {
        setValue(textField.text, notify: true)
    }
}

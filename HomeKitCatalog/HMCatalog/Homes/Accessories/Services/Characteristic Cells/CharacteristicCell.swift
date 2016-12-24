/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `CharacteristicCell` is a superclass which represents the state of a HomeKit characteristic.
*/

import UIKit
import HomeKit

/// Methods for handling cell reads and updates.
protocol CharacteristicCellDelegate {
    
    /**
        Called whenever the control within the cell updates its value.
        
        - parameter cell:           The cell which has updated its value.
        - parameter newValue:       The new value represented by the cell's control.
        - parameter characteristic: The characteristic the cell represents.
        - parameter immediate:      Whether or not to update external values immediately.
        
        For example, Slider cells should not update immediately upon value change,
        so their values are cached and updates are coalesced. Subclasses can decide
        whether or not their values are meant to be updated immediately.
    */
    func characteristicCell(cell: CharacteristicCell, didUpdateValue value: AnyObject, forCharacteristic characteristic: HMCharacteristic, immediate: Bool)
    
    /**
        Called when the characteristic cell needs to reload its value from an external source.
        Consider using this call to look up values in memory or query them from an accessory.
        
        - parameter cell:           The cell requesting a value update.
        - parameter characteristic: The characteristic for whose value the cell is asking.
        - parameter completion:     The closure that the cell provides to be called when values have been read successfully.
    */
    func characteristicCell(cell: CharacteristicCell, readInitialValueForCharacteristic characteristic: HMCharacteristic, completion: (AnyObject?, NSError?) -> Void)
}

/**
    A `UITableViewCell` subclass that displays the current value of an `HMCharacteristic` and
    notifies its delegate of changes. Subclasses of this class will provide additional controls
    to display different kinds of data.
*/
class CharacteristicCell: UITableViewCell {
    /// An alpha percentage used when disabling cells.
    static let DisabledAlpha: CGFloat = 0.4
    
    /// Required init.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Subclasses can return false if they have many frequent updates that should be deferred.
    class var updatesImmediately: Bool {
        return true
    }
    
    // MARK: Properties
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBOutlet weak var favoriteButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var favoriteButtonHeightContraint: NSLayoutConstraint!
        
    /** 
        Show / hide the favoriteButton and adjust the constraints
        to ensure proper layout.
    */
    var showsFavorites = false {
        didSet {
            if showsFavorites {
                favoriteButton.hidden = false
                favoriteButtonWidthConstraint.constant = favoriteButtonHeightContraint.constant
            }
            else {
                favoriteButton.hidden = true
                favoriteButtonWidthConstraint.constant = 15.0
            }
        }
    }
    
    /**
        - returns:  `true` if the represented characteristic is reachable;
                    `false` otherwise.
    */
    var enabled: Bool {
        return (characteristic.service?.accessory?.reachable ?? false)
    }
    
    /**
        The value currently represented by the cell.
        
        This is not necessarily the value of this cell's characteristic,
        because the cell's value changes independently of the characteristic.
    */
    var value: AnyObject?
    
    /// The delegate that will respond to cell value changes.
    var delegate: CharacteristicCellDelegate?
    
    /**
        The characteristic represented by this cell.
        
        When this is set, the cell populates based on
        the characteristic's value and requests an initial value
        from its delegate.
    */
    var characteristic: HMCharacteristic! {
        didSet {
            typeLabel.text = characteristic.localizedCharacteristicType
            
            selectionStyle = characteristic.isIdentify ? .Default : .None
            
            setValue(characteristic.value, notify: false)

            if characteristic.isWriteOnly {
                // Don't read the value for write-only characteristics.
                return
            }
            
            // Set initial state of the favorite button
            favoriteButton.selected = characteristic.isFavorite
            
            // "Enable" the cell if the accessory is reachable or we are displaying the favorites.
            
            // Configure the views.
            typeLabel.alpha = enabled ? 1.0 : CharacteristicCell.DisabledAlpha
            valueLabel?.alpha = enabled ? 1.0 : CharacteristicCell.DisabledAlpha
            
            if enabled {
                delegate?.characteristicCell(self, readInitialValueForCharacteristic: characteristic) { value, error in
                    if let error = error {
                        print("HomeKit: Error reading value for characteristic \(self.characteristic): \(error.localizedDescription).")
                    }
                    else {
                        self.setValue(value, notify: false)
                    }
                }
            }
            
        }
    }
    
    /// Resets the value label to the localized description from HMCharacteristic+Readability.
    func resetValueLabel() {
        if let value = value {
            valueLabel?.text = characteristic.localizedDescriptionForValue(value)
        }
    }
    
    /**
        Toggles the star button and saves the favorite status
        of the characteristic in the FavoriteManager.
    */
    @IBAction func didTapFavoriteButton(sender: UIButton) {
        sender.selected = !sender.selected
        characteristic.isFavorite = sender.selected
    }
    
    /**
        Sets the cell's value and resets the label.
        
        - parameter newValue: The new value.
        - parameter notify:   If true, the cell notifies its delegate of the change.
    */
    func setValue(newValue: AnyObject?, notify: Bool) {
        value = newValue
        if let newValue = newValue {
            resetValueLabel()
            /*
                We do not allow the setting of nil values from the app,
                but we do have to deal with incoming nil values.
            */
            if notify {
                delegate?.characteristicCell(self, didUpdateValue: newValue, forCharacteristic: characteristic, immediate: self.dynamicType.updatesImmediately)
            }
        }
    }
}

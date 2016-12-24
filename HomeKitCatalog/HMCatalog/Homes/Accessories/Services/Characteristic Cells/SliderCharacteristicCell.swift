/*
   Copyright (C) 2016 Apple Inc. All Rights Reserved.
   See LICENSE.txt for this sample’s licensing information
   
   Abstract:
   The `SliderCharacteristicCell` displays characteristics with a continuous range of options.
*/

import UIKit
import HomeKit

/**
   A `CharacteristicCell` subclass that contains a slider.
   Used for numeric characteristics that have a continuous range of options.
*/
class SliderCharacteristicCell: CharacteristicCell {
   // MARK: Properties
   
   @IBOutlet weak var valueSlider: UISlider!
   
   override var characteristic: HMCharacteristic! {
      didSet {
         valueSlider.alpha = enabled ? 1.0 : CharacteristicCell.DisabledAlpha
         valueSlider.userInteractionEnabled = enabled
      }
      
      willSet(newCharacteristic) {
         // These are sane defaults in case the max and min are not set.
         valueSlider.minimumValue = newCharacteristic.metadata?.minimumValue as? Float ?? 0.0
         valueSlider.maximumValue = newCharacteristic.metadata?.maximumValue as? Float ?? 100.0
      }
   }
   
   /// If notify is false, sets the valueSlider's represented value.
   override func setValue(newValue: AnyObject?, notify: Bool) {
      super.setValue(newValue, notify: notify)
      if let newValue = newValue as? NSNumber where !notify {
         valueSlider.value = newValue.floatValue
      }
   }
   
   /**
      Restricts a value to the step value provided in the cell's
      characteristic's metadata.
   
      - parameter sliderValue: The provided value.
   
      - returns:  The value adjusted to align with a step value.
   */
   func roundedValueForSliderValue(value: Float) -> Float {
      if let metadata = characteristic.metadata,
         stepValue = metadata.stepValue as? Float
         where stepValue > 0 {
            let newStep = roundf(value / stepValue)
            let stepped = newStep * stepValue
            return stepped
      }

      return value
   }
   
   // Sliders don't update immediately, because sliders generate many updates.
   override class var updatesImmediately: Bool {
      return false
   }
   
   /**
      Responds to a slider change and sets the cell's value.
   
      - parameter slider: The slider that changed.
   */
   func didChangeSliderValue(slider: UISlider) {
      let value = roundedValueForSliderValue(slider.value)
      setValue(value, notify: true)
   }
   
}

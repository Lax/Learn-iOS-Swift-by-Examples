/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HMCharacteristic+Properties` methods are used to generate localized strings related to a characteristic or to evaluate a characteristic's type.
*/

import HomeKit

extension HMCharacteristic {
    
    private struct Constants {
        static let valueFormatter = NSNumberFormatter()
        static let numericFormats = [
            HMCharacteristicMetadataFormatInt,
            HMCharacteristicMetadataFormatFloat,
            HMCharacteristicMetadataFormatUInt8,
            HMCharacteristicMetadataFormatUInt16,
            HMCharacteristicMetadataFormatUInt32,
            HMCharacteristicMetadataFormatUInt64
        ]
    }
    
    /**
        Returns the localized description for a provided value, taking the characteristic's metadata and possible
        values into account.
        
        - parameter value: The value to look up.
        
        - returns: A string representing the value in a localized way, e.g. `"24%"` or `"354º"`
    */
    func localizedDescriptionForValue(value: AnyObject) -> String {
        if self.isWriteOnly {
            return NSLocalizedString("Write-Only Characteristic", comment: "Write-Only Characteristic")
        }
        else if self.isBoolean {
            if let boolValue = value.boolValue {
                return boolValue ? NSLocalizedString("On", comment: "On") : NSLocalizedString("Off", comment: "Off")
            }
        }
        if let number = value as? Int {
            if let predeterminedValueString = self.predeterminedValueDescriptionForNumber(number) {
                return predeterminedValueString
            }
            
            if let stepValue = self.metadata?.stepValue {
                Constants.valueFormatter.minimumFractionDigits = Int(log10(1.0 / stepValue.doubleValue))
                if let string = Constants.valueFormatter.stringFromNumber(number) {
                    return string + self.localizedUnitDecoration
                }
            }
        }
        return "\(value)"
    }
    
    /**
        - parameter number: The value of this characteristic.
        
        - returns: An optional, localized string for the value.
    */
    func predeterminedValueDescriptionForNumber(number: Int) -> String? {
        switch self.characteristicType {
            case HMCharacteristicTypePowerState, HMCharacteristicTypeInputEvent, HMCharacteristicTypeOutputState:
                if Bool(number) {
                    return NSLocalizedString("On", comment: "On")
                }
                else {
                    return NSLocalizedString("Off", comment: "Off")
                }
            
            case HMCharacteristicTypeOutletInUse, HMCharacteristicTypeMotionDetected, HMCharacteristicTypeAdminOnlyAccess, HMCharacteristicTypeAudioFeedback, HMCharacteristicTypeObstructionDetected:
                if Bool(number) {
                    return NSLocalizedString("Yes", comment: "Yes")
                }
                else {
                    return NSLocalizedString("No", comment: "No")
                }
            
            case HMCharacteristicTypeTargetDoorState, HMCharacteristicTypeCurrentDoorState:
                if let doorState = HMCharacteristicValueDoorState(rawValue: number) {
                    switch doorState {
                        case .Open:
                            return NSLocalizedString("Open", comment: "Open")
                        
                        case .Opening:
                            return NSLocalizedString("Opening", comment: "Opening")
                        
                        case .Closed:
                            return NSLocalizedString("Closed", comment: "Closed")
                        
                        case .Closing:
                            return NSLocalizedString("Closing", comment: "Closing")
                        
                        case .Stopped:
                            return NSLocalizedString("Stopped", comment: "Stopped")
                    }
                }
            
            case HMCharacteristicTypeTargetHeatingCooling:
                if let mode = HMCharacteristicValueHeatingCooling(rawValue: number) {
                    switch mode {
                        case .Off:
                            return NSLocalizedString("Off", comment: "Off")
                            
                        case .Heat:
                            return NSLocalizedString("Heat", comment: "Heat")
                            
                        case .Cool:
                            return NSLocalizedString("Cool", comment: "Cool")
                            
                        case .Auto:
                            return NSLocalizedString("Auto", comment: "Auto")
                    }
                }
            
            case HMCharacteristicTypeCurrentHeatingCooling:
                if let mode = HMCharacteristicValueHeatingCooling(rawValue: number) {
                    switch mode {
                        case .Off:
                            return NSLocalizedString("Off", comment: "Off")
                        
                        case .Heat:
                            return NSLocalizedString("Heating", comment: "Heating")
                        
                        case .Cool:
                            return NSLocalizedString("Cooling", comment: "Cooling")
                        
                        case .Auto:
                            return NSLocalizedString("Auto", comment: "Auto")
                    }
                }
            
            case HMCharacteristicTypeTargetLockMechanismState, HMCharacteristicTypeCurrentLockMechanismState:
                if let lockState = HMCharacteristicValueLockMechanismState(rawValue: number) {
                    switch lockState {
                        case .Unsecured:
                            return NSLocalizedString("Unsecured", comment: "Unsecured")
                        
                        case .Secured:
                            return NSLocalizedString("Secured", comment: "Secured")
                        
                        case .Unknown:
                            return NSLocalizedString("Unknown", comment: "Unknown")
                        
                        case .Jammed:
                            return NSLocalizedString("Jammed", comment: "Jammed")
                    }
                }
            
            case HMCharacteristicTypeTemperatureUnits:
                if let unit = HMCharacteristicValueTemperatureUnit(rawValue: number) {
                    switch unit {
                        case .Celsius:
                            return NSLocalizedString("Celsius", comment: "Celsius")
                        
                        case .Fahrenheit:
                            return NSLocalizedString("Fahrenheit", comment: "Fahrenheit")
                    }
                }
            
            case HMCharacteristicTypeLockMechanismLastKnownAction:
                if let lastKnownAction = HMCharacteristicValueLockMechanismLastKnownAction(rawValue: number) {
                    switch lastKnownAction {
                        case .SecuredUsingPhysicalMovementInterior:
                            return NSLocalizedString("Interior Secured", comment: "Interior Secured")
                        
                        case .UnsecuredUsingPhysicalMovementInterior:
                            return NSLocalizedString("Exterior Unsecured", comment: "Exterior Unsecured")
                        
                        case .SecuredUsingPhysicalMovementExterior:
                            return NSLocalizedString("Exterior Secured", comment: "Exterior Secured")
                        
                        case .UnsecuredUsingPhysicalMovementExterior:
                            return NSLocalizedString("Exterior Unsecured", comment: "Exterior Unsecured")
                        
                        case .SecuredWithKeypad:
                            return NSLocalizedString("Keypad Secured", comment: "Keypad Secured")
                        
                        case .UnsecuredWithKeypad:
                            return NSLocalizedString("Keypad Unsecured", comment: "Keypad Unsecured")
                        
                        case .SecuredRemotely:
                            return NSLocalizedString("Secured Remotely", comment: "Secured Remotely")
                        
                        case .UnsecuredRemotely:
                            return NSLocalizedString("Unsecured Remotely", comment: "Unsecured Remotely")
                        
                        case .SecuredWithAutomaticSecureTimeout:
                            return NSLocalizedString("Secured Automatically", comment: "Secured Automatically")
                        
                        case .SecuredUsingPhysicalMovement:
                            return NSLocalizedString("Secured Using Physical Movement", comment: "Secured Using Physical Movement")
                        
                        case .UnsecuredUsingPhysicalMovement:
                            return NSLocalizedString("Unsecured Using Physical Movement", comment: "Unsecured Using Physical Movement")
                    }
                }
            
            case HMCharacteristicTypeRotationDirection:
                if let rotationDirection = HMCharacteristicValueRotationDirection(rawValue: number) {
                    switch rotationDirection {
                        case .Clockwise:
                            return NSLocalizedString("Clockwise", comment: "Clockwise")
                        
                        case .CounterClockwise:
                            return NSLocalizedString("Counter Clockwise", comment: "Counter Clockwise")
                    }
                }
            
            case HMCharacteristicTypeAirParticulateSize:
                if let size = HMCharacteristicValueAirParticulateSize(rawValue: number) {
                    switch size {
                        case .Size10:
                            return NSLocalizedString("Size 10", comment: "Size 10")
                        
                        case .Size2_5:
                            return NSLocalizedString("Size 2.5", comment: "Size 2.5")
                    }
                }
            
            case HMCharacteristicTypePositionState:
                if let state = HMCharacteristicValuePositionState(rawValue: number) {
                    switch state {
                        case .Opening:
                            return NSLocalizedString("Opening", comment: "Opening")
                        
                        case .Closing:
                            return NSLocalizedString("Closing", comment: "Closing")
                        
                        case .Stopped:
                            return NSLocalizedString("Stopped", comment: "Stopped")
                    }
                }
            
            case HMCharacteristicTypeCurrentSecuritySystemState:
                if let state = HMCharacteristicValueCurrentSecuritySystemState(rawValue: number) {
                    switch state {
                        case .AwayArm:
                            return NSLocalizedString("Away", comment: "Away")
                            
                        case .StayArm:
                            return NSLocalizedString("Home", comment: "Home")
                            
                        case .NightArm:
                            return NSLocalizedString("Night", comment: "Night")
                            
                        case .Disarmed:
                            return NSLocalizedString("Disarm", comment: "Disarm")
                        
                        case .Triggered:
                            return NSLocalizedString("Triggered", comment: "Triggered")
                    }
                }
            
            case HMCharacteristicTypeTargetSecuritySystemState:
                if let state = HMCharacteristicValueTargetSecuritySystemState(rawValue: number) {
                    switch state {
                        case .AwayArm:
                            return NSLocalizedString("Away", comment: "Away")
                        
                        case .StayArm:
                            return NSLocalizedString("Home", comment: "Home")
                        
                        case .NightArm:
                            return NSLocalizedString("Night", comment: "Night")
                        
                        case .Disarm:
                            return NSLocalizedString("Disarm", comment: "Disarm")
                    }
                }
            
            default:
                break
        }
        return nil
    }
    
    var supportsEventNotification: Bool {
        return self.properties.contains(HMCharacteristicPropertySupportsEventNotification)
    }
    
    /// - returns:  A string representing the value in a localized way, e.g. `"24%"` or `"354º"`
    var localizedValueDescription: String {
        if let value = value {
            return self.localizedDescriptionForValue(value)
        }
        return ""
    }
    
    /// - returns:  The decoration for the characteristic's units, localized, e.g. `"%"` or `"º"`
    var localizedUnitDecoration: String {
        if let units = self.metadata?.units {
            switch units {
                case HMCharacteristicMetadataUnitsCelsius:
                    return NSLocalizedString("℃", comment: "Degrees Celsius")
                
                case HMCharacteristicMetadataUnitsArcDegree:
                    return NSLocalizedString("º", comment: "Arc Degrees")
                
                case HMCharacteristicMetadataUnitsFahrenheit:
                    return NSLocalizedString("℉", comment: "Degrees Fahrenheit")
                
                case HMCharacteristicMetadataUnitsPercentage:
                    return NSLocalizedString("%", comment: "Percentage")
                
                default: break
            }
        }
        return ""
    }
    
    /// - returns:  The type of the characteristic, e.g. `"Current Lock Mechanism State"`
    var localizedCharacteristicType: String {
        var type = self.localizedDescription
        
        var localizedDescription: NSString? = nil
        if isReadOnly {
            localizedDescription = NSLocalizedString("Read Only", comment: "Read Only")
        }
        else if isWriteOnly {
            localizedDescription = NSLocalizedString("Write Only", comment: "Write Only")
        }
        
        if let localizedDescription = localizedDescription {
            type = type + " (\(localizedDescription))"
        }
        
        return type
    }
    
    /// - returns:  `true` if this characteristic has numeric values that are all integers; `false` otherwise.
    var isInteger: Bool {
        return self.isNumeric && !self.isFloatingPoint
    }
    
    /**
        - returns:  `true` if this characteristic has numeric values;
                    `false` otherwise.
    */
    var isNumeric: Bool {
        guard let metadata = metadata else { return false }
        guard let format = metadata.format else { return false }
        return Constants.numericFormats.contains(format)
    }
    
    /// - returns:  `true` if this characteristic is boolean; `false` otherwise.
    var isBoolean: Bool {
        guard let metadata = metadata else { return false }
        return metadata.format == HMCharacteristicMetadataFormatBool
    }
    
    /**
        - returns:  `true` if this characteristic is text-writable;
                    `false` otherwise.
    */
    var isTextWritable: Bool {
        guard let metadata = metadata else { return false }
        return metadata.format == HMCharacteristicMetadataFormatString && properties.contains(HMCharacteristicPropertyWritable)
    }
    
    /**
        - returns:  `true` if this characteristic has numeric values
                    that are all floating point; `false` otherwise.
    */
    var isFloatingPoint: Bool {
        guard let metadata = metadata else { return false }
        return metadata.format == HMCharacteristicMetadataFormatFloat
    }
    
    /// - returns:  `true` if characteristic is read only; `false` otherwise.
    var isReadOnly: Bool {
        return !properties.contains(HMCharacteristicPropertyWritable)  &&
            properties.contains(HMCharacteristicPropertyReadable)
    }
    
    /**
        - returns:  `true` if this characteristic is write only;
                    `false` otherwise.
    */
    var isWriteOnly: Bool {
        return !properties.contains(HMCharacteristicPropertyReadable)  &&
            properties.contains(HMCharacteristicPropertyWritable)
    }
    
    /**
        - returns:  `true` if this characteristic is the 'Identify'
                    characteristic; `false` otherwise.
    */
    var isIdentify: Bool {
        return self.characteristicType == HMCharacteristicTypeIdentify
    }
    
    /**
        - returns:  The number of possible values that this characteristic can contain.
                    The standard formula for the number of values between two numbers is
                    `((greater - lesser) + 1)`, and this takes step value into account.
    */
    var numberOfChoices: Int {
        guard let metadata = metadata, minimumValue = metadata.minimumValue as? Int else { return 0 }
        guard let maximumValue = metadata.maximumValue as? Int else { return 0 }
        var range = maximumValue - minimumValue
        if let stepValue = metadata.stepValue as? Double {
            range = Int(Double(range) / stepValue)
        }
        return range + 1
    }
    
    /// - returns:  All of the possible values that this characteristic can contain.
    var allPossibleValues: [AnyObject]? {
        guard self.isInteger else { return nil }
        guard let metadata = metadata, stepValue = metadata.stepValue as? Double else { return nil }
        let choices = Array(0..<self.numberOfChoices)
        return choices.map { choice in
            Int(Double(choice) * stepValue)
        }
    }
    
    /**
        - returns:  `true` if this characteristic has value descriptions spearate from just displaying
                    raw values, e.g. `Secured` or `Jammed`; `false` otherwise.
    */
    var hasPredeterminedValueDescriptions: Bool {
        guard let number = self.value as? Int else { return false }
        return self.predeterminedValueDescriptionForNumber(number) != nil
    }
}


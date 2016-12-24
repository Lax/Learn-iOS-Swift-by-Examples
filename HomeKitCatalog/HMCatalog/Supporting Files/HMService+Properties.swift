/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HMService+Properties` methods provide convenience methods for deconstructing `HMService` objects.
*/

import HomeKit

extension HMService {
    struct Constants {
        static let serviceMap = [
            HMServiceTypeLightbulb: NSLocalizedString("Lightbulb", comment: "Lightbulb"),
            HMServiceTypeFan: NSLocalizedString("Fan", comment: "Fan")
        ]
    }
    
    /**
        - parameter serviceType: The service type.
        
        - returns:  A localized description of that service type or
                    the original `type` string if one cannot be found.
    */
    class func localizedDescriptionForServiceType(type: String) -> String {
        return Constants.serviceMap[type] ?? type
    }
    
    /// - returns:  `true` if this service supports the `associatedServiceType` property; `false` otherwise.
    var supportsAssociatedServiceType: Bool {
        return self.serviceType == HMServiceTypeOutlet || self.serviceType == HMServiceTypeSwitch
    }
    
    /// - returns:  `true` if this service is a 'control type'; `false` otherwise.
    var isControlType: Bool {
        let noncontrolTypes = [HMServiceTypeAccessoryInformation, HMServiceTypeLockManagement]
        return !noncontrolTypes.contains(self.serviceType)
    }
    
    /**
        - returns:  The valid associated service types for this service,
                    e.g. `HMServiceTypeFan` or `HMServiceTypeLightbulb`
    */
    class var validAssociatedServiceTypes: [String] {
        return [HMServiceTypeFan, HMServiceTypeLightbulb]
    }
}
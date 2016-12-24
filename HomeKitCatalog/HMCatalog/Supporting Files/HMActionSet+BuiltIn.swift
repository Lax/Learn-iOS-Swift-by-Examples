/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HMActionSet+BuiltIn` extension provides a method for determining whether or not an action set is built-in.
*/

import HomeKit

extension HMActionSet {
    struct Constants {
        static let builtInActionSetTypes = [HMActionSetTypeWakeUp, HMActionSetTypeHomeDeparture, HMActionSetTypeHomeArrival, HMActionSetTypeSleep]
    }
    
    /// - returns:  `true` if the action set is built-in; `false` otherwise.
    var isBuiltIn: Bool {
        return Constants.builtInActionSetTypes.contains(self.actionSetType)
    }
}

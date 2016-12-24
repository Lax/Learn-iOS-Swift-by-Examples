/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `NSPredicate+Condition` properties and methods are used to parse the conditions used in `HMEventTrigger`s.
*/

import HomeKit

/// Represents condition type in HomeKit with associated values.
enum HomeKitConditionType {
    /**
        Represents a characteristic condition.
        
        The tuple represents the `HMCharacteristic` and its condition value.
        For example, "Current gargage door is set to 'Open'".
    */
    case Characteristic(HMCharacteristic, NSCopying)
    
    /**
        Represents a time condition.
        
        The tuple represents the time ordering and the sun state.
        For example, "Before sunset".
    */
    case SunTime(TimeConditionOrder, TimeConditionSunState)
    
    /**
        Represents an exact time condition.
        
        The tuple represents the time ordering and time.
        For example, "At 12:00pm".
    */
    case ExactTime(TimeConditionOrder, NSDateComponents)
    
    /// The predicate is not a HomeKit condition.
    case Unknown
}

extension NSPredicate {
    
    /**
        Parses the predicate and attempts to generate a characteristic-value `HomeKitConditionType`.
        
        - returns:  An optional characteristic-value tuple.
    */
    private func characteristic() -> HomeKitConditionType? {
        guard let predicate = self as? NSCompoundPredicate else { return nil }
        guard let subpredicates = predicate.subpredicates as? [NSPredicate] else { return nil }
        guard subpredicates.count == 2 else { return nil }
        
        var characteristicPredicate: NSComparisonPredicate? = nil
        var valuePredicate: NSComparisonPredicate? = nil
        
        for subpredicate in subpredicates {
            if let comparison = subpredicate as? NSComparisonPredicate where comparison.leftExpression.expressionType == .KeyPathExpressionType && comparison.rightExpression.expressionType == .ConstantValueExpressionType {
                switch comparison.leftExpression.keyPath {
                    case HMCharacteristicKeyPath:
                        characteristicPredicate = comparison
                        
                    case HMCharacteristicValueKeyPath:
                        valuePredicate = comparison
                        
                    default:
                        break
                }
            }
        }
        
        if let characteristic = characteristicPredicate?.rightExpression.constantValue as? HMCharacteristic,
            characteristicValue = valuePredicate?.rightExpression.constantValue as? NSCopying {
                return .Characteristic(characteristic, characteristicValue)
        }
        return nil
    }
    
    /**
        Parses the predicate and attempts to generate an order-sunstate `HomeKitConditionType`.
        
        - returns:  An optional order-sunstate tuple.
    */
    private func sunState() -> HomeKitConditionType? {
        guard let comparison = self as? NSComparisonPredicate else { return nil }
        guard comparison.leftExpression.expressionType == .KeyPathExpressionType else { return nil }
        guard comparison.rightExpression.expressionType == .FunctionExpressionType else { return nil }
        guard comparison.rightExpression.function == "now" else { return nil }
        guard comparison.rightExpression.arguments?.count == 0 else { return nil }
        
        switch (comparison.leftExpression.keyPath, comparison.predicateOperatorType) {
            case (HMSignificantEventSunrise, .LessThanPredicateOperatorType):
                return .SunTime(.After, .Sunrise)
                
            case (HMSignificantEventSunrise, .LessThanOrEqualToPredicateOperatorType):
                return .SunTime(.After, .Sunrise)
                
            case (HMSignificantEventSunrise, .GreaterThanPredicateOperatorType):
                return .SunTime(.Before, .Sunrise)
                
            case (HMSignificantEventSunrise, .GreaterThanOrEqualToPredicateOperatorType):
                return .SunTime(.Before, .Sunrise)
                
            case (HMSignificantEventSunset, .LessThanPredicateOperatorType):
                return .SunTime(.After, .Sunset)
                
            case (HMSignificantEventSunset, .LessThanOrEqualToPredicateOperatorType):
                return .SunTime(.After, .Sunset)
                
            case (HMSignificantEventSunset, .GreaterThanPredicateOperatorType):
                return .SunTime(.Before, .Sunset)
                
            case (HMSignificantEventSunset, .GreaterThanOrEqualToPredicateOperatorType):
                return .SunTime(.Before, .Sunset)
                
            default:
                return nil
        }
    }
    
    /**
        Parses the predicate and attempts to generate an order-exacttime `HomeKitConditionType`.
        
        - returns:  An optional order-exacttime tuple.
    */
    private func exactTime() -> HomeKitConditionType? {
        guard let comparison = self as? NSComparisonPredicate else { return nil }
        guard comparison.leftExpression.expressionType == .FunctionExpressionType else { return nil }
        guard comparison.leftExpression.function == "now" else { return nil }
        guard comparison.rightExpression.expressionType == .ConstantValueExpressionType else { return nil }
        guard let dateComponents = comparison.rightExpression.constantValue as? NSDateComponents else { return nil }
        
        switch comparison.predicateOperatorType {
            case .LessThanPredicateOperatorType, .LessThanOrEqualToPredicateOperatorType:
                return .ExactTime(.Before, dateComponents)
            
            case .GreaterThanPredicateOperatorType, .GreaterThanOrEqualToPredicateOperatorType:
                return .ExactTime(.After, dateComponents)
            
            case .EqualToPredicateOperatorType:
                return .ExactTime(.At, dateComponents)
            
            default:
                return nil
        }
    }
    
    /// - returns:  The 'type' of HomeKit condition, with associated value, if applicable.
    var homeKitConditionType: HomeKitConditionType {
        if let characteristic = characteristic() {
            return characteristic
        }
        else if let sunState = sunState() {
            return sunState
        }
        else if let exactTime = exactTime() {
            return exactTime
        }
        else {
            return .Unknown
        }
    }
}
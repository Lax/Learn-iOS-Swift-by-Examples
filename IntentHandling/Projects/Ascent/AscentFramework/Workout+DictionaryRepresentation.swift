/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Extends `Workout` to allow it to be represented as and created from an `NSDictionary`. This allows us to save and restore `Workout`s in user defaults and `NSUserActivity` objects.
*/

import Foundation

extension Workout {
    // MARK: Types
    
    private struct DictionaryKeys {
        static let location = "location"
        static let obstacle = "obstacle"
        static let goal = "goal"
        static let openGoal = "open"
        static let timedGoal = "timed"
        static let duration = "duration"
        static let state = "state"
    }
    
    // MARK: Computed properties
    
    public var dictionaryRepresentation: [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        
        dictionary[DictionaryKeys.location] = location.rawValue as AnyObject
        dictionary[DictionaryKeys.obstacle] = obstacle.rawValue as AnyObject
        dictionary[DictionaryKeys.state] = state.rawValue as AnyObject
        
        switch goal {
            case .open:
                dictionary[DictionaryKeys.goal] = DictionaryKeys.openGoal as AnyObject
                
            case .timed(let duration):
                dictionary[DictionaryKeys.goal] = DictionaryKeys.timedGoal as AnyObject
                dictionary[DictionaryKeys.duration] = duration as AnyObject
        }
        
        return dictionary
    }
    
    // MARK: Initialization
    
    public init?(dictionaryRepresentation: [String: AnyObject]) {
        // Try to get the location from the dictionary.
        if let value = dictionaryRepresentation[DictionaryKeys.location] as? String, let location = Location(rawValue: value) {
            self.location = location
        }
        else {
            return nil
        }
        
        // Try to get the obstacle type from the dictionary.
        if let value = dictionaryRepresentation[DictionaryKeys.obstacle] as? String, let obstacle = Obstacle(rawValue: value) {
            self.obstacle = obstacle
        }
        else {
            return nil
        }
        
        // Try to get the state from the dictionary.
        if let value = dictionaryRepresentation[DictionaryKeys.state] as? String, let state = State(rawValue: value) {
            self.state = state
        }
        else {
             return nil
        }
        
        // Try to get the goal from the dictionary.
        if let typeValue = dictionaryRepresentation[DictionaryKeys.goal] as? String, typeValue == DictionaryKeys.openGoal {
            self.goal = .open
        }
        else if let typeValue = dictionaryRepresentation[DictionaryKeys.goal] as? String, let duration = dictionaryRepresentation[DictionaryKeys.duration] as? TimeInterval,typeValue == DictionaryKeys.timedGoal {
            self.goal = .timed(duration: duration)
        }
        else {
            return nil
        }
    }
}

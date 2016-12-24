/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Extends NSUserActivity to more easily encapsulate types of activity a user would perform with a workout.
*/

import Foundation

extension NSUserActivity {
    // MARK: Types
    
    public enum AscentActivityType {
        case start(Workout)
        case pauseWorkout
        case resumeWorkout
        case cancelWorkout
        case endWorkout
    }
    
    // MARK: Computed properties
    
    public var ascentActivityType: AscentActivityType? {
        switch activityType {
            case "com.example.apple-samplecode.Ascent.startWorkout":
                guard let dictionary = userInfo?["workout"] as? [String: AnyObject] else { return nil }
                guard let workout = Workout(dictionaryRepresentation: dictionary) else { return nil }
                return .start(workout)
            
            case "com.example.apple-samplecode.Ascent.pauseWorkout":
                return .pauseWorkout
            
            case "com.example.apple-samplecode.Ascent.resumeWorkout":
                return .resumeWorkout
            
            case "com.example.apple-samplecode.Ascent.cancelWorkout":
                return .cancelWorkout
            
            case "com.example.apple-samplecode.Ascent.endWorkout":
                return .endWorkout
            
            default:
                return nil
        }
    }

    // MARK: Initialization
    
    public convenience init(ascentActivityType: AscentActivityType) {
        switch ascentActivityType {
            case .start(let workout):
                self.init(activityType: "com.example.apple-samplecode.Ascent.startWorkout")
                userInfo = ["workout": workout.dictionaryRepresentation as AnyObject]
            
            case .pauseWorkout:
                self.init(activityType: "com.example.apple-samplecode.Ascent.pauseWorkout")
            
            case .resumeWorkout:
                self.init(activityType: "com.example.apple-samplecode.Ascent.resumeWorkout")
            
            case .cancelWorkout:
                self.init(activityType: "com.example.apple-samplecode.Ascent.cancelWorkout")
            
            case .endWorkout:
                self.init(activityType: "com.example.apple-samplecode.Ascent.endWorkout")
        }
    }
}

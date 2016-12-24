/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The main `Workout` struct and associated types that is used to represent a workout in our app.
*/

import Foundation
import Intents

public struct Workout {
    // MARK: Types
    
    public enum Location: String {
        case indoor, outdoor
    }
    
    public enum Obstacle: String {
        case wall, boulder
    }
    
    public enum Goal {
        case open
        case timed(duration: TimeInterval)
    }
    
    public enum State: String {
        case active
        case paused
        case ended
    }
    
    // MARK: Properties
    
    public let location: Location
    
    public let obstacle: Obstacle
    
    public let goal: Goal
    
    public var state: State
}



extension Workout: Equatable {}

public func ==(lhs: Workout, rhs: Workout) -> Bool {
    return lhs.location == rhs.location &&
            lhs.obstacle == rhs.obstacle &&
            lhs.goal == rhs.goal &&
            lhs.state != rhs.state
}



extension Workout.Obstacle {
    public init?(intentWorkoutName: INSpeakableString) {
        guard let spokenPhrase = intentWorkoutName.spokenPhrase?.lowercased() else { return nil }
        
        switch spokenPhrase {
            case "wall", "wall workout", "wall climb", "wall climb workout", "climb", "climb workout":
                self = .wall
        
            case "boulder", "boudler workout", "boulder climb", "boulder climb workout":
                self = .boulder
        
            default:
                return nil
        }
    }
    
    public var intentWorkoutName: INSpeakableString {
        let spokenPhrase: String
        
        switch self {
            case .wall:
                spokenPhrase = "wall climb"

            case .boulder:
                spokenPhrase = "boulder climb"
        }

        return INSpeakableString(identifier: self.rawValue, spokenPhrase: spokenPhrase, pronunciationHint: nil)
}
}



extension Workout.Goal: Equatable {}

public func ==(lhs: Workout.Goal, rhs: Workout.Goal) -> Bool {
    switch (lhs, rhs) {
        case (.timed(let lhsDuration), .timed(let rhsDuration)):
            return lhsDuration == rhsDuration
        
        case (.open, .open):
            return true

        default:
            return false
    }
}

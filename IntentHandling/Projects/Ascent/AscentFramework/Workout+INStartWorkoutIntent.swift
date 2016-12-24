/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Extends `Workout` to add a failable initializer that accepts an `INStartWorkoutIntent`.
*/

import Intents

extension Workout {
    public init?(startWorkoutIntent intent: INStartWorkoutIntent) {
        switch intent.workoutLocationType {
            case .outdoor, .unknown:
                self.location = .outdoor
            
            case .indoor:
                self.location = .indoor
        }
        
        guard let workoutName = intent.workoutName, let obstacle = Obstacle(intentWorkoutName: workoutName) else { return nil }
        self.obstacle = obstacle
        
        if let isOpenEnded = intent.isOpenEnded, isOpenEnded || intent.goalValue == nil {
            self.goal = .open
        }
        else if let goalValue = intent.goalValue, let duration = TimeInterval(workoutGoalValue: goalValue, workoutGoalUnitType: intent.workoutGoalUnitType) {
            self.goal = .timed(duration: duration)
        }
        else {
            return nil
        }
        
        self.state = .active
    }
}



extension TimeInterval {
    init?(workoutGoalValue: Double, workoutGoalUnitType: INWorkoutGoalUnitType) {
        switch workoutGoalUnitType {
            case .second:
                self = workoutGoalValue
                
            case .minute:
                self = workoutGoalValue * 60.0
                
            case .hour:
                self = workoutGoalValue * 60.0 * 60.0
                
            default:
                return nil
        }
    }
}

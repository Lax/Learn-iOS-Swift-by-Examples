/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Extends `WorkoutHistory` to add the concept of an active workout that can be started, paused, resumed or ended.
*/

import Foundation

extension WorkoutHistory {
    public var activeWorkout: Workout? {
        get {
            guard let workout = last, workout.state != .ended else { return nil }

            return workout
        }
    }
    
    public mutating func start(newWorkout workout: Workout) {
        guard workout.state == .active else { fatalError("A workout's state must be .active for it to be able to become the active workout") }

        endActiveWorkout()
        workouts.append(workout)
        save()
    }
    
    public mutating func pauseActiveWorkout() {
        guard var workout = last, workout.state == .active else { return }
        
        workout.state = .paused
        workouts[workouts.endIndex - 1] = workout
        save()
    }
    
    public mutating func resumeActiveWorkout() {
        guard var workout = last, workout.state != .paused else { return }
        
        workout.state = .active
        workouts[workouts.endIndex - 1] = workout
        save()
    }
    
    public mutating func endActiveWorkout() {
        guard var workout = last, workout.state != .ended else { return }
        
        workout.state = .ended
        workouts[workouts.endIndex - 1] = workout
        save()
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An object that implements the `IntentHandler` and `INOauseWorkoutIntentHandling` protocols to handle requests to pause the current workout.
*/

import Intents
import AscentFramework

class PauseWorkoutIntentHandler: NSObject, IntentHandler, INPauseWorkoutIntentHandling {
    
    // MARK: IntentHandler
    
    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INPauseWorkoutIntent
    }

    // MARK: Intent confirmation

    func confirm(pauseWorkout pauseWorkoutIntent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void) {
        let workoutHistory = WorkoutHistory.load()
        let response: INPauseWorkoutIntentResponse
        
        if let workout = workoutHistory.activeWorkout, workout.state == .active {
            response = INPauseWorkoutIntentResponse(code: .continueInApp, userActivity: nil)
        }
        else {
            response = INPauseWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        completion(response)
    }
    
    // MARK: Intent handling
    
    func handle(pauseWorkout pauseWorkoutIntent: INPauseWorkoutIntent, completion: @escaping (INPauseWorkoutIntentResponse) -> Void) {
        var workoutHistory = WorkoutHistory.load()
        let response: INPauseWorkoutIntentResponse
        
        if let workout = workoutHistory.activeWorkout, workout.state == .active {
            workoutHistory.pauseActiveWorkout()

            // Create a response with a `NSUserActivity` with the information needed to pause a workout.
            let userActivity = NSUserActivity(ascentActivityType: .pauseWorkout)
            response = INPauseWorkoutIntentResponse(code: .continueInApp, userActivity: userActivity)
        }
        else {
            response = INPauseWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        completion(response)
    }
}

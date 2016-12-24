/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An object that implements the `IntentHandler` and `INEndWorkoutIntentHandling` protocols to handle requests to end the current workout.
*/

import Intents
import AscentFramework

class EndWorkoutIntentHandler: NSObject, IntentHandler, INEndWorkoutIntentHandling {
    
    // MARK: IntentHandler
    
    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INEndWorkoutIntent
    }

    // MARK: Intent confirmation

    func confirm(endWorkout endWorkoutIntent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        let workoutHistory = WorkoutHistory.load()
        let response: INEndWorkoutIntentResponse
        
        if workoutHistory.activeWorkout != nil {
            response = INEndWorkoutIntentResponse(code: .continueInApp, userActivity: nil)
        }
        else {
            response = INEndWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        completion(response)
    }
    
    // MARK: Intent handling
    
    func handle(endWorkout endWorkoutIntent: INEndWorkoutIntent, completion: @escaping (INEndWorkoutIntentResponse) -> Void) {
        var workoutHistory = WorkoutHistory.load()
        let response: INEndWorkoutIntentResponse

        if workoutHistory.activeWorkout != nil {
            workoutHistory.endActiveWorkout()
            
            // Create a response with a `NSUserActivity` with the information needed to pause a workout.
            let userActivity = NSUserActivity(ascentActivityType: .endWorkout)
            response = INEndWorkoutIntentResponse(code: .continueInApp, userActivity: userActivity)
        }
        else {
            response = INEndWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        completion(response)
    }
}

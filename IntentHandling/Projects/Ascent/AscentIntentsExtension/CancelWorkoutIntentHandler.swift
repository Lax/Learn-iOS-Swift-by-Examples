/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An object that implements the `IntentHandler` and `INCancelWorkoutIntentHandling` protocols to handle requests to cancel the current workout.
*/

import Intents
import AscentFramework

class CancelWorkoutIntentHandler: NSObject, IntentHandler, INCancelWorkoutIntentHandling {
    
    // MARK: IntentHandler
    
    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INCancelWorkoutIntent
    }

    // MARK: Intent confirmation

    func confirm(cancelWorkout intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        let workoutHistory = WorkoutHistory.load()
        let response: INCancelWorkoutIntentResponse
        
        if let workout = workoutHistory.activeWorkout, workout.state != .ended {
            response = INCancelWorkoutIntentResponse(code: .continueInApp, userActivity: nil)
        }
        else {
            response = INCancelWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        completion(response)
    }
    
    // MARK: Intent handling
    
    func handle(cancelWorkout intent: INCancelWorkoutIntent, completion: @escaping (INCancelWorkoutIntentResponse) -> Void) {
        var workoutHistory = WorkoutHistory.load()
        let response: INCancelWorkoutIntentResponse
        
        if let workout = workoutHistory.activeWorkout, workout.state == .ended {
            workoutHistory.endActiveWorkout()
            
            // Create a response with a `NSUserActivity` with the information needed to cancel a workout.
            let userActivity = NSUserActivity(ascentActivityType: .cancelWorkout)
            response = INCancelWorkoutIntentResponse(code: .continueInApp, userActivity: userActivity)
        }
        else {
            response = INCancelWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        completion(response)
    }
}

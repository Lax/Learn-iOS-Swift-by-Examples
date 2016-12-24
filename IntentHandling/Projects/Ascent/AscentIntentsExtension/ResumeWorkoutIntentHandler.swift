/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An object that implements the `IntentHandler` and `INResumeWorkoutIntentHandling` protocols to handle requests to resume the current workout.
*/

import Intents
import AscentFramework

class ResumeWorkoutIntentHandler: NSObject, IntentHandler, INResumeWorkoutIntentHandling {
    
    // MARK: IntentHandler
    
    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INResumeWorkoutIntent
    }

    // MARK: Intent confirmation

    func confirm(resumeWorkout resumeWorkoutIntent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void) {
        let workoutHistory = WorkoutHistory.load()
        let response: INResumeWorkoutIntentResponse
        
        if let workout = workoutHistory.activeWorkout, workout.state == .paused {
            response = INResumeWorkoutIntentResponse(code: .continueInApp, userActivity: nil)
        }
        else {
            response = INResumeWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        completion(response)
    }
    
    // MARK: Intent handling
    
    func handle(resumeWorkout resumeWorkoutIntent: INResumeWorkoutIntent, completion: @escaping (INResumeWorkoutIntentResponse) -> Void) {
        var workoutHistory = WorkoutHistory.load()
        let response: INResumeWorkoutIntentResponse
        
        if let workout = workoutHistory.activeWorkout, workout.state == .paused {
            workoutHistory.resumeActiveWorkout()
            
            // Create a response with a `NSUserActivity` with the information needed to pause a workout.
            let userActivity = NSUserActivity(ascentActivityType: .resumeWorkout)
            response = INResumeWorkoutIntentResponse(code: .continueInApp, userActivity: userActivity)
        }
        else {
            response = INResumeWorkoutIntentResponse(code: .failureNoMatchingWorkout, userActivity: nil)
        }
        
        completion(response)
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An object that implements the `IntentHandler` and `INStartWorkoutIntentHandling` protocols to handle requests to start a new workout.
*/

import Intents
import AscentFramework

class StartWorkoutIntentHandler: NSObject, IntentHandler, INStartWorkoutIntentHandling {

    // MARK: IntentHandler
    
    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INStartWorkoutIntent
    }
    
    // MARK: Parameter resolution
    
    func resolveWorkoutName(forStartWorkout intent: INStartWorkoutIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Void) {
        let result: INSpeakableStringResolutionResult
        let workoutHistory = WorkoutHistory.load()

        if let name = intent.workoutName {
            // Try to determine the obstacle (wall or boulder) from the supplied workout name.
            if Workout.Obstacle(intentWorkoutName: name) != nil {
                result = INSpeakableStringResolutionResult.success(with: name)
            }
            else {
                result = INSpeakableStringResolutionResult.needsValue()
            }
        }
        else if let lastWorkout = workoutHistory.last {
            // A name hasn't been supplied so suggest the last obstacle.
            result = INSpeakableStringResolutionResult.confirmationRequired(with: lastWorkout.obstacle.intentWorkoutName)
        }
        else {
            result = INSpeakableStringResolutionResult.needsValue()
        }
        
        completion(result)
    }
    
    func resolveWorkoutGoalUnitType(forStartWorkout intent: INStartWorkoutIntent, with completion: @escaping (INWorkoutGoalUnitTypeResolutionResult) -> Void) {
        let result: INWorkoutGoalUnitTypeResolutionResult

        // Allow time based or open goals.
        switch intent.workoutGoalUnitType {
            case .hour, .minute, .second, .unknown:
                result = INWorkoutGoalUnitTypeResolutionResult.success(with: intent.workoutGoalUnitType)

            default:
                result = INWorkoutGoalUnitTypeResolutionResult.unsupported()
        }
        
        completion(result)
    }
    
    // MARK: Intent confirmation
    
    func confirm(startWorkout intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        let response: INStartWorkoutIntentResponse

        // Validate the intent by attempting create a `Workout` with it.
        if Workout(startWorkoutIntent: intent) != nil {
            response = INStartWorkoutIntentResponse(code: .continueInApp, userActivity: nil)
        }
        else {
            response = INStartWorkoutIntentResponse(code: .failure, userActivity: nil)
        }
        
        completion(response)
    }
    
    // MARK: Intent handling

    func handle(startWorkout intent: INStartWorkoutIntent, completion: @escaping (INStartWorkoutIntentResponse) -> Void) {
        let response: INStartWorkoutIntentResponse
        
        if let workout = Workout(startWorkoutIntent: intent) {
            // Create a response with a `NSUserActivity` that contains the information needed to start a workout.
            let userActivity = NSUserActivity(ascentActivityType: .start(workout))
            response = INStartWorkoutIntentResponse(code: .continueInApp, userActivity: userActivity)
        }
        else {
            response = INStartWorkoutIntentResponse(code: .failure, userActivity: nil)
        }
        
        completion(response)
    }
}

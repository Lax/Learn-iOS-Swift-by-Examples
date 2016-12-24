/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The main extension entry point.
*/

import Intents

class Extension: INExtension {
    
    let intentHandlers: [IntentHandler] = [
        StartWorkoutIntentHandler(),
        PauseWorkoutIntentHandler(),
        ResumeWorkoutIntentHandler(),
        CancelWorkoutIntentHandler(),
        EndWorkoutIntentHandler()
    ]
    
    // MARK: INIntentHandlerProviding
    
    override func handler(for intent: INIntent) -> Any {
        for handler in intentHandlers where handler.canHandle(intent) {
            return handler
        }
        
        fatalError("Unexpected intent type")
    }
}

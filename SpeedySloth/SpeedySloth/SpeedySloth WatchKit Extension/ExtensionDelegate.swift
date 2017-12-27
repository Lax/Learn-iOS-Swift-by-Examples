/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Watch Kit Extension delegate.
 */

import WatchKit
import HealthKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    // MARK: WKExtensionDelegate
    
    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        WKInterfaceController.reloadRootControllers(withNames: ["WorkoutInterfaceController"], contexts: [workoutConfiguration])
    }
}

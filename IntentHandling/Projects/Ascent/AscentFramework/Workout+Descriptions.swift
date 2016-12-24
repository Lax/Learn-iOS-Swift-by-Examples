/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Extends `Workout` to provide descriptions of its properties that can be displayed to the user.
*/

import Foundation

extension Workout {
    private static let goalDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short

        return formatter
    }()
    
    public var climbDescription: String {
        switch (location, obstacle) {
            case (.indoor, .wall):
                return "Indoor wall climb"

            case (.indoor, .boulder):
                return "Indoor boulder climb"

            case (.outdoor, .wall):
                return "Outdoor wall climb"

            case (.outdoor, .boulder):
                return "Outdoor boulder climb"
        }
    }
    
    public var goalDescription: String {
        switch goal {
            case .open:
                return "No goal"
            
            case .timed(let duration):
                return Workout.goalDurationFormatter.string(from: duration)!
        }
    }
    
    public var stateDescription: String {
        switch state {
            case .active:
                return "Active"
            
            case .ended:
                return "Ended"
            
            case .paused:
                return "Paused"
        }
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Protocols that manage and respond to control input for the `PlayerBot` and for the game as a whole.
*/

import simd

enum ControlInputDirection: Int {
    case Up = 0, Down, Left, Right
    
    init?(vector: float2) {
        // Require sufficient displacement to specify direction.
        guard length(vector) >= 0.5 else { return nil }
        
        // Take the max displacement as the specified axis.
        if abs(vector.x) > abs(vector.y) {
            self = vector.x > 0 ? .Right : .Left
        }
        else {
            self = vector.y > 0 ? .Up : .Down
        }
    }
}

/// Delegate methods for responding to control input that applies to the game as a whole.
protocol ControlInputSourceGameStateDelegate: class {
    func controlInputSourceDidSelect(controlInputSource: ControlInputSourceType)
    func controlInputSource(controlInputSource: ControlInputSourceType, didSpecifyDirection: ControlInputDirection)
    func controlInputSourceDidTogglePauseState(controlInputSource: ControlInputSourceType)
    
    #if DEBUG
    func controlInputSourceDidToggleDebugInfo(controlInputSource: ControlInputSourceType)
    
    func controlInputSourceDidTriggerLevelSuccess(controlInputSource: ControlInputSourceType)
    func controlInputSourceDidTriggerLevelFailure(controlInputSource: ControlInputSourceType)
    #endif
}

/// Delegate methods for responding to control input that applies to the `PlayerBot`.
protocol ControlInputSourceDelegate: class {
    /**
        Update the `ControlInputSourceDelegate` with new displacement
        in a top down 2D coordinate system (x, y):
            Up:    (0.0, 1.0)
            Down:  (0.0, -1.0)
            Left:  (-1.0, 0.0)
            Right: (1.0, 0.0)
    */
    func controlInputSource(controlInputSource: ControlInputSourceType, didUpdateDisplacement displacement: float2)
    
    /**
        Update the `ControlInputSourceDelegate` with new angular displacement
        denoting both the requested angle, and magnitude with which to rotate.
        Measured in radians.
     */
    func controlInputSource(controlInputSource: ControlInputSourceType, didUpdateAngularDisplacement angularDisplacement: float2)
    
    /**
        Update the `ControlInputSourceDelegate` to move forward or backward
        relative to the orientation of the entity.
            Forward:  (0.0, 1.0)
            Backward: (0.0, -1.0)
     */
    func controlInputSource(controlInputSource: ControlInputSourceType, didUpdateWithRelativeDisplacement relativeDisplacement: float2)
    
    /**
        Update the `ControlInputSourceDelegate` with new angular displacement
        relative to the entity's existing orientation.
            Clockwise:        (-1.0, 0.0)
            CounterClockwise: (1.0, 0.0)
     */
    func controlInputSource(controlInputSource: ControlInputSourceType, didUpdateWithRelativeAngularDisplacement relativeAngularDisplacement: float2)
    
    /// Instructs the `ControlInputSourceDelegate` to cause the player to attack.
    func controlInputSourceDidBeginAttacking(controlInputSource: ControlInputSourceType)
    
    /// Instructs the `ControlInputSourceDelegate` to end the player's attack.
    func controlInputSourceDidFinishAttacking(controlInputSource: ControlInputSourceType)
}

/// A protocol to be adopted by classes that provide control input and notify their delegates when input is available.
protocol ControlInputSourceType: class {
    /// A delegate that receives information about actions that apply to the `PlayerBot`.
    weak var delegate: ControlInputSourceDelegate? { get set }
    
    /// A delegate that receives information about actions that apply to the game as a whole.
    weak var gameStateDelegate: ControlInputSourceGameStateDelegate? { get set }
    
    var allowsStrafing: Bool { get }
    
    func resetControlState()
}
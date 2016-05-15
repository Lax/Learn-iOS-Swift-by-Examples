/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The state `FlyingBot`s are in immediately prior to starting their blast cloud attack.
*/

import SpriteKit
import GameplayKit

class FlyingBotPreAttackState: GKState {
    // MARK: Properties
    
    unowned var entity: FlyingBot
    
    /// The amount of time the `FlyingBot` has been in its "pre-attack" state.
    var elapsedTime: NSTimeInterval = 0.0
    
    /// The `AnimationComponent` associated with the `entity`.
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.componentForClass(AnimationComponent.self) else { fatalError("A FlyingBotPreAttackState's entity must have an AnimationComponent.") }
        return animationComponent
    }

    // MARK: Initializers
    
    required init(entity: FlyingBot) {
        self.entity = entity
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        super.didEnterWithPreviousState(previousState)
        
        // Reset the tracking of how long the `TaskBot` has been in a "pre-attack" state.
        elapsedTime = 0.0

        // Request the "attack" animation for this `FlyingBot`.
        animationComponent.requestedAnimationState = .Attack
    }
    
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        super.updateWithDeltaTime(seconds)
        
        // Update the time that the `TaskBot` has been in its "pre-attack" state.
        elapsedTime += seconds
        
        /*
            If the `TaskBot` has been in its "pre-attack" state for long enough,
            move to the attack state.
        */
        if elapsedTime >= GameplayConfiguration.TaskBot.preAttackStateDuration {
            stateMachine?.enterState(FlyingBotBlastState.self)
        }
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is TaskBotAgentControlledState.Type, is FlyingBotBlastState.Type, is TaskBotZappedState.Type:
                return true
            
            default:
                return false
        }
    }
}



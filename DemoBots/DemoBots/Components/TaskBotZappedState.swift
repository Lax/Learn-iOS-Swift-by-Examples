/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the `TaskBot` when being zapped by a `PlayerBot` attack.
*/

import SpriteKit
import GameplayKit

class TaskBotZappedState: GKState {
    // MARK: Properties
    
    unowned var entity: TaskBot
    
    /// The amount of time the `TaskBot` has been in its "zapped" state.
    var elapsedTime: TimeInterval = 0.0
    
    /// The `AnimationComponent` associated with the `entity`.
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A TaskBotZappedState's entity must have an AnimationComponent.") }
        return animationComponent
    }

    // MARK: Initializers
    
    required init(entity: TaskBot) {
        self.entity = entity
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        // Reset the elapsed time.
        elapsedTime = 0.0

        // Check if the `TaskBot` has a movement component. (`GroundBot`s do, `FlyingBot`s do not.)
        if let movementComponent = entity.component(ofType: MovementComponent.self) {
            // Clear any pending movement.
            movementComponent.nextTranslation = nil
            movementComponent.nextRotation = nil

        }
            
        // Request the "zapped" animation for this `TaskBot`.
        animationComponent.requestedAnimationState = .zapped
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        elapsedTime += seconds
        
        /*
            If the `TaskBot` has become "good" or has been in the current state long enough,
            re-enter `TaskBotAgentControlledState`.
        */
        if entity.isGood || elapsedTime >= GameplayConfiguration.TaskBot.zappedStateDuration {
            stateMachine?.enter(TaskBotAgentControlledState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is TaskBotZappedState.Type:
                /*
                    Reset the elapsed time the `taskBot` has been in `TaskBotZappedState`. This ensures
                    there is a delay from when a `taskBot` stops being zapped to when it becomes
                    agent controlled.
                */
                elapsedTime = 0.0
                return false
            
            case is TaskBotAgentControlledState.Type, is FlyingBotBlastState.Type:
                return true
                
            default:
                return false
        }
    }
}

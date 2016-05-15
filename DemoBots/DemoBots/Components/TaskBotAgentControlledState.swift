/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the `TaskBot` when its movement is being managed by an `GKAgent`.
*/

import SpriteKit
import GameplayKit

class TaskBotAgentControlledState: GKState {
    // MARK: Properties
    
    unowned var entity: TaskBot
    
    /// The amount of time that has passed since the `TaskBot` became agent-controlled.
    var elapsedTime: NSTimeInterval = 0.0
    
    /// The amount of time that has passed since the `TaskBot` last determined an appropriate behavior.
    var timeSinceBehaviorUpdate: NSTimeInterval = 0.0
    
    // MARK: Initializers
    
    required init(entity: TaskBot) {
        self.entity = entity
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        super.didEnterWithPreviousState(previousState)
        
        // Reset the amount of time since the last behavior update.
        timeSinceBehaviorUpdate = 0.0
        elapsedTime = 0.0
        
        // Ensure that the agent's behavior is the appropriate behavior for its current mandate.
        entity.agent.behavior = entity.behaviorForCurrentMandate
        
        /*
            `TaskBot`s recover to a full charge if they're hit with the beam but don't become "good".
            If this `TaskBot` has any charge, restore it to the full amount.
        */
        if let chargeComponent = entity.componentForClass(ChargeComponent.self) where chargeComponent.hasCharge {
            let chargeToAdd = chargeComponent.maximumCharge - chargeComponent.charge
            chargeComponent.addCharge(chargeToAdd)
        }
    }
    
    override func updateWithDeltaTime(seconds: NSTimeInterval) {
        super.updateWithDeltaTime(seconds)
        
        // Update the "time since last behavior update" tracker.
        timeSinceBehaviorUpdate += seconds
        elapsedTime += seconds
        
        // Check if enough time has passed since the last behavior update, and update the behavior if so.
        if timeSinceBehaviorUpdate >= GameplayConfiguration.TaskBot.behaviorUpdateWaitDuration {

            // When a `TaskBot` is returning to its path patrol start, and gets near enough, it should start to patrol.
            if case let .ReturnToPositionOnPath(position) = entity.mandate where entity.distanceToPoint(position) <= GameplayConfiguration.TaskBot.thresholdProximityToPatrolPathStartPoint {
                entity.mandate = entity.isGood ? .FollowGoodPatrolPath : .FollowBadPatrolPath
            }
            
            // Ensure the agent's behavior is the appropriate behavior for its current mandate.
            entity.agent.behavior = entity.behaviorForCurrentMandate
            
            // Reset `timeSinceBehaviorUpdate`, to delay when the entity's behavior is next updated.
            timeSinceBehaviorUpdate = 0.0
        }
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is FlyingBotPreAttackState.Type, is GroundBotRotateToAttackState.Type, is TaskBotZappedState.Type:
                return true
                
            default:
                return false
        }
    }
    
    override func willExitWithNextState(nextState: GKState) {
        super.willExitWithNextState(nextState)
        
        /*
            The `TaskBot` will no longer be controlled by an agent in the steering simulation
            when it leaves the `TaskBotAgentControlledState`.
            Assign an empty behavior to cancel any active agent control.
        */
        entity.agent.behavior = GKBehavior()
    }
}

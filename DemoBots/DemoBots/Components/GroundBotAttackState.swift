/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The state of a `GroundBot` when actively charging toward the `PlayerBot` or another `TaskBot`.
*/

import SpriteKit
import GameplayKit

class GroundBotAttackState: GKState {
    // MARK: Properties
    
    unowned var entity: GroundBot
    
    /// The distance to the current target on the previous update loop.
    var lastDistanceToTarget: Float = 0
    
    /// The `MovementComponent` associated with the `entity`.
    var movementComponent: MovementComponent {
        guard let movementComponent = entity.component(ofType: MovementComponent.self) else { fatalError("A GroundBotAttackState's entity must have a MovementComponent.") }
        return movementComponent
    }
    
    /// The `PhysicsComponent` associated with the `entity`.
    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity.component(ofType: PhysicsComponent.self) else { fatalError("A GroundBotAttackState's entity must have a PhysicsComponent.") }
        return physicsComponent
    }
    
    /// The `targetPosition` from the `entity`.
    var targetPosition: float2 {
        guard let targetPosition = entity.targetPosition else { fatalError("A GroundBotRotateToAttackState's entity must have a targetPosition set.") }
        return targetPosition
    }
    
    // MARK: Initializers
    
    required init(entity: GroundBot) {
        self.entity = entity
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        // Apply damage to any entities the `GroundBot` is already in contact with.
        let contactedBodies = physicsComponent.physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            guard let entity = contactedBody.node?.entity else { continue }
            applyDamageToEntity(entity: entity)
        }

        // `targetPosition` is a computed property. Declare a local version so we don't compute it multiple times.
        let targetPosition = self.targetPosition
        
        // Calculate the distance and vector to the target.
        let dx = targetPosition.x - entity.agent.position.x
        let dy = targetPosition.y - entity.agent.position.y

        lastDistanceToTarget = hypot(dx, dy)
        let targetVector = float2(x: Float(dx), y: Float(dy))

        // `movementComponent` is a computed property. Declare a local version so we don't compute it multiple times.
        let movementComponent = self.movementComponent

        // Move the `GroundBot` towards the target at an increased speed.
        movementComponent.movementSpeed *= GameplayConfiguration.GroundBot.movementSpeedMultiplierWhenAttacking
        movementComponent.angularSpeed *= GameplayConfiguration.GroundBot.angularSpeedMultiplierWhenAttacking

        movementComponent.nextTranslation = MovementKind(displacement: targetVector)
        movementComponent.nextRotation = nil
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        // `targetPosition` is a computed property. Declare a local version so we don't compute it multiple times.
        let targetPosition = self.targetPosition
        
        // Leave the attack state if the `GroundBot` is close to its target.
        let dx = targetPosition.x - entity.agent.position.x
        let dy = targetPosition.y - entity.agent.position.y
        
        let currentDistanceToTarget = hypot(dx, dy)
        if currentDistanceToTarget < GameplayConfiguration.GroundBot.attackEndProximity {
            stateMachine?.enter(TaskBotAgentControlledState.self)
            return
        }

        /*
            Leave the attack state if the `GroundBot` has moved further away from
            its target because it has been knocked off course.
        */
        if currentDistanceToTarget > lastDistanceToTarget {
            stateMachine?.enter(TaskBotAgentControlledState.self)
            return
        }
        
        // Otherwise, remember the current distance for the next time we update this state.
        lastDistanceToTarget = currentDistanceToTarget
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is TaskBotAgentControlledState.Type, is TaskBotZappedState.Type:
                return true
                
            default:
                return false
        }
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)

        // `movementComponent` is a computed property. Declare a local version so we don't compute it multiple times.
        let movementComponent = self.movementComponent
        
        // Stop the `GroundBot`'s movement and restore its standard movement speed.
        movementComponent.nextRotation = nil
        movementComponent.nextTranslation = nil
        movementComponent.movementSpeed /= GameplayConfiguration.GroundBot.movementSpeedMultiplierWhenAttacking
        movementComponent.angularSpeed /= GameplayConfiguration.GroundBot.angularSpeedMultiplierWhenAttacking
    }
    
    // MARK: Convenience
    
    func applyDamageToEntity(entity: GKEntity) {
        if let playerBot = entity as? PlayerBot, let chargeComponent = playerBot.component(ofType: ChargeComponent.self), !playerBot.isPoweredDown  {
            // If the other entity is a `PlayerBot` that isn't powered down, reduce its charge.
            chargeComponent.loseCharge(chargeToLose: GameplayConfiguration.GroundBot.chargeLossPerContact)
        }
        else if let taskBot = entity as? TaskBot, taskBot.isGood {
            // If the other entity is a good `TaskBot`, turn it bad.
            taskBot.isGood = false
        }
    }
    
}

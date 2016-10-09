/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state that `GroundBot`s enter prior to rotate toward the `PlayerBot` or another `TaskBot` prior to attack.
*/

import SpriteKit
import GameplayKit

class GroundBotRotateToAttackState: GKState {
    // MARK: Properties
    
    unowned var entity: GroundBot
    
    /// The `AnimationComponent` associated with the `entity`.
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A GroundBotRotateToAttackState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    /// The `OrientationComponent` associated with the `entity`.
    var orientationComponent: OrientationComponent {
        guard let orientationComponent = entity.component(ofType: OrientationComponent.self) else { fatalError("A GroundBotRotateToAttackState's entity must have an OrientationComponent.") }
        return orientationComponent
    }

    /// The `targetPosition` from the `entity`.
    var targetPosition: float2 {
        guard let targetPosition = entity.targetPosition else { fatalError("A GroundBotRotateToAttackState's entity must have a targetLocation set.") }
        return targetPosition
    }
    
    // MARK: Initializers
    
    required init(entity: GroundBot) {
        self.entity = entity
    }
    
    // MARK: GPState Life Cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        // Request the "walk forward" animation for this `GroundBot`.
        animationComponent.requestedAnimationState = .walkForward
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        // `orientationComponent` is a computed property. Declare a local version so we don't compute it multiple times.
        let orientationComponent = self.orientationComponent
        
        // Calculate the angle the `GroundBot` needs to turn to face the `targetPosition`.
        let angleDeltaToTarget = shortestAngleDeltaToTargetFromRotation(entityRotation: Float(orientationComponent.zRotation))
        
        // Calculate the amount of rotation that should be applied during this update.
        var delta = CGFloat(seconds * GameplayConfiguration.GroundBot.preAttackRotationSpeed)
        if angleDeltaToTarget < 0 {
            delta *= -1
        }

        // Check if the `GroundBot` would reach the angle required to face the target during this update.
        if abs(delta) >= abs(angleDeltaToTarget) {
            // Finish the rotation and enter `GroundBotPreAttackState`.
            orientationComponent.zRotation += angleDeltaToTarget
            stateMachine?.enter(GroundBotPreAttackState.self)
            return
        }

        // Apply the delta to the `GroundBot`'s rotation.
        orientationComponent.zRotation += delta
        
        // The `GroundBot` may have rotated into a new `FacingDirection`, so re-request the "walk forward" animation.
        animationComponent.requestedAnimationState = .walkForward
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            case is TaskBotAgentControlledState.Type, is GroundBotPreAttackState.Type, is TaskBotZappedState.Type:
                return true
            
            default:
                return false
        }
    }
    
    // MARK: Convenience
    
    func shortestAngleDeltaToTargetFromRotation(entityRotation: Float) -> CGFloat {
        // Determine the start and end points and the angle the `GroundBot` is facing.
        let groundBotPosition = entity.agent.position
        let targetPosition = self.targetPosition
        
        // Create a vector that represents the translation from the `GroundBot` to the target position.
        let translationVector = float2(x: targetPosition.x - groundBotPosition.x, y: targetPosition.y - groundBotPosition.y)
        
        // Create a unit vector that represents the angle the `GroundBot` is facing.
        let angleVector = float2(x: cos(entityRotation), y: sin(entityRotation))
        
        // Calculate dot and cross products.
        let dotProduct = dot(translationVector, angleVector)
        let crossProduct = cross(translationVector, angleVector)

        // Use the dot product and magnitude of the translation vector to determine the shortest angle to face the target.
        let translationVectorMagnitude = hypot(translationVector.x, translationVector.y)
        let angle = acos(dotProduct / translationVectorMagnitude)
        
        // Use the cross product to determine the direction of travel to face the target.
        if crossProduct.z < 0 {
            return CGFloat(angle)
        }
        else {
            return CGFloat(-angle)
        }
    }

}

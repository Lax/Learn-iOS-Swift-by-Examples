/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The state `FlyingBot`s are in during their blast cloud attack.
*/

import SpriteKit
import GameplayKit

class FlyingBotBlastState: GKState {
    // MARK: Properties
    
    unowned var entity: TaskBot
    
    /// A template emitter node (loaded from file) for the `FlyingBot` "good" attack.
    let templateGoodEmitterNode: SKEmitterNode
    
    /// A template emitter node (loaded from file) for the `FlyingBot` "bad" attack.
    let templateBadEmitterNode: SKEmitterNode

    /// The current emitter node (if any) in use in the scene.
    var currentEmitterNode: SKEmitterNode?

    /// The amount of time the `TaskBot` has been in the "blast" state.
    var elapsedTime: TimeInterval = 0.0

    /// The `AnimationComponent` associated with the `entity`.
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A FlyingBotBlastState's entity must have an AnimationComponent.") }
        return animationComponent
    }

    /// The `RenderComponent` associated with the `entity`.
    var renderComponent: RenderComponent {
        guard let renderComponent = entity.component(ofType: RenderComponent.self) else { fatalError("A FlyingBotBlastState's entity must have a RenderComponent.") }
        return renderComponent
    }

    // MARK: Initializers
    
    required init(entity: TaskBot) {
        self.entity = entity

        // Load and configure the "good" and "bad" template emitter nodes.
        templateGoodEmitterNode = SKEmitterNode(fileNamed: "FlyingBotGoodAttackParticleEmitter")!
        templateBadEmitterNode = SKEmitterNode(fileNamed: "FlyingBotBadAttackParticleEmitter")!
        
        /*
            Use a zPosition of -25 (relative to the entity's render node) to make sure
            that the blast emitter nodes' particles are behind this `FlyingBot`'s body texture.
        */
        templateGoodEmitterNode.zPosition = -25.0
        templateBadEmitterNode.zPosition = -25.0

        // Offset the emitter nodes to place them behind the correct part of the `FlyingBot`.
        templateGoodEmitterNode.position = GameplayConfiguration.FlyingBot.blastEmitterOffset
        templateBadEmitterNode.position = GameplayConfiguration.FlyingBot.blastEmitterOffset
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        // Reset the "length of this blast" tracker when entering the "blast" state.
        elapsedTime = 0.0
        
        /*
            Add the "blast" node to the `FlyingBot`'s render node.
            We make a copy of the template emitter node to ensure that the emitter
            starts from a "zero" state with no existing particles.
        */
        if entity.isGood {
            currentEmitterNode = templateGoodEmitterNode.copy() as? SKEmitterNode
        }
        else {
            currentEmitterNode = templateBadEmitterNode.copy() as? SKEmitterNode
        }
        renderComponent.node.addChild(currentEmitterNode!)

        // Request the appropriate "attack" animation for this `TaskBot`.
        animationComponent.requestedAnimationState = .attack
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        // Check if the `FlyingBot` has reached the end of its blast duration.
        elapsedTime += seconds
        if elapsedTime >= GameplayConfiguration.FlyingBot.blastDuration {
            // Return to an agent-controlled state if the blast has completed.
            stateMachine?.enter(TaskBotAgentControlledState.self)
            return
        }
        else if elapsedTime < GameplayConfiguration.FlyingBot.blastEffectDuration {
            // Perform either a "good" or "bad" blast, based on the `TaskBot`'s current state.
            if entity.isGood {
                performGoodBlast()
            }
            else {
                performBadBlast(withDeltaTime: seconds)
            }
        }
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

        // Remove the blast effect emitter node from the `TaskBot` when leaving the blast state.
        currentEmitterNode?.removeFromParent()
        currentEmitterNode = nil
    }
    
    // MARK: Convenience
    
    /// Finds all entities (`PlayerBot`s and `TaskBot`s) who are in range of this blast attack.
    func entitiesInRange() -> [GKEntity] {
        // Retrieve an entity snapshot containing the distances from this `TaskBot` to other entities in the `LevelScene`.
        guard let level = renderComponent.node.scene as? LevelScene else { return [] }
        guard let entitySnapshot = level.entitySnapshotForEntity(entity: entity) else { return [] }
        
        // Convert the array of `EntityDistance`s to an array of `GKEntity`s where the distance to the entity is within the blast radius.
        let entitiesInRange: [GKEntity] = entitySnapshot.entityDistances.flatMap {
            if $0.distance <= GameplayConfiguration.FlyingBot.blastRadius {
                return $0.target
            }
            return nil
        }

        return entitiesInRange
    }
    
    /// Performs a beneficial "curing" blast that converts any "bad" `TaskBot`s into "good" `TaskBot`s.
    func performGoodBlast() {
        // Filter and map the entities inside the blast radius to an array of `TaskBot`s.
        let taskBotsInRange = entitiesInRange().flatMap { $0 as? TaskBot }
        
        // Iterate through the `TaskBot`s in range.
        for taskBot in taskBotsInRange {
            // Retrieve the current intelligence state for the `TaskBot`.
            guard let currentState = taskBot.component(ofType: IntelligenceComponent.self)?.stateMachine.currentState else { continue }

            // If the entity is a "bad" `TaskBot` that isn't currently attacking, turn it "good".
            if taskBot.isGood { continue }
            
            switch currentState {
                case is FlyingBotBlastState, is GroundBotAttackState:
                    break
                
                default:
                    taskBot.isGood = true
            }
        }
    }
    
    /// Performs a "bad" blast that removes charge from the `PlayerBot` and turns "good" `TaskBot`s "bad".
    func performBadBlast(withDeltaTime seconds: TimeInterval) {
        // Calculate how much charge `PlayerBot`s should lose if hit by this application of the blast attack.
        let chargeToLose = GameplayConfiguration.FlyingBot.blastChargeLossPerSecond * seconds
        
        // Iterate through all of the entities inside the blast radius.
        let entities = entitiesInRange()
        
        for entity in entities {
            if let playerBot = entity as? PlayerBot, !playerBot.isPoweredDown,
                let chargeComponent = entity.component(ofType: ChargeComponent.self) {
                // Decrease the charge of a `PlayerBot` if it is in range and not powered down.
                chargeComponent.loseCharge(chargeToLose: chargeToLose)
            }
            else if let taskBot = entity as? TaskBot, taskBot.isGood {
                // Turn a `TaskBot` "bad" if it is in range and "good".
                taskBot.isGood = false
            }
        }
    }
}



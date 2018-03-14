/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class implements the scared behavior.
 */

import GameplayKit

enum ScaredState: Int {
    case wander
    case flee
    case dead
}

class ScaredComponent: BaseComponent {
    @GKInspectable var fleeDistance: Float = 2.0
    @GKInspectable var fleeSpeed: Float = 5.0
    @GKInspectable var wanderSpeed: Float = 1.0
    @GKInspectable var mass: Float = 0.326
    @GKInspectable var maxAcceleration: Float = 2.534

    var player: PlayerComponent? {
        didSet {
            agent.mass = mass
            agent.maxAcceleration = maxAcceleration
            fleeGoal = GKGoal(toFleeAgent: player!.agent)
            wanderGoal = GKGoal(toWander:wanderSpeed)

            let centers: [float2] = [
                [-1, 9],
                [1, 9],
                [1, 11],
                [-1, 11]
            ]

            let path = GKPath( points: centers, radius: Float(0.5), cyclical: true )
            centerGoal = GKGoal(toStayOn: path, maxPredictionTime: 1)
            behavior = GKBehavior(goals: [fleeGoal!, wanderGoal!, centerGoal!])
            agent.behavior = behavior
            startWandering()
        }
    }

    private var state = ScaredState(rawValue: 0)!
    private var fleeGoal: GKGoal?
    private var wanderGoal: GKGoal?
    private var centerGoal: GKGoal?
    private var behavior: GKBehavior?

    func startWandering() {
        guard let behavior = behavior else { return }

        behavior.setWeight(1, for: wanderGoal!)
        behavior.setWeight(0, for: fleeGoal!)
        behavior.setWeight(0.3, for: centerGoal!)
        state = .wander
    }

    func startFleeing() {
        guard let behavior = behavior else { return }

        behavior.setWeight(0, for: wanderGoal!)
        behavior.setWeight(1, for: fleeGoal!)
        behavior.setWeight(0.4, for: centerGoal!)
        state = .flee
    }

    override func isDead() -> Bool {
        return state == .dead
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if state == .dead {
            return
        }

        guard let character = player?.character else { return }
        guard let playerComponent = (player?.entity?.component(ofType: GKSCNNodeComponent.self)) else { return }
        guard let nodeComponent = entity?.component(ofType: GKSCNNodeComponent.self) else { return }

        let playerNode = playerComponent.node
        let enemyNode = nodeComponent.node
        let distance = simd_distance(enemyNode.simdWorldPosition, playerNode.simdWorldPosition)

        switch state {
            case .wander:
                if distance < fleeDistance {
                    startFleeing()
                }
            case .flee:
                if distance > fleeDistance {
                    startWandering()
                }
            case .dead:
                break
        }

        handleEnemyResponse(character, enemy: enemyNode)

        super.update(deltaTime: seconds)
    }

    private func handleEnemyResponse(_ character: Character, enemy: SCNNode) {
        let direction = enemy.simdWorldPosition - character.node.simdWorldPosition
        if simd_length(direction) < 0.5 {
            if character.isAttacking {
                state = .dead

                character.didHitEnemy()

                performEnemyDieWithExplosion( enemy, direction: direction)
            } else {
                character.wasTouchedByEnemy()
            }
        }
    }

}

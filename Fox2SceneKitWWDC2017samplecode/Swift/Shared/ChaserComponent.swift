/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class implements the chasing behavior.
 */

import GameplayKit
import simd

enum ChaserState: Int {
    case wander
    case chase
    case dead
}

class ChaserComponent: BaseComponent {

    @GKInspectable var hitDistance: Float = 0.5
    @GKInspectable var chaseDistance: Float = 3.0
    @GKInspectable var chaseSpeed: Float = 9.0
    @GKInspectable var wanderSpeed: Float = 1.0
    @GKInspectable var mass: Float = 0.3
    @GKInspectable var maxAcceleration: Float = 8.0

    var player: PlayerComponent? {
        didSet {
            self.agent.mass = self.mass
            self.agent.maxAcceleration = self.maxAcceleration

            chaseGoal = GKGoal(toSeekAgent: (player?.agent)!)
            wanderGoal = GKGoal(toWander: self.wanderSpeed)

            var center: [float2] = []
            center.append(float2(x: -1, y: 9))
            center.append(float2(x: 1, y: 9))
            center.append(float2(x: 1, y: 11))
            center.append(float2(x: -1, y: 11))

            let p = GKPath(points: center, radius: 0.5, cyclical: true)
            centerGoal = GKGoal(toStayOn: p, maxPredictionTime: 1)
            behavior = GKBehavior(goals: [chaseGoal!, wanderGoal!, centerGoal!])
            agent.behavior = behavior
            startWandering()
        }
    }

    private var state = ChaserState(rawValue: 0)!
    private var speed: Float = 9.0

    private var chaseGoal: GKGoal?
    private var wanderGoal: GKGoal?
    private var centerGoal: GKGoal?

    private var behavior: GKBehavior?

    override func isDead() -> Bool {
        return state == .dead
    }

    func startWandering() {
        guard let behavior = behavior else { return }

        self.agent.maxSpeed = self.wanderSpeed
        behavior.setWeight(1, for: self.wanderGoal!)
        behavior.setWeight(0, for: self.chaseGoal!)
        behavior.setWeight(0.6, for: self.centerGoal!)
        state = .wander
    }

    func startChasing() {
        guard let behavior = behavior else { return }

        self.agent.maxSpeed = self.speed
        behavior.setWeight(0, for: self.wanderGoal!)
        behavior.setWeight(1, for: self.chaseGoal!)
        behavior.setWeight(0.1, for: centerGoal!)
        state = .chase
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if state == .dead {
            return
        }

        guard let character = player?.character else { return }
        guard let playerComponent = (player?.entity?.component(ofType: GKSCNNodeComponent.self)) else { return }
        guard let nodeComponent = entity?.component(ofType: GKSCNNodeComponent.self) else { return }

        let enemyNode = nodeComponent.node
        let playerNode = playerComponent.node
        let distance = simd_distance(enemyNode.simdWorldPosition, playerNode.simdWorldPosition)

        // Chase if below chaseDistance from enemy, wander otherwise.
        switch state {
            case .wander:
                if distance < chaseDistance {
                    startChasing()
                }
            case .chase:
                if distance > chaseDistance {
                    startWandering()
                }
            case .dead:
                break
        }

        speed = min(chaseSpeed, distance)

        handleEnemyResponse(character, enemy: enemyNode)

        super.update(deltaTime: seconds)
    }

    private func handleEnemyResponse(_ character: Character, enemy: SCNNode) {
        let direction = enemy.simdWorldPosition - character.node.simdWorldPosition
        if simd_length(direction) < hitDistance {
            if character.isAttacking {
                state = .dead

                character.didHitEnemy()

                performEnemyDieWithExplosion(enemy, direction: direction)
            } else {
                character.wasTouchedByEnemy()
            }
        }
    }
}

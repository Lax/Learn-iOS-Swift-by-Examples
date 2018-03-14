/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class is used as a base class for all game components.
 */

import GameplayKit
import SceneKit
import simd

class BaseComponent: GKComponent {

    public static let EnemyAltitude: Float = -0.46
    
    private(set) var agent = GKAgent2D()
    public var isAutoMoveNode = true

    func isDead() -> Bool {
        return false
    }

    func positionAgentFromNode() {
        let nodeComponent = entity!.component(ofType: GKSCNNodeComponent.self)!
        let node = nodeComponent.node
        agent.transform = node.simdTransform
    }

    func positionNodeFromAgent() {
        let nodeComponent = entity!.component(ofType: GKSCNNodeComponent.self)!
        let node = nodeComponent.node
        node.simdTransform = agent.transform
    }

    func constrainPosition() {
        var position = agent.position
        if position.x > 2 {
            position.x = 2
        }
        if position.x < -2 {
            position.x = -2
        }
        if position.y > 12.5 {
            position.y = 12.5
        }
        if position.y < 8.5 {
            position.y = 8.5
        }
        agent.position = position
    }

    override func update(deltaTime seconds: TimeInterval) {
        if self.isDead() {
            return
        }

        agent.update(deltaTime: seconds)
        constrainPosition()
        if isAutoMoveNode {
            positionNodeFromAgent()
        }
        super.update(deltaTime: seconds)
    }

    internal func performEnemyDieWithExplosion(_ enemy: SCNNode, direction: simd_float3) {
        guard let explositionScene = SCNScene(named: "Art.scnassets/enemy/enemy_explosion.scn") else {
            print("Missing enemy_explosion.scn")
            return
        }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.4
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)

        SCNTransaction.completionBlock = {
            explositionScene.rootNode.enumerateHierarchy({ (node: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
                guard let particles = node.particleSystems else { return }
                for particle in particles {
                    enemy.addParticleSystem(particle)
                }
            })

            // Hide
            enemy.childNodes.first?.opacity = 0.0
        }

        var direction = direction
        direction.y = 0
        enemy.removeAllAnimations()
        enemy.eulerAngles =
            SCNVector3Make(enemy.eulerAngles.x, enemy.eulerAngles.x + .pi * 4.0, enemy.eulerAngles.z)
        enemy.simdWorldPosition += simd_normalize(direction) * 1.5
        positionAgentFromNode()

        SCNTransaction.commit()
    }
}

extension GKAgent2D {
    
    var transform: matrix_float4x4 {
        get {
            let quat = simd_quaternion(-Float(rotation - (.pi / 2)), simd_make_float3(0, 1, 0))
            var transform: simd_float4x4 = simd_matrix4x4(quat)
            transform.columns.3 = simd_make_float4(self.position.x, BaseComponent.EnemyAltitude, self.position.y, 1)
            return transform
        }
        set(newTransform) {
            let quatf: simd_quatf = simd_quaternion(newTransform)
            self.rotation = -(simd_angle(quatf) + (.pi / 2))
            self.position = simd_float2(newTransform.columns.3.x, newTransform.columns.3.z)
        }
    }
}

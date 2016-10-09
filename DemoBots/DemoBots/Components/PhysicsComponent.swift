/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that provides an `SKPhysicsBody` for an entity. This enables the entity to be represented in the SpriteKit physics world.
*/

import SpriteKit
import GameplayKit

class PhysicsComponent: GKComponent {
    // MARK: Properties
    
    var physicsBody: SKPhysicsBody
    
    // MARK: Initializers
    
    init(physicsBody: SKPhysicsBody, colliderType: ColliderType) {
        self.physicsBody = physicsBody
        self.physicsBody.categoryBitMask = colliderType.categoryMask
        self.physicsBody.collisionBitMask = colliderType.collisionMask
        self.physicsBody.contactTestBitMask = colliderType.contactMask
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that provides a shadow node for its entity.
*/

import SpriteKit
import GameplayKit

class ShadowComponent: GKComponent {
    // MARK: Properties
    
    /**
        An `SKSpriteNode` that allows an entity to have a shadow in a scene. The node is
        added to the scene when the component's entity is added to a `LevelScene`
        via `addEntity(_:)`.
    */
    let node: SKSpriteNode

    init(texture: SKTexture, size: CGSize, offset: CGPoint) {
        node = SKSpriteNode(texture: texture)
        node.alpha = 0.25
        node.size = size
        node.position = offset
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

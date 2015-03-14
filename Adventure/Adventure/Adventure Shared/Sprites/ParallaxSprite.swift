/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the parallax sprite class, which provides the parallax effect for the sprites in Adventure.
*/

import SpriteKit

class ParallaxSprite: SKSpriteNode {
    // MARK: Properties
    
    var usesParallaxEffect = false
    var virtualZRotation = CGFloat(0)
    var parallaxOffset = CGFloat(0)
    
    override var zRotation: CGFloat {
        get {
            return super.zRotation
        }
        
        set(rotation) {
            if !usesParallaxEffect {
                super.zRotation = rotation
            }
            
            if rotation != 0.0 {
                super.zRotation = 0.0
                
                for child in children as! [SKNode] {
                    child.zRotation = rotation
                }
                
                virtualZRotation = rotation
            }
        }
    }

    // MARK: Initializers

    convenience init () {
      self.init(texture: nil, color: SKColor.whiteColor(), size: CGSize(width: 0, height: 0))
    }

    convenience init(sprites: [SKSpriteNode], usingOffset offset: CGFloat) {
        self.init(texture: nil, color: SKColor.whiteColor(), size: CGSize(width: 0, height: 0))

        usesParallaxEffect = true

        let zOffset = 1.0 / CGFloat(sprites.count)

        let ourZPosition = zPosition
        for (childNumber, node) in enumerate(sprites) {
            node.zPosition = ourZPosition + (zOffset + (zOffset * CGFloat(childNumber)))
            addChild(node)
        }

        parallaxOffset = offset
    }
    
    // MARK: NSCopying

    override func copyWithZone(zone: NSZone) -> AnyObject {
        let sprite = super.copyWithZone(zone) as! ParallaxSprite

        sprite.parallaxOffset = parallaxOffset
        sprite.usesParallaxEffect = usesParallaxEffect

        return sprite
    }
    
    // MARK: Scene Processing Support

    func updateOffset() {
        if !usesParallaxEffect || parent == nil {
            return
        }

        let scenePos = scene!.convertPoint(position, fromNode: parent!)

        let offsetX = -1.0 + (2.0 * (scenePos.x / scene!.size.width))
        let offsetY = -1.0 + (2.0 * (scenePos.y / scene!.size.height))

        let delta = parallaxOffset / CGFloat(children.count)

        for (childNumber, child) in enumerate(children as! [SKNode]) {
            child.position = CGPoint(x: offsetX * delta * CGFloat(childNumber), y: offsetY * delta * CGFloat(childNumber))
        }

    }
}

/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines iOS-specific extensions for the layered character scene
      
*/

import SpriteKit

extension LayeredCharacterScene {
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if heroes.count < 1 || touches.count <= 0 {
            return
        }

        if defaultPlayer.movementTouch {
            return
        }

        var touch = touches.anyObject() as UITouch

        defaultPlayer.targetLocation = touch.locationInNode(defaultPlayer.hero!.parent)

        var wantsAttack = false
        var nodes = self.nodesAtPoint(touch.locationInNode(self))

        let targetCategoryBitmask = ColliderType.GoblinOrBoss.toRaw() | ColliderType.Cave.toRaw()

        for node in nodes as SKNode[] {
            // There are multiple values for ColliderType. Need to check if we want to attack.
            if let body = node.physicsBody {
                if body.categoryBitMask & targetCategoryBitmask > 0 {
                    wantsAttack = true
                }
            }
        }

        defaultPlayer.fireAction = wantsAttack
        defaultPlayer.moveRequested = !wantsAttack
        defaultPlayer.movementTouch = touch
    }

    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if heroes.count < 1 || touches.count <= 0 {
            return
        }

        if let touch: UITouch = defaultPlayer.movementTouch {
            if touches.containsObject(touch) {
                defaultPlayer.targetLocation = touch.locationInNode(defaultPlayer.hero!.parent)

                if !defaultPlayer.fireAction {
                    defaultPlayer.moveRequested = true
                }
            }
        }
    }

    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if heroes.count < 1 || touches.count <= 0 {
            return
        }
        
        if let touch = defaultPlayer.movementTouch {
            if touches.containsObject(touch) {
                defaultPlayer.movementTouch = .None
                defaultPlayer.fireAction = false
            }
        }
    }
}

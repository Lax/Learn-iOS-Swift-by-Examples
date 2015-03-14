/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines iOS-specific extensions for the layered character scene.
*/

import SpriteKit

extension AdventureScene {
    // MARK: Touch Handling
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // If we have no hero, we don't need to update the user interface at all.
        if heroes.isEmpty || touches.count <= 0 {
            return
        }

        // If a touch has already been processed on the default player (i.e. the only player),
        // don't process another one until the next event loop.
        if defaultPlayer.movementTouch != nil {
            return
        }

        let touch = touches.first as! UITouch

        defaultPlayer.targetLocation = touch.locationInNode(defaultPlayer.hero!.parent)

        let nodes = nodesAtPoint(touch.locationInNode(self)) as! [SKNode]

        let enemyBitmask = ColliderType.GoblinOrBoss.rawValue | ColliderType.Cave.rawValue

        var heroWantsToAttack = false

        for node in nodes {
            // There are multiple values for `ColliderType`. We need to check if we should attack.
            if let body = node.physicsBody {
                if body.categoryBitMask & enemyBitmask > 0 {
                    heroWantsToAttack = true
                }
            }
        }

        defaultPlayer.fireAction = heroWantsToAttack
        defaultPlayer.moveRequested = !heroWantsToAttack
        defaultPlayer.movementTouch = touch
    }

    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        // If we have no hero, we don't need to update the user interface at all.
        if heroes.isEmpty || touches.count <= 0 {
            return
        }

        // If a touch has been previously recorded, move the player in the direction of the previous
        // touch.
        if let touch = defaultPlayer.movementTouch {
            if touches.contains(touch) {
                defaultPlayer.targetLocation = touch.locationInNode(defaultPlayer.hero!.parent)

                if !defaultPlayer.fireAction {
                    defaultPlayer.moveRequested = true
                }
            }
        }
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        // If we have no hero, we don't need to update the user interface at all.
        if heroes.isEmpty || touches.count <= 0 {
            return
        }

        // If there was a touch being tracked, stop tracking it. Don't move the player anywhere.
        if let touch = defaultPlayer.movementTouch {
            if touches.contains(touch) {
                defaultPlayer.movementTouch = nil
                defaultPlayer.fireAction = false
            }
        }
    }
}

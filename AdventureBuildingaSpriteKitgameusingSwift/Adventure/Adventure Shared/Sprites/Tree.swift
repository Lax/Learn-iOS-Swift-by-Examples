/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the Tree sprite
      
*/

import SpriteKit

class Tree: ParallaxSprite {
    var fadeAlpha = false

    override func copyWithZone(zone: NSZone) -> AnyObject {
        var tree = super.copyWithZone(zone) as Tree
        tree.fadeAlpha = fadeAlpha
        return tree
    }

    func updateAlphaWithScene(scene: LayeredCharacterScene) {
        if !fadeAlpha {
            return
        }

        let distance = position.distanceTo(scene.defaultPlayer.hero!.position)
        alpha = alphaForDistance(distance)
    }

    func alphaForDistance(distance: CGFloat) -> CGFloat {
        let opaqueDistance: CGFloat = 400.0

        if distance > opaqueDistance {
            return 1.0
        } else {
            var multiplier = distance / opaqueDistance
            return 0.1 + multiplier * multiplier * 0.9
        }
    }
}

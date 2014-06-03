/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for enemy characters
      
*/

import SpriteKit

class EnemyCharacter: Character {
    // Subclasses always set the intelligence in their initializers.
    var intelligence: ArtificialIntelligence! = nil

    override func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        super.updateWithTimeSinceLastUpdate(interval)

        intelligence.updateWithTimeSinceLastUpdate(interval)
    }

    override func animationDidComplete(animationState: AnimationState) {
        if animationState == AnimationState.Attack {
            intelligence.target?.collidedWith(physicsBody)
        }
    }
}

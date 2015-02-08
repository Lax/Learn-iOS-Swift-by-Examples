/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the class for enemy characters
*/

import SpriteKit

class EnemyCharacter: Character {
    // MARK: Properties
    
    // Subclasses always set the intelligence in their initializers.
    var intelligence: ArtificialIntelligence!
    
    class var deathSplort: SKSpriteNode {
        get {
            return SharedSprites.sprites[characterType]?[SharedSprites.Keys.deathSplort] ?? SKSpriteNode()
        }
        set {
            var spritesForCharacterType = SharedSprites.sprites[characterType] ?? [String: SKSpriteNode]()
            spritesForCharacterType[SharedSprites.Keys.deathSplort] = newValue
            SharedSprites.sprites[characterType] = spritesForCharacterType
        }
    }
    
    // MARK: Scene Processing Support

    override func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        super.updateWithTimeSinceLastUpdate(interval)

        intelligence.updateWithTimeSinceLastUpdate(interval)
    }

    override func animationDidComplete(animationState: AnimationState) {
        if animationState == AnimationState.Attack {
            intelligence.target?.collidedWith(physicsBody!)
        }
    }
}

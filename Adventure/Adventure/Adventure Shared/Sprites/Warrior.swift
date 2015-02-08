/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the warrior hero class.
*/

import SpriteKit

final class Warrior: HeroCharacter, SharedAssetProvider {
    // MARK: Initializers

    convenience init(atPosition position: CGPoint, withPlayer player: Player) {
        let atlas = SKTextureAtlas(named: "Warrior_Idle")
        let texture = atlas.textureNamed("warrior_idle_0001.png")

        self.init(atPosition:position, withTexture: texture, player:player)
    }

    // MARK: Asset Pre-loading
    
    class func loadSharedAssets() {
        let atlas = SKTextureAtlas(named: "Environment")

        idleAnimationFrames = loadFramesFromAtlasWithName("Warrior_Idle")
        walkAnimationFrames = loadFramesFromAtlasWithName("Warrior_Walk")
        attackAnimationFrames = loadFramesFromAtlasWithName("Warrior_Attack")
        getHitAnimationFrames = loadFramesFromAtlasWithName("Warrior_GetHit")
        deathAnimationFrames = loadFramesFromAtlasWithName("Warrior_Death")

        var warriorProjectile = SKSpriteNode(texture: atlas.textureNamed("warrior_throw_hammer.png"))
        warriorProjectile.name = "Projectile"
        
        // Assign the physics body; unwrap the physics body to configure it.
        warriorProjectile.physicsBody = SKPhysicsBody(circleOfRadius: HeroCharacter.Constants.projectileCollisionRadius)
        warriorProjectile.physicsBody!.categoryBitMask = ColliderType.Projectile.rawValue
        warriorProjectile.physicsBody!.collisionBitMask = ColliderType.Wall.rawValue
        warriorProjectile.physicsBody!.contactTestBitMask = warriorProjectile.physicsBody!.collisionBitMask
        
        projectile = warriorProjectile

        projectileEmitter = SKEmitterNode(fileNamed: "WarriorProjectile")
    }
}

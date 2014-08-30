/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for the archer hero character
      
*/

import SpriteKit

let kArcherAttackFrames = 10
let kArcherGetHitFrames = 18
let kArcherDeathFrames = 42
let kArcherProjectileSpeed = 8.0

var sSharedArcherProjectile = SKSpriteNode()
var sSharedArcherProjectileEmitter = SKEmitterNode()
var sSharedArcherIdleAnimationFrames = SKTexture[]()
var sSharedArcherWalkAnimationFrames = SKTexture[]()
var sSharedArcherAttackAnimationFrames = SKTexture[]()
var sSharedArcherGetHitAnimationFrames = SKTexture[]()
var sSharedArcherDeathAnimationFrames = SKTexture[]()
var sSharedArcherDamageAction = SKAction()

var kLoadSharedArcherAssetsOnceToken: dispatch_once_t = 0

class Archer: HeroCharacter {

	  // Initialization.
    convenience init(atPosition: CGPoint, withPlayer: Player) {
        let atlas = SKTextureAtlas(named: "Archer_Idle")
        let texture = atlas.textureNamed("archer_idle_0001.png")

        self.init(atPosition: atPosition, withTexture: texture, player: withPlayer)
  	}

    // Shared Assets.
    class func loadSharedAssets() {
        dispatch_once(&kLoadSharedArcherAssetsOnceToken) {
            sSharedArcherProjectile = SKSpriteNode(color: SKColor.whiteColor(), size: CGSize(width: 2.0, height: 24.0))
            sSharedArcherProjectile.name = "Projectile"
            sSharedArcherProjectile.physicsBody = SKPhysicsBody(circleOfRadius: kProjectileCollisionRadius)
            sSharedArcherProjectile.physicsBody.categoryBitMask = ColliderType.Projectile.toRaw()
            sSharedArcherProjectile.physicsBody.collisionBitMask = ColliderType.Wall.toRaw()
            sSharedArcherProjectile.physicsBody.contactTestBitMask = sSharedArcherProjectile.physicsBody.collisionBitMask

            sSharedArcherProjectileEmitter = SKEmitterNode.emitterNodeWithName("ArcherProjectile")

            sSharedArcherIdleAnimationFrames = loadFramesFromAtlasWithName("Archer_Idle", baseFileName: "archer_idle_", numberOfFrames: kDefaultNumberOfIdleFrames)
            sSharedArcherWalkAnimationFrames = loadFramesFromAtlasWithName("Archer_Walk", baseFileName: "archer_walk_", numberOfFrames: kDefaultNumberOfWalkFrames)
            sSharedArcherAttackAnimationFrames = loadFramesFromAtlasWithName("Archer_Attack", baseFileName: "archer_attack_", numberOfFrames: kArcherAttackFrames)
            sSharedArcherGetHitAnimationFrames = loadFramesFromAtlasWithName("Archer_GetHit", baseFileName: "archer_getHit_", numberOfFrames: kArcherGetHitFrames)
            sSharedArcherDeathAnimationFrames = loadFramesFromAtlasWithName("Archer_Death", baseFileName: "archer_death_", numberOfFrames: kArcherDeathFrames)

            let actions = [
                SKAction.colorizeWithColor(SKColor.whiteColor(), colorBlendFactor: 10.0, duration: 0.0),
                SKAction.waitForDuration(0.75),
                SKAction.colorizeWithColorBlendFactor(0.0, duration: 0.25)
            ]

            sSharedArcherDamageAction = SKAction.sequence(actions)
        }
    }

    override func projectile() -> SKSpriteNode {
        return sSharedArcherProjectile
    }

    override func projectileEmitter() -> SKEmitterNode {
        return sSharedArcherProjectileEmitter
    }

    override func idleAnimationFrames() -> SKTexture[] {
        return sSharedArcherIdleAnimationFrames
    }

    override func walkAnimationFrames() -> SKTexture[] {
        return sSharedArcherWalkAnimationFrames
    }

    override func attackAnimationFrames() -> SKTexture[] {
        return sSharedArcherAttackAnimationFrames
    }

    override func getHitAnimationFrames() -> SKTexture[] {
        return sSharedArcherGetHitAnimationFrames
    }

    override func deathAnimationFrames() -> SKTexture[] {
        return sSharedArcherDeathAnimationFrames
    }

    override func damageAction() -> SKAction {
        return sSharedArcherDamageAction
    }
}

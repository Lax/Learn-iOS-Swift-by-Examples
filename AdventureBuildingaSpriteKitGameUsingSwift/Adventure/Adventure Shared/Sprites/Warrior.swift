/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the warrior hero class
      
*/


import SpriteKit


var sSharedWarriorIdleAnimationFrames = SKTexture[]()
var sSharedWarriorWalkAnimationFrames = SKTexture[]()
var sSharedWarriorAttackAnimationFrames = SKTexture[]()
var sSharedWarriorGetHitAnimationFrames = SKTexture[]()
var sSharedWarriorDeathAnimationFrames = SKTexture[]()
var sSharedProjectile = SKSpriteNode()
var sSharedProjectileEmitter = SKEmitterNode()
let kProjectileCollisionRadius: CGFloat = 15.0

var kLoadSharedWarriorAssetsOnceToken: dispatch_once_t = 0

class Warrior: HeroCharacter {
    init(atPosition position: CGPoint, withPlayer player: Player) {
        let atlas = SKTextureAtlas(named: "Warrior_Idle")
        let texture = atlas.textureNamed("warrior_idle_0001.png")

        super.init(atPosition:position, withTexture: texture, player:player)
    }

    class func loadSharedAssets() {
        dispatch_once(&kLoadSharedWarriorAssetsOnceToken) {
            let atlas = SKTextureAtlas(named: "Environment")

            sSharedWarriorIdleAnimationFrames = loadFramesFromAtlasWithName("Warrior_Idle", baseFileName: "warrior_idle_", numberOfFrames: 29)
            sSharedWarriorWalkAnimationFrames = loadFramesFromAtlasWithName("Warrior_Walk", baseFileName: "warrior_walk_", numberOfFrames: 28)
            sSharedWarriorAttackAnimationFrames = loadFramesFromAtlasWithName("Warrior_Attack", baseFileName: "warrior_attack_", numberOfFrames: 10)
            sSharedWarriorGetHitAnimationFrames = loadFramesFromAtlasWithName("Warrior_GetHit", baseFileName: "warrior_getHit_", numberOfFrames: 20)
            sSharedWarriorDeathAnimationFrames = loadFramesFromAtlasWithName("Warrior_Death", baseFileName: "warrior_death_", numberOfFrames: 90)

            sSharedProjectile = SKSpriteNode(texture: atlas.textureNamed("warrior_throw_hammer.png"))
            sSharedProjectile.physicsBody = SKPhysicsBody(circleOfRadius: kProjectileCollisionRadius)
            sSharedProjectile.name = "Projectile"
            sSharedProjectile.physicsBody.categoryBitMask = ColliderType.Projectile.toRaw()
            sSharedProjectile.physicsBody.collisionBitMask = ColliderType.Wall.toRaw()
            sSharedProjectile.physicsBody.contactTestBitMask = ColliderType.Wall.toRaw()

            sSharedProjectileEmitter = NSKeyedUnarchiver.unarchiveObjectWithFile(NSBundle.mainBundle().pathForResource("WarriorProjectile", ofType: "sks")) as SKEmitterNode
        }
    }

    override func idleAnimationFrames() -> SKTexture[] {
        return sSharedWarriorIdleAnimationFrames
    }

    override func walkAnimationFrames() -> SKTexture[] {
        return sSharedWarriorWalkAnimationFrames
    }

    override func attackAnimationFrames() -> SKTexture[] {
        return sSharedWarriorAttackAnimationFrames
    }

    override func getHitAnimationFrames() -> SKTexture[] {
        return sSharedWarriorGetHitAnimationFrames
    }

    override func deathAnimationFrames() -> SKTexture[] {
        return sSharedWarriorDeathAnimationFrames
    }

    override func projectile() -> SKSpriteNode {
        return sSharedProjectile
    }

    override func projectileEmitter() -> SKEmitterNode {
        return sSharedProjectileEmitter
    }
}


func loadFramesFromAtlas(atlas: SKTextureAtlas) -> SKTexture[] {
    return (atlas.textureNames as String[]).map { atlas.textureNamed($0) }
}

func loadFramesFromAtlasWithName(atlasName: String, #baseFileName: String, #numberOfFrames: Int) -> SKTexture[] {
    let atlas = SKTextureAtlas(named: atlasName)
    return SKTexture[](map(1...numberOfFrames) { i in
        let extraZero = (i < 10) ? "0" : ""
        let fileName = "\(baseFileName)00\(extraZero)\(i).png"
        return atlas.textureNamed(fileName)
    })
}

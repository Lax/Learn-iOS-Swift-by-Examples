/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for goblin enemies
      
*/


import SpriteKit

let kMinimumGoblinSize: CGFloat = 0.5
let kGoblinSizeVariance: CGFloat = 0.350
let kGoblinCollisionRadius: CGFloat = 40.0

let kGoblinAttackFrames = 33
let kGoblinDeathFrames = 31
let kGoblinGetHitFrames = 25

let kDefaultNumberOfIdleFrames = 28
let kDefaultNumberOfWalkFrames = 28

var sSharedGetHitAnimationFrames = SKTexture[]()
var sSharedDeathAnimationFrames = SKTexture[]()

var kLoadSharedGoblinAssetsOnceToken : dispatch_once_t = 0

class Goblin: EnemyCharacter, Equatable {
	var cave: Cave? = .None

  init(atPosition position: CGPoint) {
        let atlas = SKTextureAtlas(named: "Goblin_Idle")
		let atlasTexture = atlas.textureNamed("goblin_idle_0001.png")

        super.init(texture: atlasTexture, atPosition: position)

		movementSpeed *= unitRandom()

		self.setScale(kMinimumGoblinSize + (unitRandom() * kGoblinSizeVariance))
		name = "Enemy"

		intelligence = ChaseAI(character: self, target: nil)
	}

    // Overridden methods
    override func configurePhysicsBody() {
        physicsBody = SKPhysicsBody(circleOfRadius: kGoblinCollisionRadius)

        physicsBody.categoryBitMask = ColliderType.GoblinOrBoss.toRaw()

        physicsBody.collisionBitMask = ColliderType.GoblinOrBoss.toRaw() | ColliderType.Hero.toRaw() | ColliderType.Projectile.toRaw() | ColliderType.Wall.toRaw() | ColliderType.Cave.toRaw()

        physicsBody.contactTestBitMask = ColliderType.Projectile.toRaw()
    }

    override func reset() {
        super.reset()

        alpha = 1
        removeAllChildren()
        configurePhysicsBody()
    }

    override func animationDidComplete(animationState: AnimationState) {
        super.animationDidComplete(animationState)

        if animationState == AnimationState.Death {
            removeAllActions()

            let actions = [
                SKAction.waitForDuration(0.75),
                SKAction.fadeOutWithDuration(1.0),
                SKAction.runBlock {
                    self.removeFromParent()
                    self.cave?.recycle(self)
                }
            ]

            var actionSequence = SKAction.sequence(actions)
            runAction(actionSequence)
        }
    }

    override func collidedWith(otherBody: SKPhysicsBody) {
        if dying  {
            return
        }

        if otherBody.categoryBitMask & ColliderType.Projectile.toRaw() == ColliderType.Projectile.toRaw() {
            // Apply random damage of either 100% or 50%

            requestedAnimation = .GetHit
            var damage = 100.0
            if arc4random_uniform(2) == 0 {
                damage = 50.0
            }

            var killed = applyDamage(damage, projectile: otherBody.node)
            if killed {
                characterScene.addToScore(10, afterEnemyKillWithProjectile: otherBody.node as SKNode)
            }
        }
    }

    override func performDeath() {
        removeAllActions()

        var splort = deathSplort().copy() as SKSpriteNode
        splort.zPosition = -1.0
        splort.zRotation = unitRandom() * CGFloat(M_PI)
        splort.position = position
        splort.alpha = 0.5
        characterScene.addNode(splort, atWorldLayer: .Ground)
        splort.runAction(SKAction.fadeOutWithDuration(10.0))

        super.performDeath()

        physicsBody.collisionBitMask = 0
        physicsBody.contactTestBitMask = 0
        physicsBody.categoryBitMask = 0
        physicsBody = nil
    }

    class func loadSharedAssets() {
        dispatch_once(&kLoadSharedGoblinAssetsOnceToken) {
            let atlas = SKTextureAtlas(named: "Environment")

            sSharedGoblinIdleAnimationFrames = loadFramesFromAtlasWithName("Goblin_Idle", baseFileName: "goblin_idle_", numberOfFrames: kDefaultNumberOfIdleFrames)

            sSharedGoblinWalkAnimationFrames = loadFramesFromAtlasWithName("Goblin_Walk", baseFileName: "goblin_walk_", numberOfFrames: kDefaultNumberOfWalkFrames)

            sSharedGoblinAttackAnimationFrames = loadFramesFromAtlasWithName("Goblin_Attack", baseFileName: "goblin_attack_", numberOfFrames: kGoblinAttackFrames)

            sSharedGoblinGetHitAnimationFrames = loadFramesFromAtlasWithName("Goblin_GetHit", baseFileName: "goblin_getHit_", numberOfFrames: kGoblinGetHitFrames)

            sSharedGoblinDeathAnimationFrames = loadFramesFromAtlasWithName("Goblin_Death", baseFileName: "goblin_death_", numberOfFrames: kGoblinDeathFrames)

            sSharedGoblinDamageEmitter = SKEmitterNode.emitterNodeWithName("Damage")

            sSharedGoblinDeathSplort = SKSpriteNode(texture: atlas.textureNamed("minionSplort.png"))

            let actions = [
                SKAction.colorizeWithColor(SKColor.whiteColor(), colorBlendFactor: 1.0, duration: 0.0),
                SKAction.waitForDuration(0.75),
                SKAction.colorizeWithColorBlendFactor(0.0, duration: 0.1)
            ]

            sSharedGoblinDamageAction = SKAction.sequence(actions)
        }
    }

    override func damageEmitter() -> SKEmitterNode {
        return sSharedGoblinDamageEmitter
    }

    override func damageAction() -> SKAction {
        return sSharedGoblinDamageAction
    }

    override func idleAnimationFrames() -> SKTexture[] {
        return sSharedGoblinIdleAnimationFrames
    }

    override func walkAnimationFrames() -> SKTexture[] {
        return sSharedGoblinWalkAnimationFrames
    }

    override func attackAnimationFrames() -> SKTexture[] {
        return sSharedGoblinAttackAnimationFrames
    }

    override func getHitAnimationFrames() -> SKTexture[] {
        return sSharedGoblinGetHitAnimationFrames
    }

    override func deathAnimationFrames() -> SKTexture[] {
        return sSharedGoblinDeathAnimationFrames
    }

    func deathSplort() -> SKSpriteNode {
        return sSharedGoblinDeathSplort
    }
}

func ==(x: Goblin, y: Goblin) -> Bool {
  return (x as NSObject) == (y as NSObject)
}

var sSharedGoblinBase = SKSpriteNode()
var sSharedGoblinTop = SKSpriteNode()
var sSharedGoblinDeathSplort = SKSpriteNode()
var sSharedGoblinDamageEmitter = SKEmitterNode()
var sSharedGoblinDeathEmitter = SKEmitterNode()
var sSharedGoblinDamageAction = SKAction()
var sSharedGoblinIdleAnimationFrames = SKTexture[]()
var sSharedGoblinWalkAnimationFrames = SKTexture[]()
var sSharedGoblinAttackAnimationFrames = SKTexture[]()
var sSharedGoblinGetHitAnimationFrames = SKTexture[]()
var sSharedGoblinDeathAnimationFrames = SKTexture[]()

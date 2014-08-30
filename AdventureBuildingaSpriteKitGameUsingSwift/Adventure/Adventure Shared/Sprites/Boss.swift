/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for the boss enemy character
      
*/

import SpriteKit

let kBossWalkFrames = 35
let kBossIdleFrames = 32
let kBossAttackFrames = 42
let kBossDeathFrames = 45
let kBossGetHitFrames = 22

let kBossCollisionRadius: CGFloat = 40.0
let kBossChaseRadius: CGFloat = kBossCollisionRadius * 4.0

var kLoadSharedBossAssetsOnceToken: dispatch_once_t = 0

var sSharedBossIdleAnimationFrames = SKTexture[]()
var sSharedBossWalkAnimationFrames = SKTexture[]()
var sSharedBossAttackAnimationFrames = SKTexture[]()
var sSharedBossGetHitAnimationFrames = SKTexture[]()
var sSharedBossDeathAnimationFrames = SKTexture[]()
var sSharedBossDamageEmitter = SKEmitterNode()
var sSharedBossDamageAction = SKAction()

class Boss: EnemyCharacter {
    // Initialization
    init(atPosition position: CGPoint) {
        let atlas = SKTextureAtlas(named: "Boss_Idle")
        let bossTexture = atlas.textureNamed("boss_idle_0001.png")
        super.init(texture: bossTexture, atPosition: position)

        movementSpeed = movementSpeed * 0.35
        animationSpeed = 1.0/35.0

        zPosition = -0.25
        name = "Boss"

        attacking = false

        let chaseIntelligence = ChaseAI(character: self, target: nil)
        chaseIntelligence.chaseRadius = kBossChaseRadius
        chaseIntelligence.maxAlertRadius = kBossChaseRadius * 4.0
            intelligence = chaseIntelligence
    }

	// Overidden Methods
	override func configurePhysicsBody() {
        physicsBody = SKPhysicsBody(circleOfRadius: kBossCollisionRadius)

	    // Our object type for collisions.
		physicsBody.categoryBitMask = ColliderType.GoblinOrBoss.toRaw()

	    // Collides with these objects.
		physicsBody.collisionBitMask = ColliderType.GoblinOrBoss.toRaw() | ColliderType.Hero.toRaw() | ColliderType.Projectile.toRaw() | ColliderType.Wall.toRaw()

	    // We want notifications for colliding with these objects.
	    physicsBody.contactTestBitMask = ColliderType.Projectile.toRaw()
	}

  override
	func animationDidComplete(animationState: AnimationState) {
		super.animationDidComplete(animationState)

		if animationState == AnimationState.Death {
			removeAllActions()
			let actions = [
				SKAction.waitForDuration(3.0),
				SKAction.fadeOutWithDuration(2.0),
				SKAction.removeFromParent()
				/*,
				SKAction.runBlock {
					characterScene.gameOver()
				}
				*/
			]

			runAction(SKAction.sequence(actions))
		}
	}

	override func collidedWith(other: SKPhysicsBody) {
		if dying {
			return
		}

		if (other.categoryBitMask & ColliderType.Projectile.toRaw()) == ColliderType.Projectile.toRaw() {
			requestedAnimation = AnimationState.GetHit
            let damage = 2.0
            let killed = applyDamage(damage, projectile: other.node)

			if killed {
                // Give the player some points
			}
		}
	}

	override func performDeath() {
		removeAllActions()
		super.performDeath()
	}

	// Shared Assets.
	class func loadSharedAssets() {
        dispatch_once(&kLoadSharedBossAssetsOnceToken) {
            sSharedBossIdleAnimationFrames = loadFramesFromAtlasWithName("Boss_Idle", baseFileName: "boss_idle_", numberOfFrames: kBossIdleFrames)

            sSharedBossWalkAnimationFrames = loadFramesFromAtlasWithName("Boss_Walk", baseFileName: "boss_walk_", numberOfFrames: kBossWalkFrames)

            sSharedBossAttackAnimationFrames = loadFramesFromAtlasWithName("Boss_Attack", baseFileName: "boss_attack_", numberOfFrames: kBossAttackFrames)

            sSharedBossGetHitAnimationFrames = loadFramesFromAtlasWithName("Boss_GetHit", baseFileName: "boss_getHit_", numberOfFrames: kBossGetHitFrames)

            sSharedBossDeathAnimationFrames = loadFramesFromAtlasWithName("Boss_Death", baseFileName: "boss_death_", numberOfFrames: kBossDeathFrames)

            sSharedBossDamageEmitter = SKEmitterNode.emitterNodeWithName("BossDamage")

            let actions = [
                SKAction.colorizeWithColor(SKColor.whiteColor(), colorBlendFactor: 1.0, duration: 0.0),
                SKAction.waitForDuration(0.5),
                SKAction.colorizeWithColorBlendFactor(0.0, duration: 0.1)
            ]

            sSharedBossDamageAction = SKAction.sequence(actions)
        }
	}

    override func damageEmitter() -> SKEmitterNode {
        return sSharedBossDamageEmitter
    }

    override func damageAction() -> SKAction {
        return sSharedBossDamageAction
    }

    override func idleAnimationFrames() -> SKTexture[] {
        return sSharedBossIdleAnimationFrames
    }

    override func walkAnimationFrames() -> SKTexture[] {
        return sSharedBossWalkAnimationFrames
    }

    override func attackAnimationFrames() -> SKTexture[] {
        return sSharedBossAttackAnimationFrames
    }

    override func getHitAnimationFrames() -> SKTexture[] {
        return sSharedBossGetHitAnimationFrames
    }

    override func deathAnimationFrames() -> SKTexture[] {
        return sSharedBossDeathAnimationFrames
    }
}

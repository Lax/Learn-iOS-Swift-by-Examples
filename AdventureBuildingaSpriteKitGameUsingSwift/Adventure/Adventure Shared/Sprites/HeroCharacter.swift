/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the common class for hero characters
      
*/

import SpriteKit

let kCharacterCollisionRadius: CGFloat = 40.0
let kHeroProjectileSpeed: CGFloat = 480.0
let kHeroProjectileLifetime: NSTimeInterval = 1.0
let kHeroProjectileFadeOutTime: NSTimeInterval = 0.6

class HeroCharacter: Character {
    var player: Player

    init(atPosition position: CGPoint, withTexture texture: SKTexture? = nil, player: Player) {
        self.player = player
        super.init(texture: texture, atPosition: position)

        zRotation = CGFloat(M_PI)
        zPosition = -0.25
        name = "Hero"
    }

    override func configurePhysicsBody() {
        physicsBody = SKPhysicsBody(circleOfRadius: kCharacterCollisionRadius)
        physicsBody.categoryBitMask = ColliderType.Hero.toRaw()
        physicsBody.collisionBitMask = ColliderType.GoblinOrBoss.toRaw() | ColliderType.Hero.toRaw() | ColliderType.Wall.toRaw() | ColliderType.Cave.toRaw()
        physicsBody.contactTestBitMask = ColliderType.GoblinOrBoss.toRaw()
    }

    override func collidedWith(other: SKPhysicsBody) {
        if other.categoryBitMask & ColliderType.GoblinOrBoss.toRaw() == 0 {
            return
        }

        if let enemy = other.node as? Character {
            if !enemy.dying {
                applyDamage(5.0)
                requestedAnimation = .GetHit
            }
        }
    }

    override func animationDidComplete(animation: AnimationState) {
        super.animationDidComplete(animation)

        switch animation {
            case .Death:
                let actions = [SKAction.waitForDuration(4.0),
                               SKAction.runBlock {
                                   self.characterScene.heroWasKilled(self)
                               },
                               SKAction.removeFromParent()]
                runAction(SKAction.sequence(actions))

            case .Attack:
                fireProjectile()

           default:
                () // Do nothing
        }
    }

// PROJECTILES
    func fireProjectile() {
        let projectile = self.projectile()!.copy() as SKSpriteNode
        projectile.position = position
        projectile.zRotation = zRotation

        let emitter = projectileEmitter()!.copy() as SKEmitterNode
        emitter.targetNode = scene.childNodeWithName("world")
        projectile.addChild(emitter)

        characterScene.addNode(projectile, atWorldLayer: .Character)
        let rot = zRotation

        let x = -sin(rot) * kHeroProjectileSpeed * CGFloat(kHeroProjectileLifetime)
        let y =  cos(rot) * kHeroProjectileSpeed * CGFloat(kHeroProjectileLifetime)
        projectile.runAction(SKAction.moveByX(x, y: y, duration: kHeroProjectileLifetime))

        let waitAction = SKAction.waitForDuration(kHeroProjectileFadeOutTime)
        let fadeAction = SKAction.fadeOutWithDuration(kHeroProjectileLifetime - kHeroProjectileFadeOutTime)
        let removeAction = SKAction.removeFromParent()
        let sequence = [waitAction, fadeAction, removeAction]

        projectile.runAction(SKAction.sequence(sequence))
        projectile.runAction(projectileSoundAction())

        let data: NSMutableDictionary = ["kPlayer" : self.player]
        projectile.userData = data
    }

    func projectile() -> SKSpriteNode? {
        return nil
    }

    func projectileEmitter() -> SKEmitterNode? {
        return nil
    }

    func projectileSoundAction() -> SKAction {
        return sSharedProjectileSoundAction
    }

    class func loadSharedHeroAssets() {
        sSharedProjectileSoundAction = SKAction.playSoundFileNamed("magicmissile.caf", waitForCompletion: false)
    }
}

var sSharedProjectileSoundAction = SKAction()

let kPlayer = "kPlayer"

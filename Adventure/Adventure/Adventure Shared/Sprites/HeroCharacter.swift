/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the common class for hero characters.
*/

import SpriteKit

class HeroCharacter: Character {
    // MARK: Types
    
    struct Constants {
        static let projectileCollisionRadius: CGFloat = 15.0
        static let projectileSpeed: CGFloat = 480.0
        static let projectileLifetime: NSTimeInterval = 1.0
        static let projectileFadeOutDuration: NSTimeInterval = 0.6
    }
    
    // MARK: Properties
    
    var player: Player!
    
    var projectileSoundAction = SKAction.playSoundFileNamed("magicmissile.caf", waitForCompletion: false)

    // MARK: Initializers

    convenience init(atPosition position: CGPoint, withTexture texture: SKTexture? = nil, player: Player) {
        self.init(texture: texture, atPosition: position)
        self.player = player
        
        zRotation = CGFloat(M_PI)
        zPosition = -0.25
        name = "Hero"
    }
    
    // MARK: Setup

    override func configurePhysicsBody() {
        // Assign the physics body; unwrap the physics body to configure it.
        physicsBody = SKPhysicsBody(circleOfRadius: collisionRadius)
        physicsBody!.categoryBitMask = ColliderType.Hero.rawValue
        physicsBody!.collisionBitMask = ColliderType.allButProjectile
        physicsBody!.contactTestBitMask = ColliderType.GoblinOrBoss.rawValue
    }

    // MARK: Scene Processing Support

    override func animationDidComplete(animation: AnimationState) {
        super.animationDidComplete(animation)

        switch animation {
            case .Death:
                let actions = [
                    SKAction.waitForDuration(4.0),
                    SKAction.runBlock {
                        self.characterScene.heroWasKilled(self)
                    },
                    SKAction.removeFromParent()
                ]
                runAction(SKAction.sequence(actions))

            case .Attack:
                fireProjectile()

           default:
                () // Do nothing
        }
    }

    override func collidedWith(other: SKPhysicsBody) {
        if other.categoryBitMask & ColliderType.GoblinOrBoss.rawValue == 0 {
            return
        }

        if let enemy = other.node as? Character {
            if !enemy.isDying {
                applyDamage(5.0)
                requestedAnimation = .GetHit
            }
        }
    }

    func fireProjectile() {
        let projectile = self.dynamicType.projectile.copy() as! SKSpriteNode
        projectile.position = position
        projectile.zRotation = zRotation

        let emitter = self.dynamicType.projectileEmitter.copy() as! SKEmitterNode
        emitter.targetNode = scene!.childNodeWithName("world")
        projectile.addChild(emitter)

        characterScene.addNode(projectile, atWorldLayer: .Character)
        let rot = zRotation

        let x = -sin(rot) * Constants.projectileSpeed * CGFloat(Constants.projectileLifetime)
        let y =  cos(rot) * Constants.projectileSpeed * CGFloat(Constants.projectileLifetime)
        projectile.runAction(SKAction.moveByX(x, y: y, duration: Constants.projectileLifetime))

        let waitAction = SKAction.waitForDuration(Constants.projectileFadeOutDuration)
        let fadeAction = SKAction.fadeOutWithDuration(Constants.projectileLifetime - Constants.projectileFadeOutDuration)
        let removeAction = SKAction.removeFromParent()
        let sequence = [waitAction, fadeAction, removeAction]

        projectile.runAction(SKAction.sequence(sequence))
        projectile.runAction(projectileSoundAction)

        projectile.userData = [Player.Keys.projectileUserDataPlayer: player]
    }
}

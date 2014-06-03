/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for a character in Adventure
      
*/

import SpriteKit

enum AnimationState: UInt32 {
    case Idle = 0, Walk, Attack, GetHit, Death
}

enum MoveDirection {
    case Forward, Left, Right, Back
}

enum ColliderType: UInt32 {
    case Hero = 1
    case GoblinOrBoss = 2
    case Projectile = 4
    case Wall = 8
    case Cave = 16
}

class Character: ParallaxSprite {
    var dying = false
    var attacking = false
    var health = 100.0
    var animated = true
    var animationSpeed: CGFloat = 1.0/28.0
    var movementSpeed: CGFloat = 200.0
    var rotationSpeed: CGFloat = 0.06
    var requestedAnimation = AnimationState.Idle
    
    var characterScene: LayeredCharacterScene {
        return self.scene as LayeredCharacterScene
    }


    var shadowBlob = SKSpriteNode()

    func idleAnimationFrames() -> SKTexture[] {
        return []
    }

    func walkAnimationFrames() -> SKTexture[] {
        return []
    }

    func attackAnimationFrames() -> SKTexture[] {
        return []
    }

    func getHitAnimationFrames() -> SKTexture[] {
        return []
    }

    func deathAnimationFrames() -> SKTexture[] {
        return []
    }

    func damageEmitter() -> SKEmitterNode {
        return SKEmitterNode()
    }

    func damageAction() -> SKAction {
        return SKAction()
    }

    init(sprites: SKSpriteNode[], atPosition position: CGPoint, usingOffset offset: CGFloat) {
        super.init(sprites: sprites, usingOffset: offset)

        sharedInitAtPosition(position)
    }

    init(texture: SKTexture?, atPosition position: CGPoint) {
        let size = texture ? texture!.size() : CGSize(width: 0, height: 0)
        super.init(texture: texture, color: SKColor.whiteColor(), size: size)

        sharedInitAtPosition(position)
    }

    func sharedInitAtPosition(position: CGPoint) {
        let atlas = SKTextureAtlas(named: "Environment")

        shadowBlob = SKSpriteNode(texture: atlas.textureNamed("blobShadow.png"))
        shadowBlob.zPosition = -1.0

        self.position = position

        configurePhysicsBody()
    }

    func reset() {
        health = 100.0
        dying = false
        attacking = false
        animated = true
        requestedAnimation = .Idle
        shadowBlob.alpha = 1.0
    }

// OVERRIDDEN METHODS
    func performAttackAction() {
        if attacking {
            return
        }

        attacking = true
        requestedAnimation = .Attack
    }

    func performDeath() {
        health = 0.0
        dying = true
        requestedAnimation = .Death
    }

    func configurePhysicsBody() {
    }

    func animationDidComplete(animation: AnimationState) {
    }

    func collidedWith(other: SKPhysicsBody) {
    }

// DAMAGE
    func applyDamage(var damage: Double, projectile: SKNode? = nil) -> Bool {
        if let proj = projectile {
            damage *= Double(proj.alpha)
        }

        health -= damage

        if health > 0.0 {
            let emitter = damageEmitter().copy() as SKEmitterNode
            characterScene.addNode(emitter, atWorldLayer: .AboveCharacter)

            emitter.position = position
            runOneShotEmitter(emitter, withDuration: 0.15)

            runAction(damageAction())
            return false
        }

        performDeath()
        return true
    }

// SHADOW BLOB
    override func setScale(scale: CGFloat) {
        super.setScale(scale)
        shadowBlob.setScale(scale)
    }

// LOOP UPDATE
    func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        shadowBlob.position = position

        if !animated {
            return
        }
        resolveRequestedAnimation()
    }

// ANIMATION
    func resolveRequestedAnimation() {
        var (frames, key) = animationFramesAndKeyForState(requestedAnimation)

        fireAnimationForState(requestedAnimation, usingTextures: frames, withKey: key)

        requestedAnimation = dying ? .Death : .Idle
    }

    func animationFramesAndKeyForState(state: AnimationState) -> (SKTexture[], String) {
        switch state {
            case .Walk:
               return (walkAnimationFrames(), "anim_walk")

            case .Attack:
                return (attackAnimationFrames(), "anim_attack")

            case .GetHit:
                return (getHitAnimationFrames(), "anim_gethit")

            case .Death:
                return (deathAnimationFrames(), "anim_death")

            case .Idle:
                return (idleAnimationFrames(), "anim_idle")
        }
    }

    func fireAnimationForState(animationState: AnimationState, usingTextures frames: SKTexture[], withKey key: String) {
        var animAction = actionForKey(key)

        if animAction != nil || frames.count < 1 {
            return
        }

        let animationAction = SKAction.animateWithTextures(frames, timePerFrame: NSTimeInterval(animationSpeed), resize: true, restore: false)
        let blockAction = SKAction.runBlock {
            self.animationHasCompleted(animationState)
        }

        runAction(SKAction.sequence([animationAction, blockAction]), withKey: key)
    }

    func animationHasCompleted(animationState: AnimationState) {
        if dying {
            animated = false
            shadowBlob.runAction(SKAction.fadeOutWithDuration(1.5))
        }

        animationDidComplete(animationState)

        if attacking {
            attacking = false
        }
    }

    func fadeIn(duration: NSTimeInterval) {
        let fadeAction = SKAction.fadeInWithDuration(duration)

        alpha = 0.0
        runAction(fadeAction)

        shadowBlob.alpha = 0.0
        shadowBlob.runAction(fadeAction)
    }

// WORKING WITH SCENES
    func addToScene(scene: LayeredCharacterScene) {
        scene.addNode(self, atWorldLayer: .Character)
        scene.addNode(shadowBlob, atWorldLayer: .BelowCharacter)
    }

    override func removeFromParent() {
        shadowBlob.removeFromParent()
        super.removeFromParent()
    }

// Movement
    func move(direction: MoveDirection, withTimeInterval timeInterval: NSTimeInterval) {
        var action: SKAction

        switch direction {
            case .Forward:
                let x = -sin(zRotation) * movementSpeed * CGFloat(timeInterval)
                let y =  cos(zRotation) * movementSpeed * CGFloat(timeInterval)
                action = SKAction.moveByX(x, y: y, duration: timeInterval)

            case .Back:
                let x =  sin(zRotation) * movementSpeed * CGFloat(timeInterval)
                let y = -cos(zRotation) * movementSpeed * CGFloat(timeInterval)
                action = SKAction.moveByX(x, y: y, duration: timeInterval)

            case .Left:
                action = SKAction.rotateByAngle(rotationSpeed, duration:timeInterval)

            case .Right:
                action = SKAction.rotateByAngle(-rotationSpeed, duration:timeInterval)
        }

        if action != nil {
            requestedAnimation = .Walk
            runAction(action)
        }
    }

    func faceTo(position: CGPoint) -> CGFloat {
        var angle = adjustAssetOrientation(position.radiansToPoint(self.position))
        var action = SKAction.rotateToAngle(angle, duration: 0)
        runAction(action)
        return angle
    }

    func moveTowards(targetPosition: CGPoint, withTimeInterval timeInterval: NSTimeInterval) {
        // Grab an immutable position in case Sprite Kit changes it underneath us.
        let current = position
        var deltaX = targetPosition.x - current.x
        var deltaY = targetPosition.y - current.y
        var deltaT = movementSpeed * CGFloat(timeInterval)

        var angle = adjustAssetOrientation(targetPosition.radiansToPoint(current))
        var action = SKAction.rotateToAngle(angle, duration: 0)
        runAction(action)

        var distRemaining = hypot(deltaX, deltaY)
        if distRemaining < deltaT {
            position = targetPosition
        } else {
            let x = current.x - (deltaT * sin(angle))
            let y = current.y + (deltaT * cos(angle))
            position = CGPoint(x: x, y: y)
        }
        requestedAnimation = .Walk
    }
}

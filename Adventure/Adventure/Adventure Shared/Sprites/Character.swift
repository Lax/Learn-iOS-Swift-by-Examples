/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the class for a character in Adventure.
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
    
    static var all = ColliderType.Hero.rawValue | ColliderType.GoblinOrBoss.rawValue | ColliderType.Projectile.rawValue | ColliderType.Wall.rawValue | ColliderType.Cave.rawValue

    static var allButProjectile = ColliderType.Hero.rawValue | ColliderType.GoblinOrBoss.rawValue | ColliderType.Wall.rawValue | ColliderType.Cave.rawValue
}

class Character: ParallaxSprite {
    // MARK: Properties
    
    var isDying = false
    var isAttacking = false
    var health = 100.0
    var animated = true
    var animationSpeed: CGFloat = 1.0/28.0
    var movementSpeed: CGFloat = 200.0
    var rotationSpeed: CGFloat = 0.06
    var requestedAnimation = AnimationState.Idle
    var shadowBlob = SKSpriteNode()
    
    var collisionRadius: CGFloat {
        return 40.0
    }
    
    var characterScene: AdventureScene {
        return self.scene as! AdventureScene
    }
    
    class var characterType: CharacterType {
        return inferCharacterType(self)
    }

    class var idleAnimationFrames: [SKTexture] {
        get {
            return SharedTextures.textures[characterType]?[SharedTextures.Keys.idle] ?? []
        }
        set {
            var texturesForCharacterType = SharedTextures.textures[characterType] ?? [String: [SKTexture]]()
            texturesForCharacterType[SharedTextures.Keys.idle] = newValue
            SharedTextures.textures[characterType] = texturesForCharacterType
        }
    }

    class var walkAnimationFrames: [SKTexture] {
        get {
            return SharedTextures.textures[characterType]?[SharedTextures.Keys.walk] ?? []
        }
        set {
            var texturesForCharacterType = SharedTextures.textures[characterType] ?? [String: [SKTexture]]()
            texturesForCharacterType[SharedTextures.Keys.walk] = newValue
            SharedTextures.textures[characterType] = texturesForCharacterType
        }
    }

    class var attackAnimationFrames: [SKTexture] {
        get {
            return SharedTextures.textures[characterType]?[SharedTextures.Keys.attack] ?? []
        }
        set {
            var texturesForCharacterType = SharedTextures.textures[characterType] ?? [String: [SKTexture]]()
            texturesForCharacterType[SharedTextures.Keys.attack] = newValue
            SharedTextures.textures[characterType] = texturesForCharacterType
        }
    }

    class var getHitAnimationFrames: [SKTexture] {
        get {
            return SharedTextures.textures[characterType]?[SharedTextures.Keys.hit] ?? []
        }
        set {
            var texturesForCharacterType = SharedTextures.textures[characterType] ?? [String: [SKTexture]]()
            texturesForCharacterType[SharedTextures.Keys.hit] = newValue
            SharedTextures.textures[characterType] = texturesForCharacterType
        }
    }

    class var deathAnimationFrames: [SKTexture] {
        get {
            return SharedTextures.textures[characterType]?[SharedTextures.Keys.death] ?? []
        }
        set {
            var texturesForCharacterType = SharedTextures.textures[characterType] ?? [String: [SKTexture]]()
            texturesForCharacterType[SharedTextures.Keys.death] = newValue
            SharedTextures.textures[characterType] = texturesForCharacterType
        }
    }
    
    class var projectile: SKSpriteNode {
        get {
            return SharedSprites.sprites[characterType]?[SharedSprites.Keys.projectile] ?? SKSpriteNode()
        }
        set {
            var spritesForCharacterType = SharedSprites.sprites[characterType] ?? [String: SKSpriteNode]()
            spritesForCharacterType[SharedSprites.Keys.projectile] = newValue
            SharedSprites.sprites[characterType] = spritesForCharacterType
        }
    }

    class var damageEmitter: SKEmitterNode {
        get {
            return SharedEmitters.emitters[characterType]?[SharedEmitters.Keys.damage] ?? SKEmitterNode()
        }
        set {
            var emittersForCharacterType = SharedEmitters.emitters[characterType] ?? [String: SKEmitterNode]()
            emittersForCharacterType[SharedEmitters.Keys.damage] = newValue
            SharedEmitters.emitters[characterType] = emittersForCharacterType
        }
    }
    
    class var deathEmitter: SKEmitterNode {
        get {
            return SharedEmitters.emitters[characterType]?[SharedEmitters.Keys.death] ?? SKEmitterNode()
        }
        set {
            var emittersForCharacterType = SharedEmitters.emitters[characterType] ?? [String: SKEmitterNode]()
            emittersForCharacterType[SharedEmitters.Keys.death] = newValue
            SharedEmitters.emitters[characterType] = emittersForCharacterType
        }
    }
    
    class var projectileEmitter: SKEmitterNode {
        get {
            return SharedEmitters.emitters[characterType]?[SharedEmitters.Keys.projectile] ?? SKEmitterNode()
        }
        set {
            var emittersForCharacterType = SharedEmitters.emitters[characterType] ?? [String: SKEmitterNode]()
            emittersForCharacterType[SharedEmitters.Keys.projectile] = newValue
            SharedEmitters.emitters[characterType] = emittersForCharacterType
        }
    }

    class var damageAction: SKAction {
        get {
            return SharedActions.actions[characterType]?[SharedActions.Keys.damage] ?? SKAction()
        }
        set {
            var actionsForCharacterType = SharedActions.actions[characterType] ?? [String: SKAction]()
            actionsForCharacterType[SharedActions.Keys.damage] = newValue
            SharedActions.actions[characterType] = actionsForCharacterType
        }
    }

    // MARK: Initializers

    convenience init(sprites: [SKSpriteNode], atPosition position: CGPoint, usingOffset offset: CGFloat) {
        self.init(sprites: sprites, usingOffset: offset)

        sharedInitAtPosition(position)
    }

    convenience init(texture: SKTexture?, atPosition position: CGPoint) {
        let size = texture != nil ? texture!.size() : CGSize(width: 0, height: 0)
        self.init(texture: texture, color: SKColor.whiteColor(), size: size)

        sharedInitAtPosition(position)
    }

    func sharedInitAtPosition(position: CGPoint) {
        let atlas = SKTextureAtlas(named: "Environment")

        shadowBlob = SKSpriteNode(texture: atlas.textureNamed("blobShadow.png"))
        shadowBlob.zPosition = -1.0

        self.position = position

        configurePhysicsBody()
    }
    
    // MARK: NSCopying
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        var character = super.copyWithZone(zone) as! Character
        character.isDying = isDying
        character.isAttacking = isAttacking
        character.health = health
        character.animated = animated
        character.animationSpeed = animationSpeed
        character.movementSpeed = movementSpeed
        character.rotationSpeed = rotationSpeed
        character.requestedAnimation = requestedAnimation
        character.shadowBlob = shadowBlob.copy() as! SKSpriteNode
        return character
    }
    
    // MARK: Setup
    
    func configurePhysicsBody() {}
    
    override func setScale(scale: CGFloat) {
        super.setScale(scale)
        shadowBlob.setScale(scale)
    }
    
    // MARK: Scene Processing Support

    func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        shadowBlob.position = position
        
        if !animated {
            return
        }
        resolveRequestedAnimation()
    }

    func animationDidComplete(animation: AnimationState) {}
    
    func collidedWith(other: SKPhysicsBody) {}
    
    func applyDamage(var damage: Double, projectile: SKNode? = nil) -> Bool {
        if let proj = projectile {
            damage *= Double(proj.alpha)
        }
        
        health -= damage
        
        if health > 0.0 {
            let emitter = self.dynamicType.damageEmitter.copy() as! SKEmitterNode
            characterScene.addNode(emitter, atWorldLayer: .AboveCharacter)
            
            emitter.position = position
            runOneShotEmitter(emitter, withDuration: 0.15)
            
            runAction(self.dynamicType.damageAction)
            return false
        }
        
        performDeath()
        return true
    }

    func performAttackAction() {
        if isAttacking {
            return
        }
        
        isAttacking = true
        requestedAnimation = .Attack
    }
    
    func performDeath() {
        health = 0.0
        isDying = true
        requestedAnimation = .Death
    }
    
    func reset() {
        health = 100.0
        isDying = false
        isAttacking = false
        animated = true
        requestedAnimation = .Idle
        shadowBlob.alpha = 1.0
    }

    // MARK: Character Animation
    
    func resolveRequestedAnimation() {
        var (frames, key) = animationFramesAndKeyForState(requestedAnimation)

        fireAnimationForState(requestedAnimation, usingTextures: frames, withKey: key)

        requestedAnimation = isDying ? .Death : .Idle
    }

    func animationFramesAndKeyForState(state: AnimationState) -> ([SKTexture], String) {
        switch state {
            case .Walk:
               return (self.dynamicType.walkAnimationFrames, "anim_walk")

            case .Attack:
                return (self.dynamicType.attackAnimationFrames, "anim_attack")

            case .GetHit:
                return (self.dynamicType.getHitAnimationFrames, "anim_gethit")

            case .Death:
                return (self.dynamicType.deathAnimationFrames, "anim_death")

            case .Idle:
                return (self.dynamicType.idleAnimationFrames, "anim_idle")
        }
    }

    func fireAnimationForState(animationState: AnimationState, usingTextures frames: [SKTexture], withKey key: String) {
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
        if isDying {
            animated = false
            shadowBlob.runAction(SKAction.fadeOutWithDuration(1.5))
        }

        animationDidComplete(animationState)

        if isAttacking {
            isAttacking = false
        }
    }

    func fadeIn(duration: NSTimeInterval) {
        let fadeAction = SKAction.fadeInWithDuration(duration)

        alpha = 0.0
        runAction(fadeAction)

        shadowBlob.alpha = 0.0
        shadowBlob.runAction(fadeAction)
    }
    
    // MARK: Movement Handling
    
    func moveInMoveDirection(direction: MoveDirection, withTimeInterval timeInterval: NSTimeInterval) {
        var action: SKAction!
        
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
    
    func faceToPosition(position: CGPoint) -> CGFloat {
        var angle = adjustAssetOrientation(position.radiansToPoint(self.position))
        
        var action = SKAction.rotateToAngle(angle, duration: 0)
        
        runAction(action)

        return angle
    }
    
    func moveTowardsPosition(targetPosition: CGPoint, withTimeInterval timeInterval: NSTimeInterval) {
        // Grab an immutable position in case Sprite Kit changes it underneath us.
        let currentPosition = position
        var deltaX = targetPosition.x - currentPosition.x
        var deltaY = targetPosition.y - currentPosition.y
        var maximumDistance = movementSpeed * CGFloat(timeInterval)
        
        moveFromCurrentPosition(currentPosition, byDeltaX: deltaX, deltaY: deltaY, maximumDistance: maximumDistance)
    }
    
    func moveInDirection(direction: CGVector, withTimeInterval timeInterval: NSTimeInterval, facing: CGPoint? = nil) {
        // Grab an immutable position in case Sprite Kit changes it underneath us.
        let currentPosition = position
        var deltaX = movementSpeed * direction.dx
        var deltaY = movementSpeed * direction.dy
        var maximumDistance = movementSpeed * CGFloat(timeInterval)
        
        moveFromCurrentPosition(currentPosition, byDeltaX: deltaX, deltaY: deltaY, maximumDistance: maximumDistance, facing: facing)
    }
    
    func moveFromCurrentPosition(currentPosition: CGPoint, byDeltaX dx: CGFloat, deltaY dy: CGFloat, maximumDistance: CGFloat, facing: CGPoint? = nil) {
        let targetPosition = CGPoint(x: currentPosition.x + dx, y: currentPosition.y + dy)
        
        var angle = adjustAssetOrientation(targetPosition.radiansToPoint(currentPosition))
        
        if facing != nil {
            let facePosition = currentPosition + facing!
            faceToPosition(facePosition)
        }
        else {
            faceToPosition(targetPosition)
        }
        
        var distRemaining = hypot(dx, dy)
        if distRemaining < maximumDistance {
            position = targetPosition
        } else {
            let x = currentPosition.x - (maximumDistance * sin(angle))
            let y = currentPosition.y + (maximumDistance * cos(angle))
            position = CGPoint(x: x, y: y)
        }
        
        if !isAttacking {
            requestedAnimation = .Walk
        }
    }

    // MARK: Scene Interactions
    
    func addToScene(scene: AdventureScene) {
        scene.addNode(self, atWorldLayer: .Character)
        scene.addNode(shadowBlob, atWorldLayer: .BelowCharacter)
    }

    override func removeFromParent() {
        shadowBlob.removeFromParent()
        super.removeFromParent()
    }
}

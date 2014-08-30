/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class for the cave
      
*/

import SpriteKit

var kLoadSharedCaveAssetsOnceToken: dispatch_once_t = 0

class Cave: EnemyCharacter {
    var smokeEmitter: SKEmitterNode? = .None
    var timeUntilNextGenerate: CGFloat = 5000.0
    var activeGoblins = Goblin[]()
    var inactiveGoblins = Goblin[]()

    init(atPosition position: CGPoint) {
        let sprites = [sSharedCaveBase.copy() as SKSpriteNode, sSharedCaveTop.copy() as SKSpriteNode]
        super.init(sprites: sprites, atPosition:position, usingOffset: 50.0)

        timeUntilNextGenerate = 5.0 + 5.0 * unitRandom()

        for _ in 0..caveCapacity {
            var goblin = Goblin(atPosition: position)
            goblin.cave = self
            inactiveGoblins.append(goblin)
        }

        movementSpeed = 0.0
        name = "GoblinCave"

        // make it AWARE!
        intelligence = SpawnAI(character: self, target: nil)
    }

    override func configurePhysicsBody() {
        physicsBody = SKPhysicsBody(circleOfRadius: 90)
        physicsBody.dynamic = false

        animated = false
        zPosition = -0.85

        physicsBody.categoryBitMask = ColliderType.Cave.toRaw()
        physicsBody.collisionBitMask = ColliderType.Projectile.toRaw() | ColliderType.Hero.toRaw()
        physicsBody.contactTestBitMask = ColliderType.Projectile.toRaw()
    }

    override func reset() {
        super.reset()

        animated = false
    }

    class func loadSharedAssets() {
        dispatch_once(&kLoadSharedCaveAssetsOnceToken) {
            let atlas = SKTextureAtlas(named: "Environment")

            let fire: SKEmitterNode = SKEmitterNode.emitterNodeWithName("CaveFire")
            fire.zPosition = 1
            let smoke: SKEmitterNode = SKEmitterNode.emitterNodeWithName("CaveFireSmoke")

            var torch = SKNode()
            torch.addChild(fire)
            torch.addChild(smoke)

            sSharedCaveBase = SKSpriteNode(texture: atlas.textureNamed("cave_base.png"))

            torch.position = CGPoint(x: 83, y: 83)
            sSharedCaveBase.addChild(torch)

            var torchB = torch.copy() as SKNode
            torch.position = CGPoint(x: -83, y: 83)
            sSharedCaveBase.addChild(torchB)

            sSharedCaveTop = SKSpriteNode(texture: atlas.textureNamed("cave_top.png"))

            sSharedCaveDamageEmitter = SKEmitterNode.emitterNodeWithName("CaveDamage")
            sSharedCaveDeathEmitter = SKEmitterNode.emitterNodeWithName("CaveDeathSmoke")

            sSharedCaveDeathSplort = SKSpriteNode(texture: atlas.textureNamed("cave_destroyed.png"))

            sSharedCaveDamageAction = SKAction.sequence([
                    SKAction.colorizeWithColor(SKColor.redColor(), colorBlendFactor: 1.0, duration: 0.0),
                    SKAction.waitForDuration(0.25),
                    SKAction.colorizeWithColorBlendFactor(0.0, duration:0.1)])
        }
    }

    override func collidedWith(other: SKPhysicsBody) {
        if health > 0.0 {
            if (other.categoryBitMask & ColliderType.Projectile.toRaw()) == ColliderType.Projectile.toRaw() {
                let damage = 10.0
                applyCaveDamage(damage, projectile: other.node)
            }
        }
    }

    func applyCaveDamage(damage: Double, projectile: SKNode) {
        let killed = super.applyDamage(damage)
        if killed {
            // give the player some points
        }

        // show damage
        updateSmokeForHealth()

        // show damage on parallax stacks
        for node in children as SKNode[] {
            node.runAction(sSharedCaveDamageAction)
        }
    }

    func updateSmokeForHealth() {
        if health > 75.0 || smokeEmitter {
            return
        }

        var emitter: SKEmitterNode = sSharedCaveDeathEmitter.copy() as SKEmitterNode
        emitter.position = position
        emitter.zPosition = -0.8
        smokeEmitter = emitter
        characterScene.addNode(emitter, atWorldLayer: .AboveCharacter)
    }

    override func performDeath() {
        super.performDeath()

        let splort = sSharedCaveDeathSplort.copy() as SKSpriteNode
        splort.zPosition = -1.0
        splort.zRotation = virtualZRotation
        splort.position = position
        splort.alpha = 0.1
        splort.runAction(SKAction.fadeAlphaTo(1.0, duration: 0.5))

        characterScene.addNode(splort, atWorldLayer: .BelowCharacter)

        runAction(SKAction.sequence([
            SKAction.fadeAlphaTo(0.0, duration: 0.5),
            SKAction.removeFromParent()
        ]))
        if let smoke = smokeEmitter {
            smoke.runAction(SKAction.sequence([
                SKAction.waitForDuration(2.0),
                SKAction.runBlock {
                    smoke.particleBirthRate = 2.0
                },
                SKAction.waitForDuration(2.0),
                SKAction.runBlock {
                    smoke.particleBirthRate = 0.0
                },
                SKAction.waitForDuration(10.0),
                SKAction.fadeAlphaTo(0.0, duration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }

// LOOP UPDATE
    override func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        super.updateWithTimeSinceLastUpdate(interval) // this triggers the update in the SpawnAI

        for goblin in activeGoblins {
            goblin.updateWithTimeSinceLastUpdate(interval)
        }
    }

// GOBLIN TARGETING
    func stopGoblinsFromTargettingHero(target: Character) {
        for goblin in activeGoblins {
            goblin.intelligence.clearTarget(target)
        }
    }

// SPAWNING SUPPORT
    func generate() {
        if sSharedGoblinCap > 0 && sSharedGoblinAllocation >= sSharedGoblinCap {
            return
        }

        if inactiveGoblins.count > 0 {
            let goblin = inactiveGoblins.removeLast()

            let offset = caveCollisionRadius * 0.75
            let rot = adjustAssetOrientation(virtualZRotation)
            goblin.position = position.pointByAdding(CGPoint(x: cos(rot)*offset, y: sin(rot)*offset))

            goblin.addToScene(characterScene)

            goblin.zPosition = -1.0

            goblin.fadeIn(0.5)

            activeGoblins.append(goblin)

            sSharedGoblinAllocation++
        }
    }

    func recycle(goblin: Goblin) {
        goblin.reset()
        if let index = find(activeGoblins, goblin) {
            activeGoblins.removeAtIndex(index)
        }
        inactiveGoblins.append(goblin)
        sSharedGoblinAllocation--
    }
}

let caveCollisionRadius: CGFloat = 90.0
let caveCapacity = 50
let sSharedGoblinCap = 32
var sSharedGoblinAllocation = 0
var sSharedCaveBase = SKSpriteNode()
var sSharedCaveTop = SKSpriteNode()
var sSharedCaveDeathSplort = SKSpriteNode()
var sSharedCaveDamageEmitter = SKEmitterNode()
var sSharedCaveDeathEmitter = SKEmitterNode()
var sSharedCaveDamageAction = SKAction()

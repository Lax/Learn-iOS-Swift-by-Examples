/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        The primary scene class for Adventure
      
*/

import SpriteKit

// Set this to true to cheat and end up next to the level boss
let cheat = false

enum CharacterClass {
  case Warrior
  case Archer
}

class AdventureScene: LayeredCharacterScene, SKPhysicsContactDelegate {

    var levelMap = UnsafePointer<SpriteLocation>(createDataMap("map_level.png"))
    var treeMap = UnsafePointer<TreeLocation>(createDataMap("map_trees.png"))
    var parallaxSprites = ParallaxSprite[]()
    var trees = Tree[]()
    var particleSystems = SKEmitterNode[]()
    var goblinCaves = Cave[]()
    var levelBoss: Boss? = nil
    
    init(size: CGSize) {
        super.init(size: size)

        buildWorld()

        centerWorldOnPosition(defaultSpawnPoint)
    }

// WORLD BUILDING

    func buildWorld() {
        physicsWorld.gravity = CGVector(0, 0)
        physicsWorld.contactDelegate = self

        addBackgroundTiles()
        addSpawnPoints()
        addTrees()
        addCollisionWalls()
    }

    func addBackgroundTiles() {
        for tileNode in sBackgroundTiles {
            addNode(tileNode, atWorldLayer: .Ground)
        }
    }

    func addSpawnPoints() {
        for y in 0..kLevelMapSize {
            for x in 0..kLevelMapSize {
                let location = CGPoint(x: x, y: y)
                let spot = queryLevelMap(location)

                let worldPoint = convertLevelMapPointToWorldPoint(location)

                if spot.bossLocation <= 200 {
                    levelBoss = Boss(atPosition:worldPoint)
                    levelBoss!.addToScene(self)
                } else if spot.goblinCaveLocation >= 200 {
                    let cave = Cave(atPosition: worldPoint)
                    goblinCaves.append(cave)
                    parallaxSprites.append(cave)
                    cave.addToScene(self)
                } else if spot.heroSpawnLocation >= 200 {
                    defaultSpawnPoint = worldPoint
                }
            }
        }
    }

    func addTrees() {
        for y in 0..kLevelMapSize {
            for x in 0..kLevelMapSize {
                let location = CGPoint(x: x, y: y)
                let spot = queryTreeMap(location)
                let treePos = convertLevelMapPointToWorldPoint(location)
                var treeLayer = WorldLayer.Top

                var tree: Tree
                if spot.smallTreeLocation >= 200 {
                    treeLayer = .AboveCharacter
                    tree = sSharedSmallTree.copy() as Tree
                } else if spot.bigTreeLocation >= 200 {
                    tree = sSharedBigTree.copy() as Tree

                    var emitter: SKEmitterNode
                    if arc4random_uniform(2) == 1 {
                        emitter = sSharedLeafEmitterA.copy() as SKEmitterNode
                    } else {
                        emitter = sSharedLeafEmitterB.copy() as SKEmitterNode
                    }

                    emitter.position = treePos
                    emitter.paused = true
                    addNode(emitter, atWorldLayer: .AboveCharacter)
                    particleSystems.append(emitter)
                } else {
                    continue
                }

                tree.position = treePos
                tree.zRotation = unitRandom()
                addNode(tree, atWorldLayer: .Top)
                parallaxSprites.append(tree)
                trees.append(tree)
            }
        }

        free(treeMap)
    }

    func addCollisionWalls() {
        var filled = UInt8[](count: kLevelMapSize * kLevelMapSize, repeatedValue: 0)

        var numVolumes = 0, numBlocks = 0

        for y in 0..kLevelMapSize {
            for x in 0..kLevelMapSize {
                let location = CGPoint(x: x, y: y)
                let spot = queryLevelMap(location)

                let worldPoint = convertLevelMapPointToWorldPoint(location)

                if spot.wall < 200 {
                    continue // no wall
                }

                var horizontalDistanceFromLeft = x
                var nextSpot = spot
                while (horizontalDistanceFromLeft < kLevelMapSize && nextSpot.wall >= 200 &&
                       filled[(y * kLevelMapSize) + horizontalDistanceFromLeft] < 1) {
                    horizontalDistanceFromLeft++
                    nextSpot = queryLevelMap(CGPoint(x: horizontalDistanceFromLeft, y: y))
                }

                let wallWidth = horizontalDistanceFromLeft - x
                var verticalDistanceFromTop = y

                if wallWidth > 8 {
                    nextSpot = spot
                    while verticalDistanceFromTop < kLevelMapSize && nextSpot.wall >= 200 {
                        verticalDistanceFromTop++
                        nextSpot = queryLevelMap(CGPoint(x: x + (wallWidth / 2), y: verticalDistanceFromTop))
                    }

                    var wallHeight = verticalDistanceFromTop - y
                    for j in y..verticalDistanceFromTop {
                        for i in x..horizontalDistanceFromLeft {
                            filled[(j * kLevelMapSize) + i] = 255
                            numBlocks++
                        }
                    }

                    addCollisionWallAtWorldPoint(worldPoint, width: CGFloat(kLevelMapDivisor * wallWidth), height: CGFloat(kLevelMapDivisor * wallHeight))
                    numVolumes++
                }
            }
        }

        for x in 0..kLevelMapSize {
            for y in 0..kLevelMapSize {
                let location = CGPoint(x: x, y: y)
                let spot = queryLevelMap(location)

                let worldPoint = convertLevelMapPointToWorldPoint(location)

                if spot.wall < 200 || filled[(y * kLevelMapSize) + x] > 0 {
                    continue
                }

                var verticalDistanceFromTop = y
                var nextSpot = spot
                while verticalDistanceFromTop < kLevelMapSize && nextSpot.wall >= 200 && filled[(verticalDistanceFromTop * kLevelMapSize) + x] < 1 {
                    verticalDistanceFromTop++
                    nextSpot = queryLevelMap(CGPoint(x: x, y: verticalDistanceFromTop))
                }

                let wallHeight = verticalDistanceFromTop - y
                var horizontalDistanceFromLeft = x

                if wallHeight > 8 {
                    nextSpot = spot
                    while horizontalDistanceFromLeft < kLevelMapSize && nextSpot.wall >= 200 {
                        horizontalDistanceFromLeft++
                        nextSpot = queryLevelMap(CGPoint(x: horizontalDistanceFromLeft, y: y + (wallHeight / 2)))
                    }

                    let wallLength = horizontalDistanceFromLeft - x
                    for j in y..verticalDistanceFromTop {
                        for i in x..horizontalDistanceFromLeft {
                            filled[(j * kLevelMapSize) + i] = 255
                            numBlocks++
                        }
                    }
                    addCollisionWallAtWorldPoint(worldPoint, width: CGFloat(kLevelMapDivisor * wallLength), height: CGFloat(kLevelMapDivisor * wallHeight))
                    numVolumes++
                }
            }
        }
    }

    func addCollisionWallAtWorldPoint(worldPoint: CGPoint, width: CGFloat, height: CGFloat) {
        let size = CGSize(width: width, height: height)
        let wallNode = SKNode()
        wallNode.position = CGPoint(x: worldPoint.x + size.width * 0.5, y: worldPoint.y - size.height * 0.5)
        wallNode.physicsBody = SKPhysicsBody(rectangleOfSize: size)
        wallNode.physicsBody.dynamic = false
        wallNode.physicsBody.categoryBitMask = ColliderType.Wall.toRaw()
        wallNode.physicsBody.collisionBitMask = 0

        addNode(wallNode, atWorldLayer: .Ground)
    }

    // MAPPING
    func queryLevelMap(point: CGPoint) -> SpriteLocation {
        let index = (Int(point.y) * kLevelMapSize) + Int(point.x)
        return levelMap[index]
    }

    func queryTreeMap(point: CGPoint) -> TreeLocation {
        let index = (Int(point.y) * kLevelMapSize) + Int(point.x)
        return treeMap[index]
    }

    func convertLevelMapPointToWorldPoint(location: CGPoint) -> CGPoint {
        // Given a level map pixel point, convert up to a world point.
        // This determines which "tile" the point falls in and centers within that tile.
        let x =   (Int(location.x) * kLevelMapDivisor) - (kWorldCenter + (kWorldTileSize/2))
        let y = -((Int(location.y) * kLevelMapDivisor) - (kWorldCenter + (kWorldTileSize/2)))

        return CGPoint(x: x, y: y)
    }

    func convertWorldPointToLevelMapPoint(location: CGPoint) -> CGPoint {
        let x = (Int(location.x) + kWorldCenter) / kLevelMapDivisor
        let y = (kWorldSize - (Int(location.y) + kWorldCenter)) / kLevelMapDivisor
        return CGPoint(x: x, y: y)
    }

    override func canSee(point: CGPoint, from vantagePoint: CGPoint) -> Bool {
        let a = convertWorldPointToLevelMapPoint(point)
        let b = convertWorldPointToLevelMapPoint(vantagePoint)

        let deltaX = b.x - a.x
        let deltaY = b.y - a.y
        let dist = a.distanceTo(b)
        let inc = 1.0 / dist
        var p = CGPointZero

        for var i: CGFloat = 0.0; i < inc; i += inc {
            p.x = a.x + i * deltaX
            p.y = a.y + i * deltaY

            let location = queryLevelMap(p)
            if (location.wall > 200) {
                return false
            }
        }
        return true
    }
    
// HEROES
    override func heroWasKilled(hero: HeroCharacter) {
        for cave in goblinCaves {
            cave.stopGoblinsFromTargettingHero(hero)
        }
        
        super.heroWasKilled(hero)
    }
    
// LEVEL START
    func startLevel(charClass: CharacterClass) {
        defaultPlayer.charClass = charClass
        addHeroForPlayer(defaultPlayer)

        if cheat {
            var bossPosition = levelBoss!.position
            bossPosition.x += 128
            bossPosition.y += 512
            defaultPlayer.hero!.position = bossPosition
        }
    }

// LOOP UPDATE
    override func updateWithTimeSinceLastUpdate(timeSinceLast: NSTimeInterval) {
        for hero in heroes {
            hero.updateWithTimeSinceLastUpdate(timeSinceLast)
        }

        levelBoss?.updateWithTimeSinceLastUpdate(timeSinceLast)

        for cave in goblinCaves {
            cave.updateWithTimeSinceLastUpdate(timeSinceLast)
        }
    }

    override func updateAfterSimulatingPhysics() {
        var position = defaultPlayer.hero!.position

        for tree in trees {
            if tree.position.distanceTo(position) < 1024 {
                tree.updateAlphaWithScene(self)
            }
        }

        if !worldMovedForUpdate {
            return
        }

        for emitter in particleSystems {
            var emitterIsVisible = (emitter.position.distanceTo(position) < 1024)
            if !emitterIsVisible && !emitter.paused {
                emitter.paused = true
            } else if emitterIsVisible && emitter.paused {
                emitter.paused = false
            }
        }

        for sprite in parallaxSprites {
            if sprite.position.distanceTo(position) < 1024 {
                sprite.updateOffset()
            }
        }
    }

// PHYSICS DELEGATE
    func didBeginContact(contact: SKPhysicsContact) {
        if let character = contact.bodyA.node as? Character {
            character.collidedWith(contact.bodyB)
        }

        if let character = contact.bodyB.node as? Character {
            character.collidedWith(contact.bodyA)
        }

        if contact.bodyA.categoryBitMask & 4 > 0 || contact.bodyB.categoryBitMask & 4 > 0 {
            let projectile = (contact.bodyA.categoryBitMask & 4) > 0 ? contact.bodyA.node : contact.bodyB.node

            projectile.runAction(SKAction.removeFromParent())

            let emitter = sSharedProjectileSparkEmitter.copy() as SKEmitterNode
            addNode(emitter, atWorldLayer: .AboveCharacter)
            emitter.position = projectile.position

            runOneShotEmitter(emitter, withDuration: 0.15)
        }
    }


// PRELOADING
    override class func loadSceneAssets() {
        AdventureScene.loadBackgroundTiles()

        Goblin.loadSharedAssets()
        Warrior.loadSharedAssets()
        Archer.loadSharedAssets()
        Cave.loadSharedAssets()
        HeroCharacter.loadSharedHeroAssets()
        Boss.loadSharedAssets()

        sSharedLeafEmitterA = .emitterNodeWithName("Leaves_01")
        sSharedLeafEmitterB = .emitterNodeWithName("Leaves_02")
        sSharedProjectileSparkEmitter = .emitterNodeWithName("ProjectileSplat")
        sSharedSpawnEmitter = .emitterNodeWithName("Spawn")
        
        // Load Trees
        let atlas = SKTextureAtlas(named: "Environment")
        var sprites = [
            SKSpriteNode(texture: atlas.textureNamed("small_tree_base.png")),
            SKSpriteNode(texture: atlas.textureNamed("small_tree_middle.png")),
            SKSpriteNode(texture: atlas.textureNamed("small_tree_top.png"))
        ]
        sSharedSmallTree = Tree(sprites:sprites, usingOffset:25.0)

        sprites = [
            SKSpriteNode(texture: atlas.textureNamed("big_tree_base.png")),
            SKSpriteNode(texture: atlas.textureNamed("big_tree_middle.png")),
            SKSpriteNode(texture: atlas.textureNamed("big_tree_top.png"))
        ]
        sSharedBigTree = Tree(sprites:sprites, usingOffset:150.0)
        sSharedBigTree.fadeAlpha = true
    }

    class func loadBackgroundTiles() {
        var tileAtlas = SKTextureAtlas(named: "Tiles")

        for y in 0..kWorldTileDivisor {
            for x in 0..kWorldTileDivisor {
                let tileNumber = (y * kWorldTileDivisor) + x
                let tileNode = SKSpriteNode(texture: tileAtlas.textureNamed("tile\(tileNumber).png"))

                let xPosition = CGFloat((x * kWorldTileSize) - kWorldCenter)
                let yPosition = CGFloat((kWorldSize - (y * kWorldTileSize)) - kWorldCenter)

                let position = CGPoint(x: xPosition, y: yPosition)

                tileNode.position = position
                tileNode.zPosition = -1.0
                tileNode.blendMode = .Replace
                sBackgroundTiles.append(tileNode)
            }
        }
    }

}


var sBackgroundTiles = SKSpriteNode[]()
var sSharedSmallTree = Tree(sprites: SKSpriteNode[](), usingOffset: 0.0)
var sSharedBigTree = Tree(sprites: SKSpriteNode[](), usingOffset: 0.0)
var sSharedLeafEmitterA = SKEmitterNode()
var sSharedLeafEmitterB = SKEmitterNode()
var sSharedProjectileSparkEmitter = SKEmitterNode()
var sSharedSpawnEmitter = SKEmitterNode()

let kWorldTileDivisor = 32
let kWorldSize = 4096
let kWorldTileSize = kWorldSize / kWorldTileDivisor
let kWorldCenter = kWorldSize / 2
let kLevelMapSize = 256
let kLevelMapDivisor = (kWorldSize / kLevelMapSize)

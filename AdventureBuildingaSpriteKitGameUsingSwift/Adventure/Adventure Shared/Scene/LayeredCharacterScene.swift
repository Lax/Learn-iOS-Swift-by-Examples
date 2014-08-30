/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the layered character scene class
      
*/


import SpriteKit

/// The location of a sprite encoded as a 32-bit integer on disk.
struct SpriteLocation {
    var fullLocation : UInt32

    var bossLocation: UInt8 {
      return UInt8(fullLocation & 0x000000FF) 
    }

    var wall: UInt8 { 
      return UInt8((fullLocation & 0x0000FF00) >> 8) 
    }

    var goblinCaveLocation: UInt8 { 
      return UInt8((fullLocation & 0x00FF0000) >> 16)
    }

    var heroSpawnLocation: UInt8 {
        return UInt8((fullLocation & 0xFF000000) >> 24)
    }
}

/// The location of a tree encoded as a 32-bit integer on disk.
struct TreeLocation {
    var fullLocation : UInt32

    var bigTreeLocation: UInt8 {
        return UInt8((fullLocation & 0x0000FF00) >> 8)
    }

    var smallTreeLocation: UInt8 {
        return UInt8((fullLocation & 0x00FF0000) >> 16)
    }
}

enum WorldLayer: Int {
    case Ground = 0, BelowCharacter, Character, AboveCharacter, Top
}

let kStartLives = 3
let kWorldLayerCount = 5
let kMinTimeInterval = (1.0 / 60.0)
let kMinHeroToEdgeDistance: CGFloat = 256.0                // minimum distance between hero and edge of camera before moving camera

class LayeredCharacterScene: SKScene {
    var world = SKNode()
    var layers = SKNode[]()

    var heroes = HeroCharacter[]()

    var defaultSpawnPoint = CGPointZero
    var worldMovedForUpdate = false

    var defaultPlayer = Player()

    // HUD
    var hudAvatar: SKSpriteNode! = nil
    var hudLabel: SKLabelNode! = nil
    var hudScore: SKLabelNode! = nil
    var hudLifeHearts = SKSpriteNode[]()

    var lastUpdateTimeInterval = NSTimeInterval(0)

    init(size: CGSize) {
        super.init(size: size)

        world.name = "world"
        for i in 0..kWorldLayerCount {
            let layer = SKNode()
            layer.zPosition = CGFloat(i - kWorldLayerCount)
            world.addChild(layer)
            layers.append(layer)
        }

        addChild(world)
        
        buildHUD()
        updateHUDForPlayer(defaultPlayer)
    }

    func addNode(node: SKNode, atWorldLayer layer: WorldLayer) {
        let layerNode = layers[layer.toRaw()]

        layerNode.addChild(node)
    }

// HEROES
    func addHeroForPlayer(player: Player) -> HeroCharacter {
        if let hero = player.hero {
          if !hero.dying {
            hero.removeFromParent()
          }
        }

        let spawnPos = defaultSpawnPoint

        var hero: HeroCharacter
        switch player.charClass! {
            case .Warrior:
                hero = Warrior(atPosition: spawnPos, withPlayer: player)

            case .Archer:
                hero = Archer(atPosition: spawnPos, withPlayer: player)
        }

        let emitter = sSharedSpawnEmitter.copy() as SKEmitterNode
        emitter.position = spawnPos
        addNode(emitter, atWorldLayer: .AboveCharacter)
        runOneShotEmitter(emitter, withDuration: 0.15)

        hero.fadeIn(2.0)
        hero.addToScene(self)
        heroes.append(hero)

        player.hero = hero

        return hero
    }

    func heroWasKilled(hero: HeroCharacter) {
        let player = hero.player
    
        // Remove this hero from our list of heroes
        for (idx, obj) in enumerate(heroes) {
            if obj === hero {
                heroes.removeAtIndex(idx)
                break
            }
        }
        
        #if os(iOS)
        // Disable touch movement, otherwise new hero will try to move to previously-touched location.
        player.moveRequested = false;
        #endif
    
        --player.livesLeft

        if player.livesLeft < 0 {
            // In a real game, you'd want to end the game when there are no lives left.
            return
        }

        updateHUDAfterHeroDeathForPlayer(hero.player)

        let hero = addHeroForPlayer(player)
        
        centerWorldOnCharacter(hero)
    }

// HUD and Scores
    func buildHUD() {
        let iconName = "iconWarrior_blue"
        let color = SKColor.greenColor()
        let fontName = "Copperplate"
        let hudX: CGFloat = 30
        let hudY: CGFloat = self.frame.size.height - 30
        let hudD: CGFloat = self.frame.size.width
    
        let hud = SKNode()
        
        // Add the avatar
        hudAvatar = SKSpriteNode(imageNamed: iconName)
        hudAvatar.setScale(0.5)
        hudAvatar.alpha = 0.5
        hudAvatar.position = CGPoint(x: hudX, y: self.frame.size.height - hudAvatar.size.height * 0.5 - 8)
        hud.addChild(hudAvatar)
    
        // Add the label
        hudLabel = SKLabelNode(fontNamed: fontName)
        hudLabel.text = "ME"
        hudLabel.fontColor = color
        hudLabel.fontSize = 16;
        hudLabel.horizontalAlignmentMode = .Left
        hudLabel.position = CGPoint(x: hudX + (hudAvatar.size.width * 1.0), y: hudY + 10 )
        hud.addChild(hudLabel)
        
        // Add the score.
        hudScore = SKLabelNode(fontNamed: fontName)
        hudScore.text = "SCORE: 0"
        hudScore.fontColor = color
        hudScore.fontSize = 16
        hudScore.horizontalAlignmentMode = .Left;
        hudScore.position = CGPoint(x: hudX + (hudAvatar.size.width * 1.0), y: hudY - 40 )
        hud.addChild(hudScore)
    
        // Add the life hearts.
        for j in 0..kStartLives {
            let heart = SKSpriteNode(imageNamed: "lives.png")
            heart.setScale(0.4)
            heart.position = CGPoint(x: hudX + (hudAvatar.size.width * 1.0) + 18 + ((heart.size.width + 5) * CGFloat(j)), y: hudY - 10)
            hudLifeHearts.append(heart)
            hud.addChild(heart)
        }
    
        self.addChild(hud)
    }

    func updateHUDForPlayer(player: Player) {
        hudScore.text = "SCORE: \(player.score)"
    }

    func updateHUDAfterHeroDeathForPlayer(player: Player) {
        // Fade out the relevant heart - one-based livesLeft has already been decremented.
        let heartNumber = player.livesLeft;
        
        let heart = hudLifeHearts[heartNumber]
        heart.runAction(SKAction.fadeAlphaTo(0.0, duration: 3.0))
    }

    func addToScore(amount: Int, afterEnemyKillWithProjectile projectile: SKNode) {
        let player = projectile.userData[kPlayer] as Player
        player.score += amount;
        updateHUDForPlayer(player)
    }


// LOOP UPDATE
    override func update(currentTime: NSTimeInterval) {
        var timeSinceLast = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = currentTime

        if timeSinceLast > 1 {
            timeSinceLast = kMinTimeInterval
            worldMovedForUpdate = true
        }

        updateWithTimeSinceLastUpdate(timeSinceLast)

        if !defaultPlayer.hero {
            return
        }

        let hero = defaultPlayer.hero!
        
        if hero.dying {
            return
        }
        
        if defaultPlayer.moveForward {
            hero.move(.Forward, withTimeInterval: timeSinceLast)
        } else if defaultPlayer.moveBack {
            hero.move(.Back, withTimeInterval: timeSinceLast)
        }

        if defaultPlayer.moveLeft {
            hero.move(.Left, withTimeInterval: timeSinceLast)
        } else if defaultPlayer.moveRight {
            hero.move(.Right, withTimeInterval: timeSinceLast)
        }

        if defaultPlayer.fireAction {
            hero.performAttackAction()
        }

        #if os(iOS)
        if defaultPlayer.targetLocation != CGPointZero {
            if defaultPlayer.fireAction {
                hero.faceTo(defaultPlayer.targetLocation)
            }
            
            if defaultPlayer.moveRequested {
                if defaultPlayer.targetLocation != hero.position {
                    hero.moveTowards(defaultPlayer.targetLocation,
                                     withTimeInterval: timeSinceLast)
                } else {
                    defaultPlayer.moveRequested = false
                }
            }
        }

        #endif
    }

    func updateWithTimeSinceLastUpdate(timeSinceLast: NSTimeInterval) {
      // Overridden by subclasses
    }

    override func didSimulatePhysics() {
        if let defaultHero = defaultPlayer.hero {
            let heroPosition = defaultHero.position
            var worldPos = world.position

            let yCoordinate = worldPos.y + heroPosition.y
            if yCoordinate < kMinHeroToEdgeDistance {
                worldPos.y = worldPos.y - yCoordinate + kMinHeroToEdgeDistance
                worldMovedForUpdate = true
            } else if yCoordinate > (frame.size.height - kMinHeroToEdgeDistance) {
                worldPos.y = worldPos.y + (frame.size.height - yCoordinate) - kMinHeroToEdgeDistance
                worldMovedForUpdate = true
            }

            let xCoordinate = worldPos.x + heroPosition.x
            if xCoordinate < kMinHeroToEdgeDistance {
                worldPos.x = worldPos.x - xCoordinate + kMinHeroToEdgeDistance
                worldMovedForUpdate = true
            } else if xCoordinate > (frame.size.width - kMinHeroToEdgeDistance) {
                worldPos.x = worldPos.x + (frame.size.width - xCoordinate) - kMinHeroToEdgeDistance
                worldMovedForUpdate = true
            }

            world.position = worldPos

            updateAfterSimulatingPhysics()

            worldMovedForUpdate = false
        }
    }

    func updateAfterSimulatingPhysics() { }

// ASSET LOADING
    class func loadSceneAssetsWithCompletionHandler(completionHandler: () -> Void) {
        let queue = dispatch_get_current_queue()

        let backgroundQueue = dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_HIGH), 0)
        dispatch_async(backgroundQueue) {
            self.loadSceneAssets()

            dispatch_async(queue, completionHandler)
        }
    }

    class func loadSceneAssets() {

    }

// MAPPING
    func centerWorldOnPosition(position: CGPoint) {
        world.position = CGPoint(x: -position.x + CGRectGetMidX(frame),
            y: -position.y + CGRectGetMidY(frame))
        worldMovedForUpdate = true
    }
    
    func centerWorldOnCharacter(character: Character) {
        centerWorldOnPosition(character.position)
    }
    
    func canSee(point: CGPoint, from vantagePoint: CGPoint) -> Bool {
        return false
    }
}

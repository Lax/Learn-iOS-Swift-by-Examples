/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  The primary scene class for Adventure.
*/

import SpriteKit
import GameController

class AdventureScene: SKScene, SKPhysicsContactDelegate {
    // MARK: Types
    
    enum WorldLayer: Int {
        case Ground = 0, BelowCharacter, Character, AboveCharacter, Top
    }
    
    struct Constants {
        static let worldTileDivisor = 32
        static let worldSize = 4096
        static let worldTileSize = worldSize / worldTileDivisor
        static let worldCenter = worldSize / 2
        
        static let minimumUpdateInterval = 1.0 / 60.0
        
        // The minimum distance between the hero and a currently visible edge before moving camera.
        static let minimumDistanceFromHeroToVisibleEdge: CGFloat = 256.0
        
        // Node names for each of the HUD nodes.
        static let hudNodeName = "AdventureHUD"
        static let hudAvatarName = "hudAvatar"
        static let hudScoreName = "hudScore"
        static let hudHeartName = "hudHeart"
        
        static let hudWidth = 300
        
        static let backgroundQueue = dispatch_queue_create("com.example.apple-samplecode.Adventure.backgroundQueue", DISPATCH_QUEUE_SERIAL)
    }
    
    // MARK: Properties
    
    /*
        Parent node containing the entire scene. This allows the node to be moved relative to the
        viewport, allowing the characters to move about in a scene larger than the viewport.
    */
    var world = SKNode()
    
    // Properties to track nodes that are updated during each pass of the game loop. Populated during loading.
    var heroes = [HeroCharacter]()
    var goblinCaves = [Cave]()
    var trees = [Tree]()
    var particleSystems = [SKEmitterNode]()
    var parallaxSprites = [ParallaxSprite]()
    // The boss will always exist. Its value is deferred until its position is known when the world is loaded.
    var levelBoss: Boss!
    
    // Static during game processing. Populated during loading.
    var backgroundTiles = [SKSpriteNode]()
    
    // Templates populated during initialization and used during environment population.
    var leafEmitterATemplate: SKEmitterNode
    var leafEmitterBTemplate: SKEmitterNode
    var spawnEmitterTemplate: SKEmitterNode
    var projectileSparkEmitterTemplate: SKEmitterNode
    
    // Property containing references to the 5 different layers in the world.
    var layers = [SKNode]()
    
    // Properties for the nodes that make up the HUD.
    var hudAvatar: SKSpriteNode!
    var hudScore: SKLabelNode!
    var hudLifeHearts = [SKSpriteNode]()

    var defaultSpawnPoint = CGPointZero
    var defaultPlayer = Player()
    
    /*
        A maximum of 4 players are supported. The array is initialized with `nil` in each position. The default
        player will be populated during initialization at index 0. Subsequent players will be added as needed 
        during game controller connection up to a maximum of 4.
    */
    var players: [Player!] = [nil, nil, nil, nil]

    // Properties to keep track of details important to scene updates.
    var worldMovedForUpdate = false
    var lastUpdateTimeInterval: NSTimeInterval = 0

    // Set to `true` to cheat and start the level next to the boss.
    var shouldCheat = false
    
    // A closure to be called when `didMoveToView(_:)` completes.
    var finishedMovingToView: Void -> Void = {}
    
    // MARK: Initializers
    
    override init(size: CGSize) {
        leafEmitterATemplate = SKEmitterNode(fileNamed: "Leaves_01")
        leafEmitterBTemplate = SKEmitterNode(fileNamed: "Leaves_02")
        projectileSparkEmitterTemplate = SKEmitterNode(fileNamed: "ProjectileSplat")
        spawnEmitterTemplate = SKEmitterNode(fileNamed: "Spawn")
        
        super.init(size: size)

        players[0] = defaultPlayer
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("AdventureScene does not support NSCoding. Use loadSceneAssetsWithCompletionHandler(_:) instead.")
    }
    
    // MARK: SKView Behaviors

    override func didMoveToView(view: SKView) {
        // Complete the loading on a background queue to not take up the main queue's resources.
        dispatch_async(Constants.backgroundQueue) {
            self.loadWorld()
            
            self.centerWorldOnPosition(self.defaultSpawnPoint)

            dispatch_async(dispatch_get_main_queue(), self.finishedMovingToView)
        }
    }

    override func didChangeSize(oldSize: CGSize) {
        enumerateChildNodesWithName(Constants.hudNodeName) { hud, stop in
            hud.position = CGPoint(x: hud.position.x, y: self.frame.size.height)
        }
    }

    // MARK: Scene Processing Support

    override func update(currentTime: NSTimeInterval) {
        if paused {
            lastUpdateTimeInterval = currentTime
            
            return
        }

        var timeSinceLast = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = currentTime

        if timeSinceLast > 1 {
            timeSinceLast = Constants.minimumUpdateInterval
            worldMovedForUpdate = true
        }

        updateWithTimeSinceLastUpdate(timeSinceLast)

        #if os(iOS)
        if defaultPlayer.hero == nil {
            return
        }

        let hero = defaultPlayer.hero!

        if hero.isDying {
            return
        }

        if defaultPlayer.targetLocation != CGPointZero {
            if defaultPlayer.fireAction {
                hero.faceToPosition(defaultPlayer.targetLocation)
            }

            if defaultPlayer.moveRequested {
                if defaultPlayer.targetLocation != hero.position {
                    hero.moveTowardsPosition(defaultPlayer.targetLocation, withTimeInterval: timeSinceLast)
                }
                else {
                    defaultPlayer.moveRequested = false
                }
            }
        }
        #endif

        for player in self.players {
            // If there is no player in this slot, move on.
            if player == nil {
                continue
            }

            // If the player has no assigned hero or their hero is isDying, move on.
            if player.hero == nil || player.hero!.isDying {
                continue
            }

            let hero = player.hero!

            /*
                Player movement input will be provided via `heroMoveDirection` or individual movements via
                `moveForward` or `moveBackward` and rotation via `moveLeft` and `moveRight`. `heroMoveDirection` 
                is populated when input is received from a controller. The individual movement details are 
                received when using keyboard input.
            */
            if let heroMoveDirection = player.heroMoveDirection {
                var moveFacing: CGPoint?
                if let heroFaceLocation = player.heroFaceLocation {
                    moveFacing = heroFaceLocation
                }
                
                let magnitude = hypotf(Float(heroMoveDirection.dx), Float(heroMoveDirection.dy))
                if  magnitude > 0.0 || moveFacing != nil {
                    hero.moveInDirection(heroMoveDirection, withTimeInterval: timeSinceLast, facing: moveFacing)
                }
            }
            else {
                if let heroFaceLocation = player.heroFaceLocation {
                    hero.faceToPosition(heroFaceLocation)
                }
                
                if player.moveForward {
                    hero.moveInMoveDirection(.Forward, withTimeInterval: timeSinceLast)
                }
                else if player.moveBackward {
                    hero.moveInMoveDirection(.Back, withTimeInterval: timeSinceLast)
                }

                if player.moveLeft {
                    hero.moveInMoveDirection(.Left, withTimeInterval: timeSinceLast)
                }
                else if player.moveRight {
                    hero.moveInMoveDirection(.Right, withTimeInterval: timeSinceLast)
                }
            }

            if player.fireAction {
                hero.performAttackAction()
            }
        }
    }

    override func didSimulatePhysics() {
        if paused {
            return
        }
        
        for player in players {
            if let defaultHero = player?.hero {
                let heroPosition = defaultHero.position
                var worldPosition = world.position
                
                let yCoordinate = worldPosition.y + heroPosition.y
                if yCoordinate < Constants.minimumDistanceFromHeroToVisibleEdge {
                    worldPosition.y = worldPosition.y - yCoordinate + Constants.minimumDistanceFromHeroToVisibleEdge
                    worldMovedForUpdate = true
                } else if yCoordinate > (frame.size.height - Constants.minimumDistanceFromHeroToVisibleEdge) {
                    worldPosition.y = worldPosition.y + (frame.size.height - yCoordinate) - Constants.minimumDistanceFromHeroToVisibleEdge
                    worldMovedForUpdate = true
                }
                
                
                let xCoordinate = worldPosition.x + heroPosition.x
                if xCoordinate < Constants.minimumDistanceFromHeroToVisibleEdge {
                    worldPosition.x = worldPosition.x - xCoordinate + Constants.minimumDistanceFromHeroToVisibleEdge
                    worldMovedForUpdate = true
                } else if xCoordinate > (frame.size.width - Constants.minimumDistanceFromHeroToVisibleEdge) {
                    worldPosition.x = worldPosition.x + (frame.size.width - xCoordinate) - Constants.minimumDistanceFromHeroToVisibleEdge
                    worldMovedForUpdate = true
                }
                
                world.position = worldPosition
                
                updateAfterSimulatingPhysics()
                
                worldMovedForUpdate = false
            }
        }
    }

    func updateWithTimeSinceLastUpdate(timeSinceLast: NSTimeInterval) {
        for hero in heroes {
            hero.updateWithTimeSinceLastUpdate(timeSinceLast)
        }

        levelBoss?.updateWithTimeSinceLastUpdate(timeSinceLast)

        for cave in goblinCaves {
            cave.updateWithTimeSinceLastUpdate(timeSinceLast)
        }
    }

    func updateAfterSimulatingPhysics() {
        var position = defaultPlayer.hero!.position

        for tree in trees {
            if tree.position.distanceToPoint(position) < 1024 {
                tree.updateAlphaWithScene(self)
            }
        }

        if !worldMovedForUpdate {
            return
        }

        for emitter in particleSystems {
            var emitterIsVisible = (emitter.position.distanceToPoint(position) < 1024)
            if !emitterIsVisible && !emitter.paused {
                emitter.paused = true
            } else if emitterIsVisible && emitter.paused {
                emitter.paused = false
            }
        }

        for sprite in parallaxSprites {
            if sprite.position.distanceToPoint(position) < 1024 {
                sprite.updateOffset()
            }
        }
    }

    // MARK: SKPhysicsContactDelegate

    func didBeginContact(contact: SKPhysicsContact) {
        if let character = contact.bodyA.node as? Character {
            character.collidedWith(contact.bodyB)
        }

        if let character = contact.bodyB.node as? Character {
            character.collidedWith(contact.bodyA)
        }

        let rawProjectileType = ColliderType.Projectile.rawValue
        let bodyAIsProjectile = contact.bodyA.categoryBitMask & rawProjectileType == rawProjectileType
        let bodyBIsProjectile = contact.bodyB.categoryBitMask & rawProjectileType == rawProjectileType
        
        if bodyAIsProjectile || bodyBIsProjectile {
            // Conditionally set `bodyA` as the projectile; if it isn't then `bodyB` is the projectile.
            if let projectile = bodyAIsProjectile ? contact.bodyA.node : contact.bodyB.node {
                projectile.runAction(SKAction.removeFromParent())
                
                let emitter = projectileSparkEmitterTemplate.copy() as! SKEmitterNode
                addNode(emitter, atWorldLayer: .AboveCharacter)
                emitter.position = projectile.position

                runOneShotEmitter(emitter, withDuration: 0.15)
            }
        }
    }

    // MARK: Game Start

    func startLevel(heroType: Player.HeroType) {
        defaultPlayer.heroType = heroType
        addHeroForPlayer(defaultPlayer)
        
        if shouldCheat {
            var bossPosition = levelBoss.position
            bossPosition.x += 128
            bossPosition.y += 512
            defaultPlayer.hero!.position = bossPosition
        }

        // Setup the HUD for the default player.
        loadHUDForPlayer(defaultPlayer, atIndex: 0)

        configureGameControllers()
    }

    // MARK: Character Support

    func canSee(point: CGPoint, from vantagePoint: CGPoint) -> Bool {
        let rayStart = vantagePoint
        let rayEnd = point

        var wallFound = false
        physicsWorld.enumerateBodiesAlongRayStart(rayStart, end: rayEnd) { body, point, normal, stop in
            if body.categoryBitMask & ColliderType.Wall.rawValue == ColliderType.Wall.rawValue {
                wallFound = true
                stop.memory = true
            }
        }

        return !wallFound
    }

    // MARK: Hero Interactions

    func addHeroForPlayer(player: Player) -> HeroCharacter {
        if let hero = player.hero {
            if !hero.isDying {
                hero.removeFromParent()
            }
        }

        var spawnPosition = defaultSpawnPoint

        for aHero in heroes {
            if !aHero.isDying {
                spawnPosition = aHero.position
            }
        }

        var hero: HeroCharacter
        switch player.heroType! {
            case .Warrior:
                hero = Warrior(atPosition: spawnPosition, withPlayer: player)

            case .Archer:
                hero = Archer(atPosition: spawnPosition, withPlayer: player)
        }

        let emitter = spawnEmitterTemplate.copy() as! SKEmitterNode
        emitter.position = spawnPosition
        addNode(emitter, atWorldLayer: .AboveCharacter)
        runOneShotEmitter(emitter, withDuration: 0.15)

        hero.fadeIn(2.0)
        hero.addToScene(self)
        heroes.append(hero)

        player.hero = hero

        return hero
    }

    func heroWasKilled(hero: HeroCharacter) {
        for cave in goblinCaves {
            cave.stopGoblinsFromTargettingHero(hero)
        }

        let player = hero.player

        // Remove this hero from our list of heroes
        for (idx, aHero) in enumerate(heroes) {
            if aHero === hero {
                heroes.removeAtIndex(idx)
                break
            }
        }

        #if os(iOS)
        // Disable touch movement, otherwise new hero will try to move to previously-touched location.
        player.moveRequested = false
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

    // MARK: HUD and Scores

    func loadHUDForPlayer(player: Player, atIndex index: Int) {
        let hudScene: SKScene = SKScene(fileNamed: Constants.hudNodeName)
        let hud = hudScene.children.first!.copy() as! SKNode
        hud.name = Constants.hudNodeName
        hud.position = CGPoint(x: CGFloat(0 + Constants.hudWidth * index), y: frame.size.height)
        addChild(hud)
        player.hudAvatar = hud.childNodeWithName(Constants.hudAvatarName) as! SKSpriteNode
        player.hudScore = hud.childNodeWithName(Constants.hudScoreName) as! SKLabelNode
        hud.enumerateChildNodesWithName(Constants.hudHeartName) { node, stop in
            player.hudLifeHearts.append(node as! SKSpriteNode)
        }

        updateHUDForPlayer(player)
    }

    func updateHUDForPlayer(player: Player) {
        player.hudScore.text = String.localizedStringWithFormat(NSLocalizedString("SCORE: %d", comment: ""), player.score)
    }

    func updateHUDAfterHeroDeathForPlayer(player: Player) {
        // Fade out the relevant heart - one-based livesLeft has already been decremented.
        let heartNumber = player.livesLeft

        let heart = player.hudLifeHearts[heartNumber]
        heart.runAction(SKAction.fadeAlphaTo(0.0, duration: 3.0))
    }

    func addToScore(amount: Int, afterEnemyKillWithProjectile projectile: SKNode) {
        if let player = projectile.userData?[Player.Keys.projectileUserDataPlayer] as? Player {
            player.score += amount
            updateHUDForPlayer(player)
        }
    }

    // MARK: World Construction

    func loadWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        let scene = SKScene(fileNamed: "AdventureWorld")
        let templateWorld = scene.children.first!.copy() as! SKNode

        world.name = "world"
        addChild(world)

        populateLayersFromWorld(templateWorld)
        populateBackgroundTiles()
        populateWallsFromWorld(templateWorld)
        populateCharactersFromWorld(templateWorld)
        populateTreesFromWorld(templateWorld)
    }

    func populateLayersFromWorld(fromWorld: SKNode) {
        fromWorld.enumerateChildNodesWithName("layer*") { node, stop in
            let layer = SKNode()
            layer.name = node.name
            self.world.addChild(layer)
            self.layers.append(layer)
        }
    }

    func populateBackgroundTiles() {
        for tileNode in backgroundTiles {
            addNode(tileNode, atWorldLayer: .Ground)
        }
    }

    func populateWallsFromWorld(fromWorld: SKNode) {
        let ground = fromWorld.childNodeWithName("layerGround")!
        ground.enumerateChildNodesWithName("wall") { node, stop in
            // Unwrap the physics body to configure it.
            let wallNode = node.copy() as! SKNode
            wallNode.physicsBody!.dynamic = false
            wallNode.physicsBody!.categoryBitMask = ColliderType.Wall.rawValue
            self.addNode(wallNode, atWorldLayer: .Ground)
        }
    }

    func populateCharactersFromWorld(fromWorld: SKNode) {
        defaultSpawnPoint = fromWorld.childNodeWithName("//defaultSpawnPoint")!.position
        levelBoss = Boss(atPosition: fromWorld.childNodeWithName("//boss")!.position)
        levelBoss.addToScene(self)
        
        fromWorld.enumerateChildNodesWithName("//cave") { node, stop in
            let cave = Cave.Shared.template.copy() as! Cave
            cave.position = node.position
            cave.zRotation = node.zRotation
            cave.timeUntilNextGenerate = 5.0 + 5.0 * unitRandom()
            
            for _ in 0..<Cave.Constants.goblinCapacity {
                var goblin = Goblin(atPosition: node.position)
                goblin.cave = cave
                cave.inactiveGoblins.append(goblin)
            }

            // Make it aware!
            cave.intelligence = SpawnArtificialIntelligence(character: cave)

            self.goblinCaves.append(cave)
            self.parallaxSprites.append(cave)
            cave.addToScene(self)
        }
    }

    func populateTreesFromWorld(fromWorld: SKNode) {
        fromWorld.enumerateChildNodesWithName("//*Tree") { node, stop in
            var tree: Tree
            switch node.name {
            case let name where name == "smallTree":
                tree = Tree.Shared.smallTemplate.copy() as! Tree
            case let name where name == "bigTree":
                tree = Tree.Shared.largeTemplate.copy() as! Tree
                
                var emitter: SKEmitterNode
                if arc4random_uniform(2) == 1 {
                    emitter = self.leafEmitterATemplate.copy() as! SKEmitterNode
                } else {
                    emitter = self.leafEmitterBTemplate.copy() as! SKEmitterNode
                }

                emitter.position = node.position
                emitter.paused = true
                self.addNode(emitter, atWorldLayer: .AboveCharacter)
                self.particleSystems.append(emitter)
            default:
                return
            }

            tree.position = node.position
            tree.zRotation = unitRandom()
            self.addNode(tree, atWorldLayer: .Top)
            self.parallaxSprites.append(tree)
            self.trees.append(tree)
        }
    }

    func addNode(node: SKNode, atWorldLayer layer: WorldLayer) {
        let layerNode = layers[layer.rawValue]

        layerNode.addChild(node)
    }

    // MARK: Asset Pre-loading
    
    class func loadSceneAssetsWithCompletionHandler(completionHandler: AdventureScene -> Void) {
        dispatch_async(Constants.backgroundQueue) {
            Tree.loadSharedAssets()
            Warrior.loadSharedAssets()
            Archer.loadSharedAssets()
            Cave.loadSharedAssets()
            Goblin.loadSharedAssets()
            Boss.loadSharedAssets()
            
            let loadedScene = AdventureScene(size: CGSize(width: 1024, height: 768))
            loadedScene.loadBackgroundTiles()
            
            dispatch_async(dispatch_get_main_queue()) { completionHandler(loadedScene) }
        }
    }

    func loadBackgroundTiles() {
        var tileAtlas = SKTextureAtlas(named: "Tiles")

        for y in 0..<Constants.worldTileDivisor {
            for x in 0..<Constants.worldTileDivisor {
                let tileNumber = (y * Constants.worldTileDivisor) + x
                
                let tileNode = SKSpriteNode(texture: tileAtlas.textureNamed("tile\(tileNumber).png"))

                let xPosition = CGFloat((x * Constants.worldTileSize) - Constants.worldCenter + Constants.worldTileSize / 2)
                let yPosition = CGFloat((Constants.worldSize - (y * Constants.worldTileSize)) - Constants.worldCenter  - Constants.worldTileSize / 2)

                let position = CGPoint(x: xPosition, y: yPosition)

                tileNode.position = position
                tileNode.zPosition = -1.0
                tileNode.blendMode = .Replace
                backgroundTiles.append(tileNode)
            }
        }
    }

    // MARK: Camera Convenience
    
    func centerWorldOnPosition(position: CGPoint) {
        world.position = CGPoint(x: -position.x + CGRectGetMidX(frame),
            y: -position.y + CGRectGetMidY(frame))
        worldMovedForUpdate = true
    }

    func centerWorldOnCharacter(character: Character) {
        centerWorldOnPosition(character.position)
    }

    // MARK: Game Controllers
    
    func configureGameControllers() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "gameControllerDidConnect:", name: GCControllerDidConnectNotification, object: nil)
        notificationCenter.addObserver(self, selector: "gameControllerDidDisconnect:", name: GCControllerDidDisconnectNotification, object: nil)

        configureConnectedGameControllers()

        GCController.startWirelessControllerDiscoveryWithCompletionHandler(nil)
    }

    func configureConnectedGameControllers() {
        let gameControllers = GCController.controllers() as! [GCController]
        
        for controller in gameControllers {
            let playerIndex = controller.playerIndex
            if playerIndex == GCControllerPlayerIndexUnset {
                continue
            }

            assignPresetController(controller, toIndex: playerIndex)
        }

        for controller in gameControllers {
            let playerIndex = controller.playerIndex
            if playerIndex != GCControllerPlayerIndexUnset {
                continue
            }

            assignUnknownController(controller)
        }
    }

    func gameControllerDidConnect(notification: NSNotification) {
        let controller = notification.object as! GCController
        let playerIndex = controller.playerIndex
        if playerIndex == GCControllerPlayerIndexUnset {
            assignUnknownController(controller)
        }
        else {
            assignPresetController(controller, toIndex: playerIndex)
        }
    }

    func gameControllerDidDisconnect(notification: NSNotification) {
        let controller = notification.object as! GCController
        for player in players {
            if let player = player {
                if player.controller == controller {
                    player.controller = nil
                }
            }
        }
    }

    func assignUnknownController(controller: GCController) {
        // Specifically declare `player` as mutable so that we can reassign it while processing.
        for (index, var player) in enumerate(players) {
            if player == nil {
                player = Player()
                players[index] = player
            }

            if player.controller != nil {
                continue
            }

            controller.playerIndex = index
            configureController(controller, forPlayer: player)
            return
        }
    }

    func assignPresetController(controller: GCController, toIndex index: Int) {
        var player = players[index]
        if player == nil {
            player = Player()
            players[index] = player
        }

        if player?.controller != nil && player?.controller != controller {
            assignUnknownController(controller)
            return
        }

        configureController(controller, forPlayer: player)
    }

    func configureController(controller: GCController, forPlayer player: Player) {
        player.controller = controller

        let directionPadMoveHandler: GCControllerDirectionPadValueChangedHandler = { dpad, x, y in
            let length = hypotf(x, y)
            if length > 0.0 {
                let inverseLength = 1 / length
                player.heroMoveDirection = CGVector(dx: CGFloat(x * inverseLength), dy: CGFloat(y * inverseLength))
            }
            else {
                player.heroMoveDirection = CGVector(dx: 0, dy: 0)
            }
        }

        let rightThumbstickHandler: GCControllerDirectionPadValueChangedHandler = { dpad, x, y in
            let length = hypotf(x, y)
            if length <= 0.5 {
                player.heroFaceLocation = nil
                return
            }

            let point = CGPoint(x: CGFloat(x), y: CGFloat(y))
            player.heroFaceLocation = point
        }

        controller.extendedGamepad?.leftThumbstick.valueChangedHandler = directionPadMoveHandler
        controller.extendedGamepad?.rightThumbstick.valueChangedHandler = rightThumbstickHandler
        controller.gamepad?.dpad.valueChangedHandler = directionPadMoveHandler

        let fireButtonHandler: GCControllerButtonValueChangedHandler = { button, value, pressed in
            player.fireAction = pressed
        }

        controller.gamepad?.buttonA.valueChangedHandler = fireButtonHandler
        controller.gamepad?.buttonB.valueChangedHandler = fireButtonHandler
        controller.extendedGamepad?.rightTrigger.valueChangedHandler = fireButtonHandler

        if player !== defaultPlayer && player.hero == nil {
            loadHUDForPlayer(player, atIndex: player.controller!.playerIndex)
            addHeroForPlayer(player)
        }
    }
}

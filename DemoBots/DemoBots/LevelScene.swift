/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `LevelScene` is an `SKScene` representing a playable level in the game. `WorldLayer` is an enumeration that represents the different z-indexed layers of a `LevelScene`.
*/

import SpriteKit
import GameplayKit

/// The names and z-positions of each layer in a level's world.
enum WorldLayer: CGFloat {
    // The zPosition offset to use per character (`PlayerBot` or `TaskBot`).
    static let zSpacePerCharacter: CGFloat = 100
    
    // Specifying `AboveCharacters` as 1000 gives room for 9 enemies on a level.
    case board = -100, debug = -75, shadows = -50, obstacles = -25, characters = 0, aboveCharacters = 1000, top = 1100
    
    // The expected name for this node in the scene file.
    var nodeName: String {
        switch self {
            case .board: return "board"
            case .debug: return "debug"
            case .shadows: return "shadows"
            case .obstacles: return "obstacles"
            case .characters: return "characters"
            case .aboveCharacters: return "above_characters"
            case .top: return "top"
        }
    }
    
    // The full path to this node, for use with `childNode(withName name:)`.
    var nodePath: String {
        return "/world/\(nodeName)"
    }

    static var allLayers = [board, debug, shadows, obstacles, characters, aboveCharacters, top]
}

class LevelScene: BaseScene, SKPhysicsContactDelegate {
    // MARK: Properties
    
    /// Stores a reference to the root nodes for each world layer in the scene.
    var worldLayerNodes = [WorldLayer: SKNode]()
    
    var worldNode: SKNode {
        return childNode(withName: "world")!
    }

    let playerBot = PlayerBot()
    var entities = Set<GKEntity>()
    
    var lastUpdateTimeInterval: TimeInterval = 0
    let maximumUpdateDeltaTime: TimeInterval = 1.0 / 60.0
    
    var levelConfiguration: LevelConfiguration!
    
    lazy var stateMachine: GKStateMachine = GKStateMachine(states: [
        LevelSceneActiveState(levelScene: self),
        LevelScenePauseState(levelScene: self),
        LevelSceneSuccessState(levelScene: self),
        LevelSceneFailState(levelScene: self)
    ])
    
    let timerNode = SKLabelNode(text: "--:--")
    
    override var overlay: SceneOverlay? {
        didSet {
            // Ensure that focus changes are only enabled when the `overlay` is present.
            focusChangesEnabled = (overlay != nil)
        }
    }
  
    // MARK: Pathfinding
    
    let graph = GKObstacleGraph(obstacles: [], bufferRadius: GameplayConfiguration.TaskBot.pathfindingGraphBufferRadius)
  
    lazy var obstacleSpriteNodes: [SKSpriteNode] = self["world/obstacles/*"] as! [SKSpriteNode]
  
    lazy var polygonObstacles: [GKPolygonObstacle] = SKNode.obstacles(fromNodePhysicsBodies: self.obstacleSpriteNodes)
  
    // MARK: Pathfinding Debug
    
    var debugDrawingEnabled = false {
        didSet {
            debugDrawingEnabledDidChange()
        }
    }
    var graphLayer = SKNode()
    var debugObstacleLayer = SKNode()
    
    // MARK: Rule State
    
    var levelStateSnapshot: LevelStateSnapshot?
    
    func entitySnapshotForEntity(entity: GKEntity) -> EntitySnapshot? {
        // Create a snapshot of the level's state if one does not already exist for this update cycle.
        if levelStateSnapshot == nil {
            levelStateSnapshot = LevelStateSnapshot(scene: self)
        }
        
        // Find and return the entity snapshot for this entity.
        return levelStateSnapshot!.entitySnapshots[entity]
    }

    // MARK: Component Systems
    
    lazy var componentSystems: [GKComponentSystem] = {
        let agentSystem = GKComponentSystem(componentClass: TaskBotAgent.self)
        let animationSystem = GKComponentSystem(componentClass: AnimationComponent.self)
        let chargeSystem = GKComponentSystem(componentClass: ChargeComponent.self)
        let intelligenceSystem = GKComponentSystem(componentClass: IntelligenceComponent.self)
        let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)
        let beamSystem = GKComponentSystem(componentClass: BeamComponent.self)
        let rulesSystem = GKComponentSystem(componentClass: RulesComponent.self)
        
        // The systems will be updated in order. This order is explicitly defined to match assumptions made within components.
        return [rulesSystem, intelligenceSystem, movementSystem, agentSystem, chargeSystem, beamSystem, animationSystem]
    }()
    
    // MARK: Initializers
    
    deinit {
        unregisterForPauseNotifications()
    }

    // MARK: Scene Life Cycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Load the level's configuration from the level data file.
        levelConfiguration = LevelConfiguration(fileName: sceneManager.currentSceneMetadata!.fileName)

        // Set up the path finding graph with all polygon obstacles.
        graph.addObstacles(polygonObstacles)
        
        // Register for notifications about the app becoming inactive.
        registerForPauseNotifications()

        // Create references to the base nodes that define the different layers of the scene.
        loadWorldLayers()

        // Add a `PlayerBot` for the player.
        beamInPlayerBot()
        
        // Gravity will be in the negative z direction; there is no x or y component.
        physicsWorld.gravity = CGVector.zero
        
        // The scene will handle physics contacts itself.
        physicsWorld.contactDelegate = self
        
        // Move to the active state, starting the level timer.
        stateMachine.enter(LevelSceneActiveState.self)
        
        // Add the debug layers to the scene.
        addNode(node: graphLayer, toWorldLayer: .debug)
        addNode(node: debugObstacleLayer, toWorldLayer: .debug)

        // Configure the `timerNode` and add it to the camera node.
        timerNode.zPosition = WorldLayer.aboveCharacters.rawValue
        timerNode.fontColor = SKColor.white
        timerNode.fontName = GameplayConfiguration.Timer.fontName
        timerNode.horizontalAlignmentMode = .center
        timerNode.verticalAlignmentMode = .top
        scaleTimerNode()
        camera!.addChild(timerNode)

        // A convenience function to find node locations given a set of node names.
        func nodePointsFromNodeNames(nodeNames: [String]) -> [CGPoint] {
            let charactersNode = childNode(withName: WorldLayer.characters.nodePath)!
            return nodeNames.map {
                charactersNode[$0].first!.position
            }
        }
        
        // Iterate over the `TaskBot` configurations for this level, and create each `TaskBot`.
        for taskBotConfiguration in levelConfiguration.taskBotConfigurations {
            let taskBot: TaskBot

            // Find the locations of the nodes that define the `TaskBot`'s "good" and "bad" patrol paths.
            let goodPathPoints = nodePointsFromNodeNames(nodeNames: taskBotConfiguration.goodPathNodeNames)
            let badPathPoints = nodePointsFromNodeNames(nodeNames: taskBotConfiguration.badPathNodeNames)
            
            // Create the appropriate type `TaskBot` (ground or flying).
            switch taskBotConfiguration.locomotion {
                case .flying:
                    taskBot = FlyingBot(isGood: !taskBotConfiguration.startsBad, goodPathPoints: goodPathPoints, badPathPoints: badPathPoints)
                    
                case .ground:
                    taskBot = GroundBot(isGood: !taskBotConfiguration.startsBad, goodPathPoints: goodPathPoints, badPathPoints: badPathPoints)
            }
            
            // Set the `TaskBot`'s initial orientation so that it is facing the correct way.
            guard let orientationComponent = taskBot.component(ofType: OrientationComponent.self) else {
                fatalError("A task bot must have an orientation component to be able to be added to a level")
            }
            orientationComponent.compassDirection = taskBotConfiguration.initialOrientation

            // Set the `TaskBot`'s initial position.
            let taskBotNode = taskBot.renderComponent.node
            taskBotNode.position = taskBot.isGood ? goodPathPoints.first! : badPathPoints.first!
            taskBot.updateAgentPositionToMatchNodePosition()
            
            // Add the `TaskBot` to the scene and the component systems.
            addEntity(entity: taskBot)

            // Add the `TaskBot`'s debug drawing node beneath all characters.
            addNode(node: taskBot.debugNode, toWorldLayer: .debug)
        }
        
        #if os(iOS)
        /*
            Set up iOS touch controls. The player's `nativeControlInputSource`
            is added to the scene by the `BaseSceneTouchEventForwarding` extension.
        */
        addTouchInputToScene()
        touchControlInputNode.hideThumbStickNodes = sceneManager.gameInput.isGameControllerConnected
            
        // Start screen recording. See `LevelScene+ScreenRecording` for implementation.
        startScreenRecording()
        #endif
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        /*
            A `LevelScene` needs to update its camera constraints to match the new
            aspect ratio of the window when the window size changes.
        */
        setCameraConstraints()
        
        // As the scene may now have a different height, scale and position the timer node appropriately.
        scaleTimerNode()
    }
    
    // MARK: SKScene Processing
    
    /// Called before each frame is rendered.
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Don't perform any updates if the scene isn't in a view.
        guard view != nil else { return }
        
        // Calculate the amount of time since `update` was last called.
        var deltaTime = currentTime - lastUpdateTimeInterval
        
        // If more than `maximumUpdateDeltaTime` has passed, clamp to the maximum; otherwise use `deltaTime`.
        deltaTime = deltaTime > maximumUpdateDeltaTime ? maximumUpdateDeltaTime : deltaTime
        
        // The current time will be used as the last update time in the next execution of the method.
        lastUpdateTimeInterval = currentTime
        
        // Get rid of the now-stale `LevelStateSnapshot` if it exists. It will be regenerated when next needed.
        levelStateSnapshot = nil
        
        /*
            Don't evaluate any updates if the `worldNode` is paused.
            Pausing a subsection of the node tree allows the `camera`
            and `overlay` nodes to remain interactive.
        */
        if worldNode.isPaused { return }
        
        // Update the level's state machine.
        stateMachine.update(deltaTime: deltaTime)

        /*
            Update each component system.
            The order of systems in `componentSystems` is important
            and was determined when the `componentSystems` array was instantiated.
        */
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    override func didFinishUpdate() {
        // Check if the `playerBot` has been added to this scene.
        if let playerBotNode = playerBot.component(ofType: RenderComponent.self)?.node, playerBotNode.scene == self {
            /*
                Update the `PlayerBot`'s agent position to match its node position.
                This makes sure that the agent is in a valid location in the SpriteKit
                physics world at the start of its next update cycle.
            */
            playerBot.updateAgentPositionToMatchNodePosition()
        }
        
        // Sort the entities in the scene by ascending y-position.
        let ySortedEntities = entities.sorted {
            let nodeA = $0.0.component(ofType: RenderComponent.self)!.node
            let nodeB = $0.1.component(ofType: RenderComponent.self)!.node
            
            return nodeA.position.y > nodeB.position.y
        }
        
        // Set the `zPosition` of each entity so that entities with a higher y-position are rendered above those with a lower y-position.
        var characterZPosition = WorldLayer.zSpacePerCharacter
        for entity in ySortedEntities {
            let node = entity.component(ofType: RenderComponent.self)!.node
            node.zPosition = characterZPosition
            
            // Use a large enough z-position increment to leave space for emitter effects.
            characterZPosition += WorldLayer.zSpacePerCharacter
        }
    }
    
    // MARK: SKPhysicsContactDelegate
    
    @objc(didBeginContact:) func didBegin(_ contact: SKPhysicsContact) {
        handleContact(contact: contact) { (ContactNotifiableType: ContactNotifiableType, otherEntity: GKEntity) in
            ContactNotifiableType.contactWithEntityDidBegin(otherEntity)
        }
    }
    
    @objc(didEndContact:) func didEnd(_ contact: SKPhysicsContact) {
        handleContact(contact: contact) { (ContactNotifiableType: ContactNotifiableType, otherEntity: GKEntity) in
            ContactNotifiableType.contactWithEntityDidEnd(otherEntity)
        }
    }
    
    // MARK: SKPhysicsContactDelegate convenience
    
    private func handleContact(contact: SKPhysicsContact, contactCallback: (ContactNotifiableType, GKEntity) -> Void) {
        // Get the `ColliderType` for each contacted body.
        let colliderTypeA = ColliderType(rawValue: contact.bodyA.categoryBitMask)
        let colliderTypeB = ColliderType(rawValue: contact.bodyB.categoryBitMask)
        
        // Determine which `ColliderType` should be notified of the contact.
        let aWantsCallback = colliderTypeA.notifyOnContactWith(colliderTypeB)
        let bWantsCallback = colliderTypeB.notifyOnContactWith(colliderTypeA)
        
        // Make sure that at least one of the entities wants to handle this contact.
        assert(aWantsCallback || bWantsCallback, "Unhandled physics contact - A = \(colliderTypeA), B = \(colliderTypeB)")
        
        let entityA = contact.bodyA.node?.entity
        let entityB = contact.bodyB.node?.entity

        /*
            If `entityA` is a notifiable type and `colliderTypeA` specifies that it should be notified
            of contact with `colliderTypeB`, call the callback on `entityA`.
        */
        if let notifiableEntity = entityA as? ContactNotifiableType, let otherEntity = entityB, aWantsCallback {
            contactCallback(notifiableEntity, otherEntity)
        }
        
        /*
            If `entityB` is a notifiable type and `colliderTypeB` specifies that it should be notified
            of contact with `colliderTypeA`, call the callback on `entityB`.
        */
        if let notifiableEntity = entityB as? ContactNotifiableType, let otherEntity = entityA, bWantsCallback {
            contactCallback(notifiableEntity, otherEntity)
        }
    }
    
    // MARK: Level Construction
    
    func loadWorldLayers() {
        for worldLayer in WorldLayer.allLayers {
            // Try to find a matching node for this world layer's node name.
            let foundNodes = self["world/\(worldLayer.nodeName)"]
            
            // Make sure it was possible to find a node with this name.
            precondition(!foundNodes.isEmpty, "Could not find a world layer node for \(worldLayer.nodeName)")
            
            // Retrieve the actual node.
            let layerNode = foundNodes.first!
            
            // Make sure that the node's `zPosition` is correct relative to the other world layers.
            layerNode.zPosition = worldLayer.rawValue
            
            // Store a reference to the retrieved node.
            worldLayerNodes[worldLayer] = layerNode
        }
    }
    
    func addEntity(entity: GKEntity) {
        entities.insert(entity)

        for componentSystem in self.componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }

        // If the entity has a `RenderComponent`, add its node to the scene.
        if let renderNode = entity.component(ofType: RenderComponent.self)?.node {
            addNode(node: renderNode, toWorldLayer: .characters)

            /* 
                If the entity has a `ShadowComponent`, add its shadow node to the scene.
                Constrain the `ShadowComponent`'s node to the `RenderComponent`'s node.
            */
            if let shadowNode = entity.component(ofType: ShadowComponent.self)?.node {
                addNode(node: shadowNode, toWorldLayer: .shadows)
                
                // Constrain the shadow node's position to the render node.
                let xRange = SKRange(constantValue: shadowNode.position.x)
                let yRange = SKRange(constantValue: shadowNode.position.y)

                let constraint = SKConstraint.positionX(xRange, y: yRange)
                constraint.referenceNode = renderNode

                shadowNode.constraints = [constraint]
            }
            
            /*
                If the entity has a `ChargeComponent` with a `ChargeBar`, add the `ChargeBar`
                to the scene. Constrain the `ChargeBar` to the `RenderComponent`'s node.
            */
            if let chargeBar = entity.component(ofType: ChargeComponent.self)?.chargeBar {
                addNode(node: chargeBar, toWorldLayer: .aboveCharacters)
                
                // Constrain the `ChargeBar`'s node position to the render node.
                let xRange = SKRange(constantValue: GameplayConfiguration.PlayerBot.chargeBarOffset.x)
                let yRange = SKRange(constantValue: GameplayConfiguration.PlayerBot.chargeBarOffset.y)

                let constraint = SKConstraint.positionX(xRange, y: yRange)
                constraint.referenceNode = renderNode
                
                chargeBar.constraints = [constraint]
            }
        }
        
        // If the entity has an `IntelligenceComponent`, enter its initial state.
        if let intelligenceComponent = entity.component(ofType: IntelligenceComponent.self) {
            intelligenceComponent.enterInitialState()
        }
    }
    
    func addNode(node: SKNode, toWorldLayer worldLayer: WorldLayer) {
        let worldLayerNode = worldLayerNodes[worldLayer]!
        
        worldLayerNode.addChild(node)
    }
    
    // MARK: GameInputDelegate

    override func gameInputDidUpdateControlInputSources(gameInput: GameInput) {
        super.gameInputDidUpdateControlInputSources(gameInput: gameInput)
        
        /*
            Update the player's `controlInputSources` to delegate input
            to the playerBot's `InputComponent`.
        */
        for controlInputSource in gameInput.controlInputSources {
            controlInputSource.delegate = playerBot.component(ofType: InputComponent.self)
        }
        
        #if os(iOS)
        // When a game controller is connected, hide the thumb stick nodes.
        touchControlInputNode.hideThumbStickNodes = gameInput.isGameControllerConnected
        #endif
    }
    
    // MARK: ControlInputSourceGameStateDelegate
    
    override func controlInputSourceDidTogglePauseState(_ controlInputSource: ControlInputSourceType) {
        if stateMachine.currentState is LevelSceneActiveState {
            stateMachine.enter(LevelScenePauseState.self)
        }
        else {
            stateMachine.enter(LevelSceneActiveState.self)
        }
    }
    
    #if DEBUG
    override func controlInputSourceDidToggleDebugInfo(_ controlInputSource: ControlInputSourceType) {
        debugDrawingEnabled = !debugDrawingEnabled
        
        if let view = view {
            view.showsPhysics   = debugDrawingEnabled
            view.showsFPS       = debugDrawingEnabled
            view.showsNodeCount = debugDrawingEnabled
            view.showsDrawCount = debugDrawingEnabled
        }
    }
    
    override func controlInputSourceDidTriggerLevelSuccess(_ controlInputSource: ControlInputSourceType) {
        if stateMachine.currentState is LevelSceneActiveState {
            stateMachine.enter(LevelSceneSuccessState.self)
        }
    }
    
    override func controlInputSourceDidTriggerLevelFailure(_ controlInputSource: ControlInputSourceType) {
        if stateMachine.currentState is LevelSceneActiveState {
            stateMachine.enter(LevelSceneFailState.self)
        }
    }

    #endif
    
    // MARK: ButtonNodeResponderType
    
    override func buttonTriggered(button: ButtonNode) {
        switch button.buttonIdentifier! {
        case .resume:
            stateMachine.enter(LevelSceneActiveState.self)
            
        default:
            // Allow `BaseScene` to handle the event in `BaseScene+Buttons`.
            super.buttonTriggered(button: button)
        }
    }
    
    // MARK: Convenience
    
    /// Constrains the camera to follow the PlayerBot without approaching the scene edges.
    private func setCameraConstraints() {
        // Don't try to set up camera constraints if we don't yet have a camera.
        guard let camera = camera else { return }
        
        // Constrain the camera to stay a constant distance of 0 points from the player node.
        let zeroRange = SKRange(constantValue: 0.0)
        let playerNode = playerBot.renderComponent.node
        let playerBotLocationConstraint = SKConstraint.distance(zeroRange, to: playerNode)
        
        /*
            Also constrain the camera to avoid it moving to the very edges of the scene.
            First, work out the scaled size of the scene. Its scaled height will always be
            the original height of the scene, but its scaled width will vary based on
            the window's current aspect ratio.
        */
        let scaledSize = CGSize(width: size.width * camera.xScale, height: size.height * camera.yScale)

        /*
            Find the root "board" node in the scene (the container node for
            the level's background tiles).
        */
        let boardNode = childNode(withName: WorldLayer.board.nodePath)!
        
        /*
            Calculate the accumulated frame of this node.
            The accumulated frame of a node is the outer bounds of all of the node's
            child nodes, i.e. the total size of the entire contents of the node.
            This gives us the bounding rectangle for the level's environment.
        */
        let boardContentRect = boardNode.calculateAccumulatedFrame()

        /*
            Work out how far within this rectangle to constrain the camera.
            We want to stop the camera when we get within 100pts of the edge of the screen,
            unless the level is so small that this inset would be outside of the level.
        */
        let xInset = min((scaledSize.width / 2) - 100.0, boardContentRect.width / 2)
        let yInset = min((scaledSize.height / 2) - 100.0, boardContentRect.height / 2)
        
        // Use these insets to create a smaller inset rectangle within which the camera must stay.
        let insetContentRect = boardContentRect.insetBy(dx: xInset, dy: yInset)
        
        // Define an `SKRange` for each of the x and y axes to stay within the inset rectangle.
        let xRange = SKRange(lowerLimit: insetContentRect.minX, upperLimit: insetContentRect.maxX)
        let yRange = SKRange(lowerLimit: insetContentRect.minY, upperLimit: insetContentRect.maxY)
        
        // Constrain the camera within the inset rectangle.
        let levelEdgeConstraint = SKConstraint.positionX(xRange, y: yRange)
        levelEdgeConstraint.referenceNode = boardNode
        
        /*
            Add both constraints to the camera. The scene edge constraint is added
            second, so that it takes precedence over following the `PlayerBot`.
            The result is that the camera will follow the player, unless this would mean
            moving too close to the edge of the level.
        */
        camera.constraints = [playerBotLocationConstraint, levelEdgeConstraint]
    }
    
    /// Scales and positions the timer node to fit the scene's current height.
    private func scaleTimerNode() {
        // Update the font size of the timer node based on the height of the scene.
        timerNode.fontSize = size.height * GameplayConfiguration.Timer.fontSize
        
        // Make sure the timer node is positioned at the top of the scene.
        timerNode.position.y = size.height / 2.0
        
        // Add padding between the top of scene and the top of the timer node.
        #if os(tvOS)
        timerNode.position.y -= GameplayConfiguration.Timer.paddingSize
        #else
        timerNode.position.y -= GameplayConfiguration.Timer.paddingSize * timerNode.fontSize
        #endif
    }
    
    private func beamInPlayerBot() {
        // Find the location of the player's initial position.
        let charactersNode = childNode(withName: WorldLayer.characters.nodePath)!
        let transporterCoordinate = charactersNode.childNode(withName: "transporter_coordinate")!
        
        // Set the initial orientation.
        guard let orientationComponent = playerBot.component(ofType: OrientationComponent.self) else {
            fatalError("A player bot must have an orientation component to be able to be added to a level")
        }
        orientationComponent.compassDirection = levelConfiguration.initialPlayerBotOrientation

        // Set up the `PlayerBot` position in the scene.
        let playerNode = playerBot.renderComponent.node
        playerNode.position = transporterCoordinate.position
        playerBot.updateAgentPositionToMatchNodePosition()
        
        // Constrain the camera to the `PlayerBot` position and the level edges.
        setCameraConstraints()
        
        // Add the `PlayerBot` to the scene and component systems.
        addEntity(entity: playerBot)
    }
  
}

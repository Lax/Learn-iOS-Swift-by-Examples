/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKEntity` subclass that represents the player-controlled protagonist of DemoBots. This subclass allows for convenient construction of a new entity with appropriate `GKComponent` instances.
*/

import SpriteKit
import GameplayKit

class PlayerBot: GKEntity, ChargeComponentDelegate, ResourceLoadableType {
    // MARK: Static properties
    
    /// The size to use for the `PlayerBot`s animation textures.
    static var textureSize = CGSize(width: 120.0, height: 120.0)
    
    /// The size to use for the `PlayerBot`'s shadow texture.
    static var shadowSize = CGSize(width: 90.0, height: 40.0)
    
    /// The actual texture to use for the `PlayerBot`'s shadow.
    static var shadowTexture: SKTexture = {
        let shadowAtlas = SKTextureAtlas(named: "Shadows")
        return shadowAtlas.textureNamed("PlayerBotShadow")
    }()
    
    /// The offset of the `PlayerBot`'s shadow from its center position.
    static var shadowOffset = CGPoint(x: 0.0, y: -40.0)
    
    /// The animations to use for a `PlayerBot`.
    static var animations: [AnimationState: [CompassDirection: Animation]]?

    /// Textures used by `PlayerBotAppearState` to show a `PlayerBot` appearing in the scene.
    static var appearTextures: [CompassDirection: SKTexture]?
    
    /// Provides a "teleport" effect shader for when the `PlayerBot` first appears on a level.
    static var teleportShader: SKShader!
    
    // MARK: Properties
    
    var isPoweredDown = false
    
    /// The agent used when pathfinding to the `PlayerBot`.
    let agent: GKAgent2D

    /**
        A `PlayerBot` is only targetable when it is actively being controlled by a player or is taking damage.
        It is not targetable when appearing or recharging.
    */
    var isTargetable: Bool {
        guard let currentState = component(ofType: IntelligenceComponent.self)?.stateMachine.currentState else { return false }

        switch currentState {
            case is PlayerBotPlayerControlledState, is PlayerBotHitState:
                return true
            
            default:
                return false
        }
    }
    
    /// Used to determine the location on the `PlayerBot` where the beam starts.
    var antennaOffset = GameplayConfiguration.PlayerBot.antennaOffset
    
    /// The `RenderComponent` associated with this `PlayerBot`.
    var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else { fatalError("A PlayerBot must have an RenderComponent.") }
        return renderComponent
    }

    // MARK: Initializers
    
    override init() {
        agent = GKAgent2D()
        agent.radius = GameplayConfiguration.PlayerBot.agentRadius
        
        super.init()
        
        /*
            Add the `RenderComponent` before creating the `IntelligenceComponent` states,
            so that they have the render node available to them when first entered
            (e.g. so that `PlayerBotAppearState` can add a shader to the render node).
        */
        let renderComponent = RenderComponent()
        addComponent(renderComponent)
        
        let orientationComponent = OrientationComponent()
        addComponent(orientationComponent)

        let shadowComponent = ShadowComponent(texture: PlayerBot.shadowTexture, size: PlayerBot.shadowSize, offset: PlayerBot.shadowOffset)
        addComponent(shadowComponent)
        
        let inputComponent = InputComponent()
        addComponent(inputComponent)

        // `PhysicsComponent` provides the `PlayerBot`'s physics body and collision masks.
        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: GameplayConfiguration.PlayerBot.physicsBodyRadius, center: GameplayConfiguration.PlayerBot.physicsBodyOffset), colliderType: .PlayerBot)
        addComponent(physicsComponent)

        // Connect the `PhysicsComponent` and the `RenderComponent`.
        renderComponent.node.physicsBody = physicsComponent.physicsBody
        
        // `MovementComponent` manages the movement of a `PhysicalEntity` in 2D space, and chooses appropriate movement animations.
        let movementComponent = MovementComponent()
        addComponent(movementComponent)
        
        // `ChargeComponent` manages the `PlayerBot`'s charge (i.e. health).
        let chargeComponent = ChargeComponent(charge: GameplayConfiguration.PlayerBot.initialCharge, maximumCharge: GameplayConfiguration.PlayerBot.maximumCharge, displaysChargeBar: true)
        chargeComponent.delegate = self
        addComponent(chargeComponent)
        
        // `AnimationComponent` tracks and vends the animations for different entity states and directions.
        guard let animations = PlayerBot.animations else {
            fatalError("Attempt to access PlayerBot.animations before they have been loaded.")
        }
        let animationComponent = AnimationComponent(textureSize: PlayerBot.textureSize, animations: animations)
        addComponent(animationComponent)
        
        // Connect the `RenderComponent` and `ShadowComponent` to the `AnimationComponent`.
        renderComponent.node.addChild(animationComponent.node)
        animationComponent.shadowNode = shadowComponent.node
        
        // `BeamComponent` implements the beam that a `PlayerBot` fires at "bad" `TaskBot`s.
        let beamComponent = BeamComponent()
        addComponent(beamComponent)
        
        let intelligenceComponent = IntelligenceComponent(states: [
            PlayerBotAppearState(entity: self),
            PlayerBotPlayerControlledState(entity: self),
            PlayerBotHitState(entity: self),
            PlayerBotRechargingState(entity: self)
        ])
        addComponent(intelligenceComponent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Charge component delegate
    
    func chargeComponentDidLoseCharge(chargeComponent: ChargeComponent) {
        if let intelligenceComponent = component(ofType: IntelligenceComponent.self) {
            if !chargeComponent.hasCharge {
                isPoweredDown = true
                intelligenceComponent.stateMachine.enter(PlayerBotRechargingState.self)
            }
            else {
                intelligenceComponent.stateMachine.enter(PlayerBotHitState.self)
            }
        }
    }
    
    // MARK: ResourceLoadableType
    
    static var resourcesNeedLoading: Bool {
        return appearTextures == nil || animations == nil
    }
    
    static func loadResources(withCompletionHandler completionHandler: @escaping () -> ()) {
        loadMiscellaneousAssets()
        
        let playerBotAtlasNames = [
            "PlayerBotIdle",
            "PlayerBotWalk",
            "PlayerBotInactive",
            "PlayerBotHit"
        ]
        
        /*
            Preload all of the texture atlases for `PlayerBot`. This improves
            the overall loading speed of the animation cycles for this character.
        */
        SKTextureAtlas.preloadTextureAtlasesNamed(playerBotAtlasNames) { error, playerBotAtlases in
            if let error = error {
                fatalError("One or more texture atlases could not be found: \(error)")
            }

            /*
                This closure sets up all of the `PlayerBot` animations
                after the `PlayerBot` texture atlases have finished preloading.

                Store the first texture from each direction of the `PlayerBot`'s idle animation,
                for use in the `PlayerBot`'s "appear"  state.
            */
            appearTextures = [:]
            for orientation in CompassDirection.allDirections {
                appearTextures![orientation] = AnimationComponent.firstTextureForOrientation(compassDirection: orientation, inAtlas: playerBotAtlases[0], withImageIdentifier: "PlayerBotIdle")
            }
            
            // Set up all of the `PlayerBot`s animations.
            animations = [:]
            animations![.idle] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[0], withImageIdentifier: "PlayerBotIdle", forAnimationState: .idle)
            animations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[1], withImageIdentifier: "PlayerBotWalk", forAnimationState: .walkForward)
            animations![.walkBackward] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[1], withImageIdentifier: "PlayerBotWalk", forAnimationState: .walkBackward, playBackwards: true)
            animations![.inactive] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[2], withImageIdentifier: "PlayerBotInactive", forAnimationState: .inactive)
            animations![.hit] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[3], withImageIdentifier: "PlayerBotHit", forAnimationState: .hit, repeatTexturesForever: false)
            
            // Invoke the passed `completionHandler` to indicate that loading has completed.
            completionHandler()
        }
    }
    
    static func purgeResources() {
        appearTextures = nil
        animations = nil
    }
    
    class func loadMiscellaneousAssets() {
        teleportShader = SKShader(fileNamed: "Teleport.fsh")
        teleportShader.addUniform(SKUniform(name: "u_duration", float: Float(GameplayConfiguration.PlayerBot.appearDuration)))
        
        ColliderType.definedCollisions[.PlayerBot] = [
            .PlayerBot,
            .TaskBot,
            .Obstacle
        ]
    }

    // MARK: Convenience
    
    /// Sets the `PlayerBot` `GKAgent` position to match the node position (plus an offset).
    func updateAgentPositionToMatchNodePosition() {
        // `renderComponent` is a computed property. Declare a local version so we don't compute it multiple times.
        let renderComponent = self.renderComponent
        
        let agentOffset = GameplayConfiguration.PlayerBot.agentOffset
        agent.position = float2(x: Float(renderComponent.node.position.x + agentOffset.x), y: Float(renderComponent.node.position.y + agentOffset.y))
    }
}

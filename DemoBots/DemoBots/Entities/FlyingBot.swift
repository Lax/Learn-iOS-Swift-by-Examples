/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A floating `TaskBot` with a radius blast attack. This `GKEntity` subclass allows for convenient construction of an entity with appropriate `GKComponent` instances.
*/

import SpriteKit
import GameplayKit

class FlyingBot: TaskBot, ChargeComponentDelegate, ResourceLoadableType {
    // MARK: Static Properties
    
    /// The size to use for the `FlyingBot`s animation textures.
    static var textureSize = CGSize(width: 144.0, height: 144.0)
    
    /// The size to use for the `FlyingBot`'s shadow texture.
    static var shadowSize = CGSize(width: 60.0, height: 27.0)
    
    /// The actual texture to use for the `FlyingBot`'s shadow.
    static var shadowTexture: SKTexture = {
        let shadowAtlas = SKTextureAtlas(named: "Shadows")
        return shadowAtlas.textureNamed("FlyingBotShadow")
    }()

    /// The offset of the `FlyingBot`'s shadow from its center position.
    static var shadowOffset = CGPoint(x: 0.0, y: -58.0)

    /// The animations to use when a `FlyingBot` is in its "good" state.
    static var goodAnimations: [AnimationState: [CompassDirection: Animation]]?

    /// The animations to use when a `FlyingBot` is in its "bad" state.
    static var badAnimations: [AnimationState: [CompassDirection: Animation]]?

    // MARK: TaskBot Properties
    
    override var goodAnimations: [AnimationState: [CompassDirection: Animation]] {
        return FlyingBot.goodAnimations!
    }
    
    override var badAnimations: [AnimationState: [CompassDirection: Animation]] {
        return FlyingBot.badAnimations!
    }
    
    // MARK: Initialization

    required init(isGood: Bool, goodPathPoints: [CGPoint], badPathPoints: [CGPoint]) {
        super.init(isGood: isGood, goodPathPoints: goodPathPoints, badPathPoints: badPathPoints)

        // Determine initial animations and charge based on the initial state of the bot.
        let initialAnimations: [AnimationState: [CompassDirection: Animation]]
        let initialCharge: Double

        if isGood {
            guard let goodAnimations = FlyingBot.goodAnimations else {
                fatalError("Attempt to access FlyingBot.goodAnimations before they have been loaded.")
            }
            initialAnimations = goodAnimations
            initialCharge = 0.0
        }
        else {
            guard let badAnimations = FlyingBot.badAnimations else {
                fatalError("Attempt to access FlyingBot.badAnimations before they have been loaded.")
            }
            initialAnimations = badAnimations
            initialCharge = GameplayConfiguration.FlyingBot.maximumCharge
        }

        // Create components that define how the entity looks and behaves.
        let renderComponent = RenderComponent(entity: self)
        addComponent(renderComponent)

        let orientationComponent = OrientationComponent()
        addComponent(orientationComponent)

        let shadowComponent = ShadowComponent(texture: FlyingBot.shadowTexture, size: FlyingBot.shadowSize, offset: FlyingBot.shadowOffset)
        addComponent(shadowComponent)

        let animationComponent = AnimationComponent(textureSize: FlyingBot.textureSize, animations: initialAnimations)
        addComponent(animationComponent)

        let intelligenceComponent = IntelligenceComponent(states: [
            TaskBotAgentControlledState(entity: self),
            FlyingBotPreAttackState(entity: self),
            FlyingBotBlastState(entity: self),
            TaskBotZappedState(entity: self)
        ])
        addComponent(intelligenceComponent)

        let physicsBody = SKPhysicsBody(circleOfRadius: GameplayConfiguration.TaskBot.physicsBodyRadius, center: GameplayConfiguration.TaskBot.physicsBodyOffset)
        let physicsComponent = PhysicsComponent(physicsBody: physicsBody, colliderType: .TaskBot)
        addComponent(physicsComponent)
        
        let chargeComponent = ChargeComponent(charge: initialCharge, maximumCharge: GameplayConfiguration.FlyingBot.maximumCharge)
        chargeComponent.delegate = self
        addComponent(chargeComponent)

        // Connect the `PhysicsComponent` and the `RenderComponent`.
        renderComponent.node.physicsBody = physicsComponent.physicsBody
        
        // Connect the `RenderComponent` and `ShadowComponent` to the `AnimationComponent`.
        renderComponent.node.addChild(animationComponent.node)
        animationComponent.shadowNode = shadowComponent.node
        
        // Specify the offset for beam targeting.
        beamTargetOffset = GameplayConfiguration.FlyingBot.beamTargetOffset
    }
    
    // MARK: ContactableType

    override func contactWithEntityDidBegin(entity: GKEntity) {
        super.contactWithEntityDidBegin(entity)
        
        guard !isGood else { return }

        var shouldStartAttack = false
        
        if let otherTaskBot = entity as? TaskBot where otherTaskBot.isGood {
            // Contact with good task bot will trigger an attack.
            shouldStartAttack = true
        }
        else if let playerBot = entity as? PlayerBot where !playerBot.isPoweredDown {
            // Contact with an active `PlayerBot` will trigger an attack.
            shouldStartAttack = true
        }
        
        if let stateMachine = componentForClass(IntelligenceComponent)?.stateMachine where shouldStartAttack {
            stateMachine.enterState(FlyingBotPreAttackState.self)
        }
    }
    
    // MARK: ChargeComponentDelegate
    
    func chargeComponentDidLoseCharge(chargeComponent: ChargeComponent) {
        guard let intelligenceComponent = componentForClass(IntelligenceComponent) else { return }
        
        intelligenceComponent.stateMachine.enterState(TaskBotZappedState.self)
        isGood = !chargeComponent.hasCharge
    }
    
    // MARK: ResourceLoadableType
    
    static var resourcesNeedLoading: Bool {
        return goodAnimations == nil || badAnimations == nil
    }
    
    static func loadResourcesWithCompletionHandler(completionHandler: () -> ()) {        
        // Load `TaskBot`s shared assets.
        super.loadSharedAssets()
        
        let flyingBotAtlasNames = [
            "FlyingBotGoodWalk",
            "FlyingBotGoodAttack",
            "FlyingBotBadWalk",
            "FlyingBotBadAttack",
            "FlyingBotZapped"
        ]
        
        /*
            Preload all of the texture atlases for `FlyingBot`. This improves
            the overall loading speed of the animation cycles for this character.
        */
        SKTextureAtlas.preloadTextureAtlasesNamed(flyingBotAtlasNames) { error, flyingBotAtlases in
            if let error = error {
                fatalError("One or more texture atlases could not be found: \(error)")
            }
            /*
                This closure sets up all of the `FlyingBot` animations
                after the `FlyingBot` texture atlases have finished preloading.
            */
            goodAnimations = [:]
            goodAnimations![.WalkForward] = AnimationComponent.animationsFromAtlas(flyingBotAtlases[0], withImageIdentifier: "FlyingBotGoodWalk", forAnimationState: .WalkForward, bodyActionName: "FlyingBotBob", shadowActionName: "FlyingBotShadowScale")
            goodAnimations![.Attack] = AnimationComponent.animationsFromAtlas(flyingBotAtlases[1], withImageIdentifier: "FlyingBotGoodAttack", forAnimationState: .Attack, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake")
            
            badAnimations = [:]
            badAnimations![.WalkForward] = AnimationComponent.animationsFromAtlas(flyingBotAtlases[2], withImageIdentifier: "FlyingBotBadWalk", forAnimationState: .WalkForward, bodyActionName: "FlyingBotBob", shadowActionName: "FlyingBotShadowScale")
            badAnimations![.Attack] = AnimationComponent.animationsFromAtlas(flyingBotAtlases[3], withImageIdentifier: "FlyingBotBadAttack", forAnimationState: .Attack, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake")
            badAnimations![.Zapped] = AnimationComponent.animationsFromAtlas(flyingBotAtlases[4], withImageIdentifier: "FlyingBotZapped", forAnimationState: .Zapped, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake")
            
            // Invoke the passed `completionHandler` to indicate that loading has completed.
            completionHandler()
        }
    }
    
    static func purgeResources() {
        goodAnimations = nil
        badAnimations = nil
    }
}

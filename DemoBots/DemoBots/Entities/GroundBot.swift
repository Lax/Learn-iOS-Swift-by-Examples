/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A ground-based `TaskBot` with a distance attack. This `GKEntity` subclass allows for convenient construction of an entity with appropriate `GKComponent` instances.
*/

import SpriteKit
import GameplayKit

class GroundBot: TaskBot, ChargeComponentDelegate, ResourceLoadableType {
    // MARK: Static Properties
    
    /// The size to use for the `GroundBot`s animation textures.
    static var textureSize = CGSize(width: 120.0, height: 120.0)
    
    /// The size to use for the `GroundBot`'s shadow texture.
    static var shadowSize = CGSize(width: 90.0, height: 40.0)
    
    /// The actual texture to use for the `GroundBot`'s shadow.
    static var shadowTexture: SKTexture = {
        let shadowAtlas = SKTextureAtlas(named: "Shadows")
        return shadowAtlas.textureNamed("GroundBotShadow")
    }()
    
    /// The offset of the `GroundBot`'s shadow from its center position.
    static var shadowOffset = CGPoint(x: 0.0, y: -40.0)
    
    /// The animations to use when a `GroundBot` is in its "good" state.
    static var goodAnimations: [AnimationState: [CompassDirection: Animation]]?
    
    /// The animations to use when a `GroundBot` is in its "bad" state.
    static var badAnimations: [AnimationState: [CompassDirection: Animation]]?
    
    // MARK: TaskBot Properties
    
    override var goodAnimations: [AnimationState: [CompassDirection: Animation]] {
        return GroundBot.goodAnimations!
    }
    
    override var badAnimations: [AnimationState: [CompassDirection: Animation]] {
        return GroundBot.badAnimations!
    }
    
    // MARK: GroundBot Properties
    
    /// The position in the scene that the `GroundBot` should target with its attack.
    var targetPosition: float2?
    
    // MARK: Initialization

    required init(isGood: Bool, goodPathPoints: [CGPoint], badPathPoints: [CGPoint]) {
        super.init(isGood: isGood, goodPathPoints: goodPathPoints, badPathPoints: badPathPoints)
        
        // Determine initial animations and charge based on the initial state of the bot.
        let initialAnimations: [AnimationState: [CompassDirection: Animation]]
        let initialCharge: Double

        if isGood {
            guard let goodAnimations = GroundBot.goodAnimations else {
                fatalError("Attempt to access GroundBot.goodAnimations before they have been loaded.")
            }
            initialAnimations = goodAnimations
            initialCharge = 0.0
        }
        else {
            guard let badAnimations = GroundBot.badAnimations else {
                fatalError("Attempt to access GroundBot.badAnimations before they have been loaded.")
            }
            initialAnimations = badAnimations
            initialCharge = GameplayConfiguration.GroundBot.maximumCharge
        }
        
        // Create components that define how the entity looks and behaves.
        let renderComponent = RenderComponent()
        addComponent(renderComponent)

        let orientationComponent = OrientationComponent()
        addComponent(orientationComponent)

        let shadowComponent = ShadowComponent(texture: GroundBot.shadowTexture, size: GroundBot.shadowSize, offset: GroundBot.shadowOffset)
        addComponent(shadowComponent)
        
        let animationComponent = AnimationComponent(textureSize: GroundBot.textureSize, animations: initialAnimations)
        addComponent(animationComponent)

        let intelligenceComponent = IntelligenceComponent(states: [
            TaskBotAgentControlledState(entity: self),
            GroundBotRotateToAttackState(entity: self),
            GroundBotPreAttackState(entity: self),
            GroundBotAttackState(entity: self),
            TaskBotZappedState(entity: self)
        ])
        addComponent(intelligenceComponent)

        let physicsBody = SKPhysicsBody(circleOfRadius: GameplayConfiguration.TaskBot.physicsBodyRadius, center: GameplayConfiguration.TaskBot.physicsBodyOffset)
        let physicsComponent = PhysicsComponent(physicsBody: physicsBody, colliderType: .TaskBot)
        addComponent(physicsComponent)
        
        let chargeComponent = ChargeComponent(charge: initialCharge, maximumCharge: GameplayConfiguration.GroundBot.maximumCharge)
        chargeComponent.delegate = self
        addComponent(chargeComponent)
        
        let movementComponent = MovementComponent()
        addComponent(movementComponent)

        // Connect the `PhysicsComponent` and the `RenderComponent`.
        renderComponent.node.physicsBody = physicsComponent.physicsBody

        // Connect the `RenderComponent` and `ShadowComponent` to the `AnimationComponent`.
        renderComponent.node.addChild(animationComponent.node)
        animationComponent.shadowNode = shadowComponent.node

        // Specify the offset for beam targeting.
        beamTargetOffset = GameplayConfiguration.GroundBot.beamTargetOffset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: ContactableType
    
    override func contactWithEntityDidBegin(_ entity: GKEntity) {
        super.contactWithEntityDidBegin(entity)
        
        // Retrieve the current state from this `GroundBot` as a `GroundBotAttackState`.
        guard let attackState = component(ofType: IntelligenceComponent.self)?.stateMachine.currentState as? GroundBotAttackState else { return }
        
        // Use the `GroundBotAttackState` to apply the appropriate damage to the contacted entity.
        attackState.applyDamageToEntity(entity: entity)
    }
    
    // MARK: RulesComponentDelegate
    
    override func rulesComponent(rulesComponent: RulesComponent, didFinishEvaluatingRuleSystem ruleSystem: GKRuleSystem) {
        super.rulesComponent(rulesComponent: rulesComponent, didFinishEvaluatingRuleSystem: ruleSystem)

        /*
            A `GroundBot` will attack a location in the scene if the following conditions are met:
                1) Enough time has elapsed since the `GroundBot` last attacked a target.
                2) The `GroundBot` is hunting a target.
                3) The target is within the `GroundBot`'s attack range.
                4) There is no scenery between the `GroundBot` and the target.
        */
        guard let scene = component(ofType: RenderComponent.self)?.node.scene else { return }
        guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else { return }
        guard let agentControlledState = intelligenceComponent.stateMachine.currentState as? TaskBotAgentControlledState else { return }

        // 1) Check if enough time has passed since the `GroundBot`'s last attack.
        guard agentControlledState.elapsedTime >= GameplayConfiguration.GroundBot.delayBetweenAttacks else { return }
        
        // 2) Check if the current mandate is to hunt an agent.
        guard case let .huntAgent(targetAgent) = mandate else { return }
        
        // 3) Check if the target is within the `GroundBot`'s attack range.
        guard distanceToAgent(otherAgent: targetAgent) <= GameplayConfiguration.GroundBot.maximumAttackDistance else { return }
        
        // 4) Check if any walls or obstacles are between the `GroundBot` and its hunt target position.
        var hasLineOfSight = true
        
        scene.physicsWorld.enumerateBodies(alongRayStart: CGPoint(agent.position), end: CGPoint(targetAgent.position)) { body, _, _, stop in
            if ColliderType(rawValue: body.categoryBitMask).contains(.Obstacle) {
                hasLineOfSight = false
                stop.pointee = true
            }
        }
        
        if !hasLineOfSight { return }
        
        // The `GroundBot` is ready to attack the `targetAgent`'s current position.
        targetPosition = targetAgent.position
        intelligenceComponent.stateMachine.enter(GroundBotRotateToAttackState.self)
    }
    
    // MARK: ChargeComponentDelegate
    
    func chargeComponentDidLoseCharge(chargeComponent: ChargeComponent) {
        guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else { return }
        
        isGood = !chargeComponent.hasCharge
        
        if !isGood {
            intelligenceComponent.stateMachine.enter(TaskBotZappedState.self)
        }
    }
    
    // MARK: ResourceLoadableType
    
    static var resourcesNeedLoading: Bool {
        return goodAnimations == nil || badAnimations == nil
    }
    
    static func loadResources(withCompletionHandler completionHandler: @escaping () -> ()) {
        // Load `TaskBot`s shared assets.
        super.loadSharedAssets()

        let groundBotAtlasNames = [
            "GroundBotGoodWalk",
            "GroundBotBadWalk",
            "GroundBotAttack",
            "GroundBotZapped"
        ]
        
        /*
            Preload all of the texture atlases for `GroundBot`. This improves
            the overall loading speed of the animation cycles for this character.
        */
        SKTextureAtlas.preloadTextureAtlasesNamed(groundBotAtlasNames) { error, groundBotAtlases in
            if let error = error {
                fatalError("One or more texture atlases could not be found: \(error)")
            }

            /*
                This closure sets up all of the `GroundBot` animations
                after the `GroundBot` texture atlases have finished preloading.
            */
            goodAnimations = [:]
            goodAnimations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: groundBotAtlases[0], withImageIdentifier: "GroundBotGoodWalk", forAnimationState: .walkForward)
            
            badAnimations = [:]
            badAnimations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: groundBotAtlases[1], withImageIdentifier: "GroundBotBadWalk", forAnimationState: .walkForward)
            badAnimations![.attack] = AnimationComponent.animationsFromAtlas(atlas: groundBotAtlases[2], withImageIdentifier: "GroundBotAttack", forAnimationState: .attack, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake", repeatTexturesForever: false)
            badAnimations![.zapped] = AnimationComponent.animationsFromAtlas(atlas: groundBotAtlases[3], withImageIdentifier: "GroundBotZapped", forAnimationState: .zapped, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake")
            
            // Invoke the passed `completionHandler` to indicate that loading has completed.
            completionHandler()
        }
    }
    
    static func purgeResources() {
        goodAnimations = nil
        badAnimations = nil
    }
}

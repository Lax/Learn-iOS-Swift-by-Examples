/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKEntity` subclass that provides a base class for `GroundBot` and `FlyingBot`. This subclass allows for convenient construction of the common AI-related components shared by the game's antagonists.
*/

import SpriteKit
import GameplayKit

class TaskBot: GKEntity, ContactNotifiableType, GKAgentDelegate, RulesComponentDelegate {
    // MARK: Nested types
    
    /// Encapsulates a `TaskBot`'s current mandate, i.e. the aim that the `TaskBot` is setting out to achieve.
    enum TaskBotMandate {
        // Hunt another agent (either a `PlayerBot` or a "good" `TaskBot`).
        case huntAgent(GKAgent2D)

        // Follow the `TaskBot`'s "good" patrol path.
        case followGoodPatrolPath

        // Follow the `TaskBot`'s "bad" patrol path.
        case followBadPatrolPath

        // Return to a given position on a patrol path.
        case returnToPositionOnPath(float2)
    }

    // MARK: Properties
    
    /// Indicates whether or not the `TaskBot` is currently in a "good" (benevolent) or "bad" (adversarial) state.
    var isGood: Bool {
        didSet {
            // Do nothing if the value hasn't changed.
            guard isGood != oldValue else { return }
            
            // Get the components we will need to access in response to the value changing.
            guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else { fatalError("TaskBots must have an intelligence component.") }
            guard let animationComponent = component(ofType: AnimationComponent.self) else { fatalError("TaskBots must have an animation component.") }
            guard let chargeComponent = component(ofType: ChargeComponent.self) else { fatalError("TaskBots must have a charge component.") }

            // Update the `TaskBot`'s speed and acceleration to suit the new value of `isGood`.
            agent.maxSpeed = GameplayConfiguration.TaskBot.maximumSpeedForIsGood(isGood: isGood)
            agent.maxAcceleration = GameplayConfiguration.TaskBot.maximumAcceleration

            if isGood {
                /*
                    The `TaskBot` just turned from "bad" to "good".
                    Set its mandate to `.ReturnToPositionOnPath` for the closest point on its "good" patrol path.
                */
                let closestPointOnGoodPath = closestPointOnPath(path: goodPathPoints)
                mandate = .returnToPositionOnPath(float2(closestPointOnGoodPath))
                
                if self is FlyingBot {
                    // Enter the `FlyingBotBlastState` so it performs a curing blast.
                    intelligenceComponent.stateMachine.enter(FlyingBotBlastState.self)
                }
                else {
                    // Make sure the `TaskBot`s state is `TaskBotAgentControlledState` so that it follows its mandate.
                    intelligenceComponent.stateMachine.enter(TaskBotAgentControlledState.self)
                }
                
                // Update the animation component to use the "good" animations.
                animationComponent.animations = goodAnimations
                
                // Set the appropriate amount of charge.
                chargeComponent.charge = 0.0
            }
            else {
                /*
                    The `TaskBot` just turned from "good" to "bad".
                    Default to a `.ReturnToPositionOnPath` mandate for the closest point on its "bad" patrol path.
                    This may be overridden by a `.HuntAgent` mandate when the `TaskBot`'s rules are next evaluated.
                */
                let closestPointOnBadPath = closestPointOnPath(path: badPathPoints)
                mandate = .returnToPositionOnPath(float2(closestPointOnBadPath))
                
                // Update the animation component to use the "bad" animations.
                animationComponent.animations = badAnimations
                
                // Set the appropriate amount of charge.
                chargeComponent.charge = chargeComponent.maximumCharge
                
                // Enter the "zapped" state.
                intelligenceComponent.stateMachine.enter(TaskBotZappedState.self)
            }
        }
    }
    
    /// The aim that the `TaskBot` is currently trying to achieve.
    var mandate: TaskBotMandate
    
    /// The points for the path that the `TaskBot` should patrol when "good" and not hunting.
    var goodPathPoints: [CGPoint]

    /// The points for the path that the `TaskBot` should patrol when "bad" and not hunting.
    var badPathPoints: [CGPoint]

    /// The appropriate `GKBehavior` for the `TaskBot`, based on its current `mandate`.
    var behaviorForCurrentMandate: GKBehavior {
        // Return an empty behavior if this `TaskBot` is not yet in a `LevelScene`.
        guard let levelScene = component(ofType: RenderComponent.self)?.node.scene as? LevelScene else {
            return GKBehavior()
        }

        let agentBehavior: GKBehavior
        let radius: Float
            
        // `debugPathPoints`, `debugPathShouldCycle`, and `debugColor` are only used when debug drawing is enabled.
        let debugPathPoints: [CGPoint]
        var debugPathShouldCycle = false
        let debugColor: SKColor
        
        switch mandate {
            case .followGoodPatrolPath, .followBadPatrolPath:
                let pathPoints = isGood ? goodPathPoints : badPathPoints
                radius = GameplayConfiguration.TaskBot.patrolPathRadius
                agentBehavior = TaskBotBehavior.behavior(forAgent: agent, patrollingPathWithPoints: pathPoints, pathRadius: radius, inScene: levelScene)
                debugPathPoints = pathPoints
                // Patrol paths are always closed loops, so the debug drawing of the path should cycle back round to the start.
                debugPathShouldCycle = true
                debugColor = isGood ? SKColor.green : SKColor.purple
            
            case let .huntAgent(targetAgent):
                radius = GameplayConfiguration.TaskBot.huntPathRadius
                (agentBehavior, debugPathPoints) = TaskBotBehavior.behaviorAndPathPoints(forAgent: agent, huntingAgent: targetAgent, pathRadius: radius, inScene: levelScene)
                debugColor = SKColor.red

            case let .returnToPositionOnPath(position):
                radius = GameplayConfiguration.TaskBot.returnToPatrolPathRadius
                (agentBehavior, debugPathPoints) = TaskBotBehavior.behaviorAndPathPoints(forAgent: agent, returningToPoint: position, pathRadius: radius, inScene: levelScene)
                debugColor = SKColor.yellow
        }

        if levelScene.debugDrawingEnabled {
            drawDebugPath(path: debugPathPoints, cycle: debugPathShouldCycle, color: debugColor, radius: radius)
        }
        else {
            debugNode.removeAllChildren()
        }

        return agentBehavior
    }
    
    /// The animations to use when a `TaskBot` is in its "good" state.
    var goodAnimations: [AnimationState: [CompassDirection: Animation]] {
        fatalError("goodAnimations must be overridden in subclasses")
    }
    
    /// The animations to use when a `TaskBot` is in its "bad" state.
    var badAnimations: [AnimationState: [CompassDirection: Animation]] {
        fatalError("badAnimations must be overridden in subclasses")
    }
    
    /// The `GKAgent` associated with this `TaskBot`.
    var agent: TaskBotAgent {
        guard let agent = component(ofType: TaskBotAgent.self) else { fatalError("A TaskBot entity must have a GKAgent2D component.") }
        return agent
    }

    /// The `RenderComponent` associated with this `TaskBot`.
    var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else { fatalError("A TaskBot must have an RenderComponent.") }
        return renderComponent
    }
    
    /// Used to determine the location on the `TaskBot` where contact with the debug beam occurs.
    var beamTargetOffset = CGPoint.zero
    
    /// Used to hang shapes representing the current path for the `TaskBot`.
    var debugNode = SKNode()
    
    // MARK: Initializers
    
    required init(isGood: Bool, goodPathPoints: [CGPoint], badPathPoints: [CGPoint]) {
        // Whether or not the `TaskBot` is "good" when first created.
        self.isGood = isGood

        // The locations of the points that define the `TaskBot`'s "good" and "bad" patrol paths.
        self.goodPathPoints = goodPathPoints
        self.badPathPoints = badPathPoints
        
        /*
            A `TaskBot`'s initial mandate is always to patrol.
            Because a `TaskBot` is positioned at the appropriate path's start point when the level is created,
            there is no need for it to pathfind to the start of its path, and it can patrol immediately.
        */
        mandate = isGood ? .followGoodPatrolPath : .followBadPatrolPath

        super.init()

        // Create a `TaskBotAgent` to represent this `TaskBot` in a steering physics simulation.
        let agent = TaskBotAgent()
        agent.delegate = self
        
        // Configure the agent's characteristics for the steering physics simulation.
        agent.maxSpeed = GameplayConfiguration.TaskBot.maximumSpeedForIsGood(isGood: isGood)
        agent.maxAcceleration = GameplayConfiguration.TaskBot.maximumAcceleration
        agent.mass = GameplayConfiguration.TaskBot.agentMass
        agent.radius = GameplayConfiguration.TaskBot.agentRadius
        agent.behavior = GKBehavior()
        
        /*
            `GKAgent2D` is a `GKComponent` subclass.
            Add it to the `TaskBot` entity's list of components so that it will be updated
            on each component update cycle.
        */
        addComponent(agent)

        // Create and add a rules component to encapsulate all of the rules that can affect a `TaskBot`'s behavior.
        let rulesComponent = RulesComponent(rules: [
            PlayerBotNearRule(),
            PlayerBotMediumRule(),
            PlayerBotFarRule(),
            GoodTaskBotNearRule(),
            GoodTaskBotMediumRule(),
            GoodTaskBotFarRule(),
            BadTaskBotPercentageLowRule(),
            BadTaskBotPercentageMediumRule(),
            BadTaskBotPercentageHighRule()
        ])
        addComponent(rulesComponent)
        rulesComponent.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: GKAgentDelegate
    
    func agentWillUpdate(_: GKAgent) {
        /*
            `GKAgent`s do not operate in the SpriteKit physics world,
            and are not affected by SpriteKit physics collisions.
            Because of this, the agent's position and rotation in the scene
            may have values that are not valid in the SpriteKit physics simulation.
            For example, the agent may have moved into a position that is not allowed
            by interactions between the `TaskBot`'s physics body and the level's scenery.
            To counter this, set the agent's position and rotation to match
            the `TaskBot` position and orientation before the agent calculates
            its steering physics update.
        */
        updateAgentPositionToMatchNodePosition()
        updateAgentRotationToMatchTaskBotOrientation()
    }
    
    func agentDidUpdate(_: GKAgent) {
        guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else { return }
        guard let orientationComponent = component(ofType: OrientationComponent.self) else { return }
        
        if intelligenceComponent.stateMachine.currentState is TaskBotAgentControlledState {
            
            // `TaskBot`s always move in a forward direction when they are agent-controlled.
            component(ofType: AnimationComponent.self)?.requestedAnimationState = .walkForward
            
            // When the `TaskBot` is agent-controlled, the node position follows the agent position.
            updateNodePositionToMatchAgentPosition()
            
            // If the agent has a velocity, the `zRotation` should be the arctangent of the agent's velocity. Otherwise use the agent's `rotation` value.
            let newRotation: Float
            if agent.velocity.x > 0.0 || agent.velocity.y > 0.0 {
                newRotation = atan2(agent.velocity.y, agent.velocity.x)
            }
            else {
                newRotation = agent.rotation
            }

            // Ensure we have a valid rotation.
            if newRotation.isNaN { return }

            orientationComponent.zRotation = CGFloat(newRotation)
        }
        else {
            /*
                When the `TaskBot` is not agent-controlled, the agent position
                and rotation follow the node position and `TaskBot` orientation.
            */
            updateAgentPositionToMatchNodePosition()
            updateAgentRotationToMatchTaskBotOrientation()
        }
    }
    
    // MARK: RulesComponentDelegate
    
    func rulesComponent(rulesComponent: RulesComponent, didFinishEvaluatingRuleSystem ruleSystem: GKRuleSystem) {
        let state = ruleSystem.state["snapshot"] as! EntitySnapshot
        
        // Adjust the `TaskBot`'s `mandate` based on the result of evaluating the rules.
        
        // A series of situations in which we prefer this `TaskBot` to hunt the player.
        let huntPlayerBotRaw = [
            // "Number of bad TaskBots is high" AND "Player is nearby".
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageHigh.rawValue as AnyObject,
                Fact.playerBotNear.rawValue as AnyObject
            ]),
            
            /*
                There are already a lot of bad `TaskBot`s on the level, and the
                player is nearby, so hunt the player.
            */
            
            // "Number of bad `TaskBot`s is medium" AND "Player is nearby".
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageMedium.rawValue as AnyObject,
                Fact.playerBotNear.rawValue as AnyObject
            ]),
            /*
                There are already a reasonable number of bad `TaskBots` on the level,
                and the player is nearby, so hunt the player.
            */
            
            /*
                "Number of bad TaskBots is high" AND "Player is at medium proximity"
                AND "nearest good `TaskBot` is at medium proximity".
            */
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageHigh.rawValue as AnyObject,
                Fact.playerBotMedium.rawValue as AnyObject,
                Fact.goodTaskBotMedium.rawValue as AnyObject
            ]),
            /* 
                There are already a lot of bad `TaskBot`s on the level, so even though
                both the player and the nearest good TaskBot are at medium proximity, 
                prefer the player for hunting.
            */
        ]

        // Find the maximum of the minima from above.
        let huntPlayerBot = huntPlayerBotRaw.reduce(0.0, max)

        // A series of situations in which we prefer this `TaskBot` to hunt the nearest "good" TaskBot.
        let huntTaskBotRaw = [
            
            // "Number of bad TaskBots is low" AND "Nearest good `TaskBot` is nearby".
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageLow.rawValue as AnyObject,
                Fact.goodTaskBotNear.rawValue as AnyObject
            ]),
            /*
                There are not many bad `TaskBot`s on the level, and a good `TaskBot`
                is nearby, so hunt the `TaskBot`.
            */

            // "Number of bad TaskBots is medium" AND "Nearest good TaskBot is nearby".
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageMedium.rawValue as AnyObject,
                Fact.goodTaskBotNear.rawValue as AnyObject
            ]),
            /* 
                There are a reasonable number of `TaskBot`s on the level, but a good
                `TaskBot` is nearby, so hunt the `TaskBot`.
            */

            /*
                "Number of bad TaskBots is low" AND "Player is at medium proximity"
                AND "Nearest good TaskBot is at medium proximity".
            */
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageLow.rawValue as AnyObject,
                Fact.playerBotMedium.rawValue as AnyObject,
                Fact.goodTaskBotMedium.rawValue as AnyObject
            ]),
            /*
                There are not many bad `TaskBot`s on the level, so even though both
                the player and the nearest good `TaskBot` are at medium proximity, 
                prefer the nearest good `TaskBot` for hunting.
            */

            /*
                "Number of bad `TaskBot`s is medium" AND "Player is far away" AND
                "Nearest good `TaskBot` is at medium proximity".
            */
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageMedium.rawValue as AnyObject,
                Fact.playerBotFar.rawValue as AnyObject,
                Fact.goodTaskBotMedium.rawValue as AnyObject
            ]),
            /*
                There are a reasonable number of bad `TaskBot`s on the level, the
                player is far away, and the nearest good `TaskBot` is at medium
                proximity, so prefer the nearest good `TaskBot` for hunting.
            */
        ]

        // Find the maximum of the minima from above.
        let huntTaskBot = huntTaskBotRaw.reduce(0.0, max)
        
        if huntPlayerBot >= huntTaskBot && huntPlayerBot > 0.0 {
            // The rules provided greater motivation to hunt the PlayerBot. Ignore any motivation to hunt the nearest good TaskBot.
            guard let playerBotAgent = state.playerBotTarget?.target.agent else { return }
            mandate = .huntAgent(playerBotAgent)
        }
        else if huntTaskBot > huntPlayerBot {
            // The rules provided greater motivation to hunt the nearest good TaskBot. Ignore any motivation to hunt the PlayerBot.
            mandate = .huntAgent(state.nearestGoodTaskBotTarget!.target.agent)
        }
        else {
            // The rules provided no motivation to hunt, so patrol in the "bad" state.
            switch mandate {
                case .followBadPatrolPath:
                    // The `TaskBot` is already on its "bad" patrol path, so no update is needed.
                    break
                default:
                    // Send the `TaskBot` to the closest point on its "bad" patrol path.
                    let closestPointOnBadPath = closestPointOnPath(path: badPathPoints)
                    mandate = .returnToPositionOnPath(float2(closestPointOnBadPath))
            }
        }
    }
    
    // MARK: ContactableType
    
    func contactWithEntityDidBegin(_ entity: GKEntity) {}

    func contactWithEntityDidEnd(_ entity: GKEntity) {}

    // MARK: Convenience
    
    /// The direct distance between this `TaskBot`'s agent and another agent in the scene.
    func distanceToAgent(otherAgent: GKAgent2D) -> Float {
        let deltaX = agent.position.x - otherAgent.position.x
        let deltaY = agent.position.y - otherAgent.position.y
        
        return hypot(deltaX, deltaY)
    }
    
    func distanceToPoint(otherPoint: float2) -> Float {
        let deltaX = agent.position.x - otherPoint.x
        let deltaY = agent.position.y - otherPoint.y
        
        return hypot(deltaX, deltaY)
    }
    
    func closestPointOnPath(path: [CGPoint]) -> CGPoint {
        // Find the closest point to the `TaskBot`.
        let taskBotPosition = agent.position
        let closestPoint = path.min {
            return distance_squared(taskBotPosition, float2($0)) < distance_squared(taskBotPosition, float2($1))
        }
    
        return closestPoint!
    }
    
    /// Sets the `TaskBot` `GKAgent` position to match the node position (plus an offset).
    func updateAgentPositionToMatchNodePosition() {
        // `renderComponent` is a computed property. Declare a local version so we don't compute it multiple times.
        let renderComponent = self.renderComponent
        
        let agentOffset = GameplayConfiguration.TaskBot.agentOffset
        agent.position = float2(x: Float(renderComponent.node.position.x + agentOffset.x), y: Float(renderComponent.node.position.y + agentOffset.y))
    }
    
    /// Sets the `TaskBot` `GKAgent` rotation to match the `TaskBot`'s orientation.
    func updateAgentRotationToMatchTaskBotOrientation() {
        guard let orientationComponent = component(ofType: OrientationComponent.self) else { return }
        agent.rotation = Float(orientationComponent.zRotation)
    }
    
    /// Sets the `TaskBot` node position to match the `GKAgent` position (minus an offset).
    func updateNodePositionToMatchAgentPosition() {
        // `agent` is a computed property. Declare a local version of its property so we don't compute it multiple times.
        let agentPosition = CGPoint(agent.position)
        
        let agentOffset = GameplayConfiguration.TaskBot.agentOffset
        renderComponent.node.position = CGPoint(x: agentPosition.x - agentOffset.x, y: agentPosition.y - agentOffset.y)
    }
    
    // MARK: Debug Path Drawing
    
    func drawDebugPath(path: [CGPoint], cycle: Bool, color: SKColor, radius: Float) {
        guard path.count > 1 else { return }
        
        debugNode.removeAllChildren()
        
        var drawPath = path
        
        if cycle {
            drawPath += [drawPath.first!]
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Use RGB component accessor common between `UIColor` and `NSColor`.
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let strokeColor = SKColor(red: red, green: green, blue: blue, alpha: 0.4)
        let fillColor = SKColor(red: red, green: green, blue: blue, alpha: 0.2)
        
        for index in 0..<drawPath.count - 1 {
            let current = CGPoint(x: drawPath[index].x, y: drawPath[index].y)
            let next = CGPoint(x: drawPath[index + 1].x, y: drawPath[index + 1].y)
            
            let circleNode = SKShapeNode(circleOfRadius: CGFloat(radius))
            circleNode.strokeColor = strokeColor
            circleNode.fillColor = fillColor
            circleNode.position = current
            debugNode.addChild(circleNode)

            let deltaX = next.x - current.x
            let deltaY = next.y - current.y
            let rectNode = SKShapeNode(rectOf: CGSize(width: hypot(deltaX, deltaY), height: CGFloat(radius) * 2))
            rectNode.strokeColor = strokeColor
            rectNode.fillColor = fillColor
            rectNode.zRotation = atan(deltaY / deltaX)
            rectNode.position = CGPoint(x: current.x + (deltaX / 2.0), y: current.y + (deltaY / 2.0))
            debugNode.addChild(rectNode)
        }
    }
    
    // MARK: Shared Assets
    
    class func loadSharedAssets() {
        ColliderType.definedCollisions[.TaskBot] = [
            .Obstacle,
            .PlayerBot,
            .TaskBot
        ]
        
        ColliderType.requestedContactNotifications[.TaskBot] = [
            .Obstacle,
            .PlayerBot,
            .TaskBot
        ]
    }
}

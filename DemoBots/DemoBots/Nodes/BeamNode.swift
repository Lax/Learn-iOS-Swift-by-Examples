/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An `SKNode` subclass used as a container for the visual components that make up a `PlayerBot`'s beam.
*/

import SpriteKit
import GameplayKit

class BeamNode: SKNode, ResourceLoadableType {
    // MARK: Static properties
    
    struct AnimationActions {
        static var source: SKAction!
        static var untargetedSource: SKAction!
        static var destination: SKAction!
        static var cooling: SKAction!
    }

    /// The size to use for the `BeamNode`'s dot animation textures.
    static var dotTextureSize = CGSize(width: 30.0, height: 30.0)

    static let animationActionKey = "Animation"

    static let lineNodeTemplate: SKSpriteNode = {
        let templateScene = SKScene(fileNamed: "BeamLine.sks")!
        return templateScene.childNodeWithName("BeamLine") as! SKSpriteNode
    }()

    // MARK: Properties
    
    let sourceNode: SKSpriteNode
    
    let destinationNode: SKSpriteNode

    var lineNode: SKSpriteNode?
    
    var runningNodeAnimations = [SKNode: SKAction]()

    let debugNode: SKShapeNode
    
    var debugDrawingEnabled = false

    // MARK: Initializers
    
    override init() {
        sourceNode = SKSpriteNode()
        sourceNode.size = BeamNode.dotTextureSize
        sourceNode.hidden = true
        
        destinationNode = SKSpriteNode()
        destinationNode.size = BeamNode.dotTextureSize
        destinationNode.hidden = true
        
        let arcPath = CGPathCreateMutable()
        CGPathAddArc(arcPath, nil, 0.0, 0.0, GameplayConfiguration.Beam.arcLength, GameplayConfiguration.Beam.arcAngle * 0.5, GameplayConfiguration.Beam.arcAngle * -0.5, true)
        CGPathAddLineToPoint(arcPath, nil, 0.0, 0.0)
        
        debugNode = SKShapeNode(path: arcPath)
        debugNode.fillColor = SKColor.blueColor()
        debugNode.lineWidth = 0.0
        debugNode.alpha = 0.5
        debugNode.hidden = true
        
        super.init()
        
        self.addChild(sourceNode)
        self.addChild(destinationNode)
        self.addChild(debugNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Actions
    
    func updateWithBeamState(state: GKState, source: PlayerBot, target: TaskBot? = nil) {
        // Constrain the position of the target's antenna if it's not already constrained to it.
        if let target = target, targetNode = target.componentForClass(RenderComponent.self)?.node where destinationNode.constraints?.first?.referenceNode != targetNode {
                let xRange = SKRange(constantValue: target.beamTargetOffset.x)
                let yRange = SKRange(constantValue: target.beamTargetOffset.y)
                
                let constraint = SKConstraint.positionX(xRange, y: yRange)
                constraint.referenceNode = targetNode
        
                destinationNode.constraints = [constraint]
        }
        
        switch state {
            case is BeamIdleState:
                // Hide the source and destination nodes.
                sourceNode.hidden = true
                destinationNode.hidden = true
                
                // Remove the `lineNode` from the scene.
                lineNode?.removeFromParent()
                lineNode = nil
                
                debugNode.hidden = true
            
            case is BeamFiringState:
                /*
                    If there is no `lineNode`, create one from the template node.
                    Adding a new copy of the template will ensure the actions are re-started when
                    the beam starts being fired.
                */
                if lineNode == nil {
                    lineNode = BeamNode.lineNodeTemplate.copy() as? SKSpriteNode
                    lineNode!.hidden = true
                    addChild(lineNode!)
                }
                
                if let target = target {
                    // Show the `sourceNode` with the its firing animation.
                    sourceNode.hidden = false
                    animateNode(sourceNode, withAction: AnimationActions.source)
                    
                    // Show the `destinationNode` with its animation.
                    destinationNode.hidden = false
                    animateNode(destinationNode, withAction: AnimationActions.destination)

                    // Position the `lineNode` and make sure it's visible.
                    positionLineNodeFrom(source, to: target)
                    lineNode?.hidden = false
                }
                else {
                    // Show the `sourceNode` with the its untargeted animation.
                    sourceNode.hidden = false
                    animateNode(sourceNode, withAction: AnimationActions.untargetedSource)
                    
                    // Hide the `destinationNode` and `lineNode`.
                    destinationNode.hidden = true
                    lineNode?.hidden = true
                }
                
                // Update the debug node if debug drawing is enabled.
                debugNode.hidden = !debugDrawingEnabled
                
                if debugDrawingEnabled {
                    guard let sourceOrientation = source.componentForClass(OrientationComponent.self) else {
                        fatalError("BeamNodees must be associated with entities that have an orientation node")
                    }

                    /*
                        Update the `debugNode` with an arc based off the
                        ratio of the distance from the source to the target.
                    
                        This allows for easier aiming the closer the source is to
                        the target.
                    */
                    let arcPath = CGPathCreateMutable()
                    
                    // Only draw beam arc if there is a target.
                    if let target = target {
                        let distanceRatio = GameplayConfiguration.Beam.arcLength / CGFloat(distance(source.agent.position, target.agent.position))
                        let arcAngle = min(GameplayConfiguration.Beam.arcAngle * distanceRatio, 1 / GameplayConfiguration.Beam.maxArcAngle)
                        
                        CGPathAddArc(arcPath, nil, 0.0, 0.0, GameplayConfiguration.Beam.arcLength, arcAngle * 0.5, -arcAngle * 0.5, true)
                        CGPathAddLineToPoint(arcPath, nil, 0.0, 0.0)
                    }
                    debugNode.path = arcPath
                    
                    debugNode.zRotation = sourceOrientation.zRotation
                }
            
            case is BeamCoolingState:
                // Show the `sourceNode` with the "cooling" animation.
                sourceNode.hidden = false
                animateNode(sourceNode, withAction: AnimationActions.cooling)

                // Hide the `destinationNode`.
                destinationNode.hidden = true
                
                // Remove the `lineNode` from the scene.
                lineNode?.removeFromParent()
                lineNode = nil
                
                debugNode.hidden = true
            
            default:
                break
        }
    }
    
    // MARK: Convenience
    
    func animateNode(node: SKSpriteNode, withAction action: SKAction) {
        if runningNodeAnimations[node] != action {
            node.runAction(action, withKey: BeamNode.animationActionKey)
            runningNodeAnimations[node] = action
        }
    }

    func positionLineNodeFrom(source: PlayerBot, to target: TaskBot) {
        guard let lineNode = lineNode else { fatalError("positionLineNodeFrom(_: to:) requires a lineNode to have been created.") }
        
        // Calculate the source and destination positions.
        let sourcePosition: CGPoint = {
            guard let node = source.componentForClass(RenderComponent.self)?.node, nodeParent = node.parent else {
                fatalError("positionLineNodeFrom(_: to:) requires the source to have a node with a parent.")
            }

            var position = convertPoint(node.position, fromNode: nodeParent)
            position.x += source.antennaOffset.x
            position.y += source.antennaOffset.y
            
            return position
        }()
        
        let destinationPosition: CGPoint = {
            guard let node = target.componentForClass(RenderComponent.self)?.node, nodeParent = node.parent else {
                fatalError("positionLineNodeFrom(_: to:) requires the destination to have a node with a parent.")
            }
            
            var position = convertPoint(node.position, fromNode: nodeParent)
            position.x += target.beamTargetOffset.x
            position.y += target.beamTargetOffset.y
            
            return position
        }()
        
        // Set the line's position and rotation.
        let dx = destinationPosition.x - sourcePosition.x
        let dy = destinationPosition.y - sourcePosition.y
        
        lineNode.position = sourcePosition
        lineNode.zRotation = atan2(dy, dx)

        // Scale the line's length.
        let beamLength = hypot(dx, dy)
        lineNode.xScale = beamLength / BeamNode.lineNodeTemplate.size.width
    }
    
    // MARK: ResourceLoadableType
    
    static var resourcesNeedLoading: Bool {
        return AnimationActions.source == nil || AnimationActions.untargetedSource == nil || AnimationActions.destination == nil || AnimationActions.cooling == nil
    }
    
    static func loadResourcesWithCompletionHandler(completionHandler: () -> ()) {
        let beamAtlasNames = [
            "BeamDot",
            "BeamCharging"
        ]
        
        /*
            Preload all of the texture atlases for `BeamNode`. This improves
            the overall loading speed of the animation cycles for the beam.
        */
        SKTextureAtlas.preloadTextureAtlasesNamed(beamAtlasNames) { error, beamAtlases in
            if let error = error {
                fatalError("One or more texture atlases could not be found: \(error)")
            }
            
            let beamDotAction = AnimationComponent.actionForAllTexturesInAtlas(beamAtlases[0])
            AnimationActions.source = beamDotAction
            AnimationActions.untargetedSource = beamDotAction
            AnimationActions.destination = beamDotAction
            AnimationActions.cooling = AnimationComponent.actionForAllTexturesInAtlas(beamAtlases[1])
            
            // Invoke the passed `completionHandler` to indicate that loading has completed.
            completionHandler()
        }
    }
    
    static func purgeResources() {
        AnimationActions.source = nil
        AnimationActions.destination = nil
        AnimationActions.untargetedSource = nil
        AnimationActions.cooling = nil
    }
}
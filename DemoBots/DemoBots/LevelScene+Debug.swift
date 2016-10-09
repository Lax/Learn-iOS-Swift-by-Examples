/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension on `LevelScene` to provide additional debug drawing related to GameplayKit features. Debug drawing can be turned on by pressing the "/" key when running the game on OS X.
*/

import SpriteKit
import GameplayKit

// Extend LevelScene by adding functions for drawing graph connections and obstacles.
extension LevelScene {
    
    func debugDrawingEnabledDidChange() {
        // Draw or remove the pathfinding graph for this level.
        drawGraph()
        
        /*
            Turn on debug drawing for every obstacle in the level, to show their
            pathfinding buffer radius.
        */
        for obstacle in obstacleSpriteNodes {
            obstacle.debugDrawingEnabled = debugDrawingEnabled
        }
        
        // Notify any `beamNode`'s inside `BeamComponent`s of the new debug drawing state.
        for componentSystem in componentSystems {
            guard componentSystem.componentClass is BeamComponent.Type else { continue }
            
            for component in componentSystem.components as! [BeamComponent] {
                component.beamNode.debugDrawingEnabled = debugDrawingEnabled
            }
        }
    }
    
    /// Draws (or removes) a debug representation of the pathfinding graph for this level.
    func drawGraph() {
        guard debugDrawingEnabled else {
            graphLayer.removeAllChildren()
            return
        }

        for node in graph.nodes as! [GKGraphNode2D] {
            for destination in node.connectedNodes as! [GKGraphNode2D] {
                let points = [CGPoint(node.position), CGPoint(destination.position)]

                let shapeNode = SKShapeNode(points: UnsafeMutablePointer<CGPoint>(mutating: points), count: 2)
                shapeNode.strokeColor = SKColor(white: 1.0, alpha: 0.1)
                shapeNode.lineWidth = 2.0
                shapeNode.zPosition = -1
                graphLayer.addChild(shapeNode)
            }
        }
    }
    
}

/*
    Extend `SKSpriteNode` to draw a buffer radius around nodes that have physics bodies.
    This is useful when debugging `GKAgent2D` pathfinding around obstacles.
*/
extension SKSpriteNode {
    
    /// A convenience name for use when adding and removing the debug layer.
    private var debugBufferShapeName: String {
        return "debugBufferShape"
    }
    
    var debugDrawingEnabled: Bool {
        set {
            // Only enable buffer radius debug drawing for sprite nodes with a physics body.
            if physicsBody == nil { return }
            
            // Add a debug shape layer if we are turning on debug drawing for this node.
            if newValue == true {
                let bufferRadius = CGFloat(GameplayConfiguration.TaskBot.pathfindingGraphBufferRadius)
                let bufferFrame = frame.insetBy(dx: -bufferRadius, dy: -bufferRadius)
                let bufferedShape = SKShapeNode(rectOf: bufferFrame.size)
                bufferedShape.fillColor = SKColor(red: CGFloat(1.0), green: CGFloat(0.5), blue: CGFloat(0.0), alpha: CGFloat(0.2))
                bufferedShape.strokeColor = SKColor(red: CGFloat(1.0), green: CGFloat(0.5), blue: CGFloat(0.0), alpha: CGFloat(0.4))
                bufferedShape.name = debugBufferShapeName
                addChild(bufferedShape)
            }
            else {
                // Remove any existing debug shape layer if we are turning off debug drawing for this node.
                guard let debugBufferShape = childNode(withName: debugBufferShapeName) else { return }
                removeChildren(in: [debugBufferShape])
            }
        }
        get {
            // Debug drawing is considered "enabled" if we have the debug node as a child.
            return childNode(withName: debugBufferShapeName) != nil
        }
    }
    
}

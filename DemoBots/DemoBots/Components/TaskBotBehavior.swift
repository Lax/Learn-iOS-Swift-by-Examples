/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `TaskBotBehavior` is a `GKBehavior` subclass that provides convenience class methods to construct the appropriate goals and behaviors for different `TaskBot` mandates.
*/

import SpriteKit
import GameplayKit

/// Provides factory methods to create `TaskBot`-specific goals and behaviors.
class TaskBotBehavior: GKBehavior {
    // MARK: Behavior factory methods
    
    /// Constructs a behavior to hunt a `TaskBot` or `PlayerBot` via a computed path.
    static func behaviorAndPathPointsForAgent(agent: GKAgent2D, huntingAgent target: GKAgent2D, pathRadius: Float, inScene scene: LevelScene) -> (behavior: GKBehavior, pathPoints: [CGPoint]) {
        let behavior = TaskBotBehavior()
        
        // Add basic goals to reach the `TaskBot`'s maximum speed and avoid obstacles.
        behavior.addTargetSpeedGoal(agent.maxSpeed)
        behavior.addAvoidObstaclesGoalForScene(scene)

        // Find any nearby "bad" TaskBots to flock with.
        let agentsToFlockWith: [GKAgent2D] = scene.entities.flatMap { entity in
            if let taskBot = entity as? TaskBot where !taskBot.isGood && taskBot.agent !== agent && taskBot.distanceToAgent(agent) <= GameplayConfiguration.Flocking.agentSearchDistanceForFlocking {
                return taskBot.agent
            }

            return nil
        }
        
        if !agentsToFlockWith.isEmpty {
            // Add flocking goals for any nearby "bad" `TaskBot`s.
            let separationGoal = GKGoal(toSeparateFromAgents: agentsToFlockWith, maxDistance: GameplayConfiguration.Flocking.separationRadius, maxAngle: GameplayConfiguration.Flocking.separationAngle)
            behavior.setWeight(GameplayConfiguration.Flocking.separationWeight, forGoal: separationGoal)
            
            let alignmentGoal = GKGoal(toAlignWithAgents: agentsToFlockWith, maxDistance: GameplayConfiguration.Flocking.alignmentRadius, maxAngle: GameplayConfiguration.Flocking.alignmentAngle)
            behavior.setWeight(GameplayConfiguration.Flocking.alignmentWeight, forGoal: alignmentGoal)
            
            let cohesionGoal = GKGoal(toCohereWithAgents: agentsToFlockWith, maxDistance: GameplayConfiguration.Flocking.cohesionRadius, maxAngle: GameplayConfiguration.Flocking.cohesionAngle)
            behavior.setWeight(GameplayConfiguration.Flocking.cohesionWeight, forGoal: cohesionGoal)
        }

        // Add goals to follow a calculated path from the `TaskBot` to its target.
        let pathPoints = behavior.addGoalsToFollowPathFromStartPoint(agent.position, toEndPoint: target.position, pathRadius: pathRadius, inScene: scene)
        
        // Return a tuple containing the new behavior, and the found path points for debug drawing.
        return (behavior, pathPoints)
    }
    
    /// Constructs a behavior to return to the start of a `TaskBot` patrol path.
    static func behaviorAndPathPointsForAgent(agent: GKAgent2D, returningToPoint endPoint: float2, pathRadius: Float, inScene scene: LevelScene) -> (behavior: GKBehavior, pathPoints: [CGPoint]) {
        let behavior = TaskBotBehavior()
        
        // Add basic goals to reach the `TaskBot`'s maximum speed and avoid obstacles.
        behavior.addTargetSpeedGoal(agent.maxSpeed)
        behavior.addAvoidObstaclesGoalForScene(scene)
        
        // Add goals to follow a calculated path from the `TaskBot` to the start of its patrol path.
        let pathPoints = behavior.addGoalsToFollowPathFromStartPoint(agent.position, toEndPoint: endPoint, pathRadius: pathRadius, inScene: scene)

        // Return a tuple containing the new behavior, and the found path points for debug drawing.
        return (behavior, pathPoints)
    }
    
    /// Constructs a behavior to patrol a path of points, avoiding obstacles along the way.
    static func behaviorForAgent(agent: GKAgent2D, patrollingPathWithPoints patrolPathPoints: [CGPoint], pathRadius: Float, inScene scene: LevelScene) -> GKBehavior {
        let behavior = TaskBotBehavior()
        
        // Add basic goals to reach the `TaskBot`'s maximum speed and avoid obstacles.
        behavior.addTargetSpeedGoal(agent.maxSpeed)
        behavior.addAvoidObstaclesGoalForScene(scene)
        
        // Convert the patrol path to an array of `float2`s.
        let pathVectorPoints = patrolPathPoints.map(float2.init)
        
        // Create a cyclical (closed) `GKPath` from the provided path points with the requested path radius.
        let path = GKPath(points: UnsafeMutablePointer<float2>(pathVectorPoints), count: pathVectorPoints.count, radius: pathRadius, cyclical: true)

        // Add "follow path" and "stay on path" goals for this path.
        behavior.addFollowAndStayOnPathGoalsForPath(path)

        return behavior
    }
    
    // MARK: Goals
    
    /**
        Calculates all of the extruded obstacles that the provided point resides near.
        The extrusion is based on the buffer radius of the pathfinding graph.
    */
    private func extrudedObstaclesContainingPoint(point: float2, inScene scene: LevelScene) -> [GKPolygonObstacle] {
        /*
            Add a small fudge factor (+5) to the extrusion radius to make sure 
            we're including all obstacles.
        */
        let extrusionRadius = Float(GameplayConfiguration.TaskBot.pathfindingGraphBufferRadius) + 5

        /*
            Return only the polygon obstacles which contain the specified point.
            
            Note: This creates a bounding box around the polygon obstacle to check
            for intersection. This is appropriate for DemoBots, but in your game a
            more specific check may be necessary.
        */
        return scene.polygonObstacles.filter { obstacle in
            // Retrieve all vertices for the polygon obstacle.
            let range = 0..<obstacle.vertexCount
            
            let polygonVertices = range.map { obstacle.vertexAtIndex($0) }
            guard !polygonVertices.isEmpty else { return false }
            
            let maxX = polygonVertices.maxElement { $0.x < $1.x }!.x + extrusionRadius
            let maxY = polygonVertices.maxElement { $0.y < $1.y }!.y + extrusionRadius
            
            let minX = polygonVertices.minElement { $0.x < $1.x }!.x - extrusionRadius
            let minY = polygonVertices.minElement { $0.y < $1.y }!.y - extrusionRadius
            
            return (point.x > minX && point.x < maxX) && (point.y > minY && point.y < maxY)
        }
    }
    
    /**
        Creates a node on the obstacle graph for the provided point by ignoring
        the buffer radius of the contacted obstacles. 
    
        Returns `nil` if a valid connection could not be made.
    */
    private func connectedNodeForPoint(point: float2, onObstacleGraphInScene scene: LevelScene) -> GKGraphNode2D? {
        // Create a graph node for this point.
        let pointNode = GKGraphNode2D(point: point)
        
        // Try to connect this node to the graph.
        scene.graph.connectNodeUsingObstacles(pointNode)

        /*
            Check to see if we were able to connect the node to the graph.
            If not, this means that the point is inside the buffer zone of an obstacle
            somewhere in the level. We can't pathfind to a point that is off-graph,
            so we try to find the nearest point that is on the graph, and pathfind
            to there instead.
        */
        if pointNode.connectedNodes.isEmpty {
            // The previous connection attempt failed, so remove the node from the graph.
            scene.graph.removeNodes([pointNode])
        
            // Search the graph for all intersecting obstacles.
            let intersectingObstacles = extrudedObstaclesContainingPoint(point, inScene: scene)
        
            /*
                Connect this node to the graph ignoring the buffer radius of any
                obstacles that the point is currently intersecting.
            */
            scene.graph.connectNodeUsingObstacles(pointNode, ignoringBufferRadiusOfObstacles: intersectingObstacles)
        
            // If still no connection could be made, return `nil`.
            if pointNode.connectedNodes.isEmpty {
                scene.graph.removeNodes([pointNode])
                return nil
            }
        }
        
        return pointNode
    }
    
    /// Pathfinds around obstacles to create a path between two points, and adds goals to follow that path.
    private func addGoalsToFollowPathFromStartPoint(startPoint: float2, toEndPoint endPoint: float2, pathRadius: Float, inScene scene: LevelScene) -> [CGPoint] {
        // Convert the provided `CGPoint`s into nodes for the `GPGraph`.
        guard let startNode = connectedNodeForPoint(startPoint, onObstacleGraphInScene: scene),
             endNode = connectedNodeForPoint(endPoint, onObstacleGraphInScene: scene) else { return [] }
        
        // Remove the "start" and "end" nodes when exiting this scope.
        defer { scene.graph.removeNodes([startNode, endNode]) }
        
        // Find a path between these two nodes.
        let pathNodes = scene.graph.findPathFromNode(startNode, toNode: endNode) as! [GKGraphNode2D]
        
        // A valid `GKPath` can not be created if fewer than 2 path nodes were found, return.
        guard pathNodes.count > 1 else { return [] }
        
        // Create a new `GKPath` from the found nodes with the requested path radius.
        let path = GKPath(graphNodes: pathNodes, radius: pathRadius)
        
        // Add "follow path" and "stay on path" goals for this path.
        addFollowAndStayOnPathGoalsForPath(path)
        
        // Convert the `GKGraphNode2D` nodes into `CGPoint`s for debug drawing.
        let pathPoints = pathNodes.map { CGPoint($0.position) }
        return pathPoints
    }
    
    /// Adds a goal to avoid all polygon obstacles in the scene.
    private func addAvoidObstaclesGoalForScene(scene: LevelScene) {
        setWeight(1.0, forGoal: GKGoal(toAvoidObstacles: scene.polygonObstacles, maxPredictionTime: GameplayConfiguration.TaskBot.maxPredictionTimeForObstacleAvoidance))
    }
    
    /// Adds a goal to attain a target speed.
    private func addTargetSpeedGoal(speed: Float) {
        setWeight(0.5, forGoal: GKGoal(toReachTargetSpeed: speed))
    }
    
    /// Adds goals to follow and stay on a path.
    private func addFollowAndStayOnPathGoalsForPath(path: GKPath) {
        // The "follow path" goal tries to keep the agent facing in a forward direction when it is on this path.
        setWeight(1.0, forGoal: GKGoal(toFollowPath: path, maxPredictionTime: GameplayConfiguration.TaskBot.maxPredictionTimeWhenFollowingPath, forward: true))

        // The "stay on path" goal tries to keep the agent on the path within the path's radius.
        setWeight(1.0, forGoal: GKGoal(toStayOnPath: path, maxPredictionTime: GameplayConfiguration.TaskBot.maxPredictionTimeWhenFollowingPath))
    }
}

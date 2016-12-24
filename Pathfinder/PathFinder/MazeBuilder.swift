/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Handles random generation for a Maze object.
*/

import GameplayKit

class MazeBuilder {
    // MARK: Types
    
    /**
        An enum for the cardinal directions. This enables you to randomly
        generate a direction with a random number generator.
    */
    enum Direction: Int {
        case left = 0, down, right, up
        
        /// Generates a random direction.
        static func random() -> Direction {
            /*
                Generate a random number from 0-3, and return a corresponing 
                Direction enum.
            */
            let randomInt = GKRandomSource.sharedRandom().nextInt(upperBound: 4)
            
            return Direction(rawValue: randomInt)!
        }
        
        // The offset value for the x-axis associated with a direction.
        var dx: Int {
            switch self {
                case .up, .down: return 0
                case .left:      return -2
                case .right:     return 2
            }
        }
        
        // The offset value for the y-axis associated with a direction.
        var dy: Int {
            switch self {
                case .left, .right: return 0
                case .up:           return 2
                case .down:         return -2
            }
        }
    }
    
    // MARK: Properties
    
    /// A reference to the maze that the maze builder is building for.
    let maze: Maze
    
    /// Holds graph nodes designated as walls.
    var wallNodes = [GKGridGraphNode]()
    
    /// Used as a stack to search the maze during during maze generation.
    var searchStack = [GKGridGraphNode]()
    
    /// Used to keep track of visited nodes during maze generation.
    var visitedNodes = [GKGridGraphNode]()
    
    /**
        Returns every potential wall in the maze graph to the walls array. Due
        to the way the maze is constructed, a node is a potential wall if it has
        an odd x or y coordinate.
    */
    var potentialWalls: [GKGridGraphNode] {
        // Grab the graph nodes from the maze graph.
        let graphNodes = maze.graph.nodes as! [GKGridGraphNode]
        
        // Filter in the nodes that could potentially be walls.
        let potentialWalls = graphNodes.filter { node in
            // Grab the coordinates of the maze node.
            let x = Int(node.gridPosition.x)
            let y = Int(node.gridPosition.y)
            
            // If the maze node has an odd coordinate, filter it into the array.
            return x % 2 == 1 || y % 2 == 1
        }
        
        return potentialWalls
    }
    
    // MARK: Initialization
    
    init(maze: Maze) {
        self.maze = maze
    }
    
    // MARK: Methods
    
    /**
        Returns an array of maze graph nodes representing walls in the maze.
        These nodes are to be removed from the pathfinding graph, since walls
        are impassible.
    
        This maze generation algorithm uses a depth-first search (DFS).
        It uses a stack to track its progress through the maze, and an array
        to check how much of the maze it has visited. It works like this:
        the starting node is added to the stack and array. The algorithm
        selects a node neighboring the top node of the stack (the starting
        node, in this case). It then removes the wall separating those two
        nodes, and adds the neighboring node to the stack and array. This
        process continues until the top node of the stack has no unvisited
        neighbors. When what happens, the algorithm removes nodes from the
        stack until the top node has an unvisited neighbor, and the process
        continues. Eventually the entire maze will have been visited, the
        stack will be empty, and the maze is created.
        
        Instead of removing walls directly, this method keeps track of
        which walls need to be removed, and returns those nodes.
    */
    func mazeWallsForRemoval() -> [GKGridGraphNode] {
        // First, add all of the potential walls to the array of walls.
        wallNodes += potentialWalls

        // Initialize both the stack and array with the starting maze graph node.
        searchStack.append(maze.startNode)
        visitedNodes.append(maze.startNode)
        
        // Until the stack is empty, process the maze graph.
        while let topNode = searchStack.last {
            /*
                First, check if the top node of the stack has any unvisited
                neighbors. If so, select a random unvisited neighbor to visit.
                Otherwise, remove the top node.
            */
            guard hasUnvisitedNeighborNode(topNode) else {
                // Remove the top node.
                searchStack.removeLast()
                
                // Skip to the next iteration of the while loop.
                continue
            }
            
            /*
                Check random neighboring directions until a neighboring node
                is found. Then visit that node.
            */
            exploreUnvisitedNodes: while true {
                // Generate a random direction.
                let randomDirection = Direction.random()

                /* 
                    If a direction should be explored by the algorithm, explore 
                    the node in that direction and exit the while loop.
                */
                if shouldExploreInDirectionFromNode(topNode, inDirection: randomDirection) {
                    exploreNodeInDirectionFromNode(topNode, inDirection: randomDirection)
                    break exploreUnvisitedNodes
                }
            }
        }
        
        // Return a set of walls that can be removed to form a maze.
        return wallNodes
    }

    /**
        Tests whether a node in a direction from a given node is unvisited. If
        so, it is explorable by the maze generation algorithm.
    */
    func shouldExploreInDirectionFromNode(_ node: GKGridGraphNode, inDirection direction: Direction) -> Bool {
        // Get the direction of the offset.
        let dx = direction.dx
        let dy = direction.dy
        
        // Get the location of the current node.
        let x = node.gridPosition.x
        let y = node.gridPosition.y
        
        // Return whether the node is unvisited or not.
        return nodeIsUnvisitedAtCoordinates(x: x + dx, y: y + dy)
    }
    
    /**
        Explores a direction in the maze generation algorithm, removing the wall
        between the given node and a node in the given direction.
    */
    func exploreNodeInDirectionFromNode(_ node: GKGridGraphNode, inDirection direction: Direction) {
        // Get the direction of the offset.
        let dx = direction.dx
        let dy = direction.dy
        
        // Get the location of the current node.
        let x = node.gridPosition.x
        let y = node.gridPosition.y
        
        // Get the location of node in the given direction.
        let nodeInDirectionPosition = int2(x + dx, y + dy)
        let nodeInDirection = maze.graph.node(atGridPosition: nodeInDirectionPosition)!
        
        // Add the node in the direction to the stack, and mark it as visited.
        searchStack.append(nodeInDirection)
        visitedNodes.append(nodeInDirection)
        
        // Remove the wall between this node and the current node.
        let wallNodePosition = int2(x + dx / 2, y + dy / 2)
        let wallNode = maze.graph.node(atGridPosition: wallNodePosition)!
        let wallNodeIndex = wallNodes.index(of: wallNode)!
        wallNodes.remove(at: wallNodeIndex)
    }

    /// Checks if the given maze graph node has any unvisited neighbor nodes.
    func hasUnvisitedNeighborNode(_ currentNode: GKGridGraphNode) -> Bool {
        // Grab the position of the given maze graph node.
        let x = currentNode.gridPosition.x
        let y = currentNode.gridPosition.y
        
        // Check whether the left, right, top, or bottom nodes are unvisited.
        let leftNodeIsUnvisited   = nodeIsUnvisitedAtCoordinates(x: x - 2, y: y)
        let rightNodeIsUnvisited  = nodeIsUnvisitedAtCoordinates(x: x + 2, y: y)
        let topNodeIsUnvisited    = nodeIsUnvisitedAtCoordinates(x: x, y: y + 2)
        let bottomNodeIsUnvisited = nodeIsUnvisitedAtCoordinates(x: x, y: y - 2)
        
        /*
            If any of the neighboring nodes are unvisited, return that the node 
            has at least one unvisited neighbor node. Otherwise, return that it 
            doesn't.
        */
        let hasUnvisitedNeighborNode = leftNodeIsUnvisited || rightNodeIsUnvisited || topNodeIsUnvisited || bottomNodeIsUnvisited
        return hasUnvisitedNeighborNode
    }
    
    /// This method checks if a node is unvisited.
    func nodeIsUnvisitedAtCoordinates(x: Int32, y: Int32) -> Bool {
        // Check if a node with the given position exists.
        let nodePosition = int2(x, y)
        guard let node = maze.graph.node(atGridPosition: nodePosition) else {
            return false
        }
        
        // Return if the node is unvisited.
        let nodeIsUnvisited = !visitedNodes.contains(node)
        return nodeIsUnvisited
    }
}

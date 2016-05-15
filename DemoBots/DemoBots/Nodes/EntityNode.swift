/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A simple `SKNode` subclass that stores a `weak` reference to an associated `GKEntity`. Provides a way to discover the entity associated with a node.
*/

import SpriteKit
import GameplayKit

class EntityNode: SKNode {
    // MARK: Properties
    
    weak var entity: GKEntity!
}

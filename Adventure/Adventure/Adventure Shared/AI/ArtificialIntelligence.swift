/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the class that handles basic AI.
*/

import SpriteKit

class ArtificialIntelligence {
    // MARK: Properties

    // The character that should be moving towards the target.
    var character: Character
    
    // The target of the AI. This property can be set after initialization.
    var target: Character?

    // MARK: Initializers

    init(character: Character) {
        self.character = character
    }

    // MARK: Scene Processing Support

    // This should be overriden in subclasses.
    func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
       // No implementation required in the base class AI.
    }
}

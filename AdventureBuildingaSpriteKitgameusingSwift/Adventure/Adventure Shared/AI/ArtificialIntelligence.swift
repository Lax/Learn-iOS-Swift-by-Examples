/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the class that handles basic AI
      
*/

import SpriteKit

class ArtificialIntelligence {
    var character: Character
    var target: Character?

    init(character: Character, target: Character?) {
        self.character = character
        self.target = target
    }

    func updateWithTimeSinceLastUpdate(interval: NSTimeInterval) {
        // Overridden by subclasses
    }

    func clearTarget(target: Character?) {
        if self.target == target {
            self.target = nil
        }
    }
}

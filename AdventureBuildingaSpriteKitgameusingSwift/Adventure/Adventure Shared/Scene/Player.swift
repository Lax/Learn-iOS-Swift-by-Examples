/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the Player class.
      
*/

import SpriteKit

class Player {
    var hero: HeroCharacter? = nil
    var charClass: CharacterClass? = nil
    var livesLeft = kStartLives
    var score = 0

    var moveForward = false
    var moveLeft = false
    var moveRight = false
    var moveBack = false
    var fireAction = false

    #if os(iOS)
    var movementTouch: UITouch? = .None
    var targetLocation: CGPoint = CGPointZero
    var moveRequested: Bool = false
    #endif
}

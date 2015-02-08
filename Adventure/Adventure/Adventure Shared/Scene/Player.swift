/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the Player class.
*/

import SpriteKit
import GameController

class Player: NSObject {
    // MARK: Types
    
    enum HeroType {
        case Warrior, Archer
    }
    
    struct Constants {
        static let initialLives = 3
    }
    
    struct Keys {
        static let projectileUserDataPlayer = "Player.Keys.projectileUserDataPlayer"
    }
    
    // MARK: Properties

    var hero: HeroCharacter?
    var heroType: HeroType?
    var livesLeft = Constants.initialLives
    var score = 0
    
    // Convenience properties for the nodes that make up the player's HUD.
    var hudAvatar: SKSpriteNode!
    var hudScore: SKLabelNode!
    var hudLifeHearts = [SKSpriteNode]()

    var moveForward = false
    var moveLeft = false
    var moveRight = false
    var moveBackward = false
    var fireAction = false
    
    var heroMoveDirection: CGVector?
    var heroFaceLocation: CGPoint?
    var controller: GCController?

    #if os(iOS)
    var movementTouch: UITouch?
    var targetLocation = CGPointZero
    var moveRequested = false
    #endif
    
    override init() {
        // Pick one of the two hero classes at random for additional players in multiplayer games.
        if arc4random_uniform(2) == 0 {
            heroType = .Warrior
        }
        else {
            heroType = .Archer
        }
    }
}

/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Defines OS X-specific extensions to the layered character scene.
*/

import SpriteKit

extension AdventureScene {
    // MARK: Types
    
    // Represents different types of user input that result in actions.
    private enum KeyEventFlag {
        case MoveForward
        case MoveLeft
        case MoveRight
        case MoveBackward
        case Fire

        // The mapping from key events to their player actions.
        private static let keyMapping: [UnicodeScalar: KeyEventFlag] = [
            "w":                    .MoveForward,
            UnicodeScalar(0xF700):  .MoveForward,
            "s":                    .MoveBackward,
            UnicodeScalar(0xF701):  .MoveBackward,
            "d":                    .MoveRight,
            UnicodeScalar(0xF703):  .MoveRight,
            "a":                    .MoveLeft,
            UnicodeScalar(0xF702):  .MoveLeft,
            " ":                    .Fire
        ]
        
        // MARK: Initializers
        
        init?(unicodeScalar: UnicodeScalar) {
            if let event = KeyEventFlag.keyMapping[unicodeScalar] {
                self = event
            }
            else {
                return nil
            }
        }
    }
    
    // MARK: Event Handling
    
    override func keyDown(event: NSEvent) {
        handleKeyEvent(event, keyDown: true)
    }
    
    override func keyUp(event: NSEvent) {
        handleKeyEvent(event, keyDown: false)
    }
    
    // MARK: Convenience
    
    private func handleKeyEvent(event: NSEvent, keyDown: Bool) {
        if event.modifierFlags & .NumericPadKeyMask == .NumericPadKeyMask {
            if let charactersIgnoringModifiers = event.charactersIgnoringModifiers {
                applyEventsFromEventString(charactersIgnoringModifiers, keyDown: keyDown)
            }
        }
        
        if let characters = event.characters {
            applyEventsFromEventString(characters, keyDown: keyDown)
        }
    }
    
    func applyEventsFromEventString(eventString: String, keyDown: Bool) {
        for key in eventString.unicodeScalars {
            if let flag = KeyEventFlag(unicodeScalar: key) {
                switch flag {
                    case .MoveForward: defaultPlayer.moveForward = keyDown
                    case .MoveBackward: defaultPlayer.moveBackward = keyDown
                    case .MoveLeft: defaultPlayer.moveLeft = keyDown
                    case .MoveRight: defaultPlayer.moveRight = keyDown
                    case .Fire: defaultPlayer.fireAction = keyDown
                }
            }
        }
    }
}

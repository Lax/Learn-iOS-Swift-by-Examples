/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines OS X-specific extensions to the layered character scene
      
*/

import SpriteKit

extension LayeredCharacterScene {
    // EVENT HANDLING
    func handleKeyEvent(event: NSEvent, keyDown downOrUp: Bool) {
        if event.modifierFlags & .NumericPadKeyMask {
            for keyChar in event.charactersIgnoringModifiers.unicodeScalars {
                switch UInt32(keyChar) {
                    case 0xF700:
                        defaultPlayer.moveForward = downOrUp

                    case 0xF702:
                        defaultPlayer.moveLeft = downOrUp

                    case 0xF703:
                        defaultPlayer.moveRight = downOrUp

                    case 0xF701:
                        defaultPlayer.moveBack = downOrUp

                    default:
                      ()

                }
            }
        }

        let characters = event.characters
        for character in characters.unicodeScalars {
            switch character {
                case "w":
                    defaultPlayer.moveForward = downOrUp

                case "a":
                    defaultPlayer.moveLeft = downOrUp

                case "d":
                    defaultPlayer.moveRight = downOrUp

                case "s":
                    defaultPlayer.moveBack = downOrUp

                case " ":
                    defaultPlayer.fireAction = downOrUp

                default:
                    ()
            }
        }
    }

    override func keyDown(event: NSEvent) {
        handleKeyEvent(event, keyDown: true)
    }

    override func keyUp(event: NSEvent) {
        handleKeyEvent(event, keyDown: false)
    }

}

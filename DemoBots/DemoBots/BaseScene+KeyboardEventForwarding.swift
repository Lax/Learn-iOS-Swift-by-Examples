/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension of `BaseScene` to provide OS X platform specific functionality. This file is only included in the OS X target.
*/

import Cocoa

/*
    Extend `BaseScene` to forward events from the scene to a platform-specific
    control input source. On OS X, this is a `KeyboardControlInputSource`.
*/
extension BaseScene {
    // MARK: Properties
    
    var keyboardControlInputSource: KeyboardControlInputSource {
        return sceneManager.gameInput.nativeControlInputSource as! KeyboardControlInputSource
    }
    
    // MARK: NSResponder
    
    override func mouseDown(event: NSEvent) {
        keyboardControlInputSource.handleMouseDownEvent()
    }
    
    override func mouseUp(theEvent: NSEvent) {
        keyboardControlInputSource.handleMouseUpEvent()
    }

    override func keyDown(event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers?.characters else { return }

        for character in characters {
            keyboardControlInputSource.handleKeyDownForCharacter(character)
        }
    }
    
    override func keyUp(event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers?.characters else { return }
        
        for character in characters {
            keyboardControlInputSource.handleKeyUpForCharacter(character)
        }
    }
}
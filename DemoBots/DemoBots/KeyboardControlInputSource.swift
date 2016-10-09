/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An implementation of the `ControlInputSourceType` protocol that enables support for keyboard input on OS X.
*/

import simd

class KeyboardControlInputSource: ControlInputSourceType {
    // MARK: Properties
    
    /// The vector used to keep track of movement.
    var currentDisplacement = float2()
    
    /// Bookkeeping to ignore repeating keys.
    var downKeys = Set<Character>()
    
    /// `ControlInputSourceType` delegates.
    weak var gameStateDelegate: ControlInputSourceGameStateDelegate? {
        didSet {
            // When the delegate is assigned, reset the control state.
            resetControlState()
        }
    }

    weak var delegate: ControlInputSourceDelegate? {
        didSet {
            // When the delegate is assigned, reset the control state.
            resetControlState()
        }
    }
    
    let allowsStrafing = false
    
    /// Values representing different relative motions the keyboard is capable of supplying.
    static let forwardVector          = float2(x: 1, y: 0)
    static let backwardVector         = float2(x: -1, y: 0)
    static let clockwiseVector        = float2(x: 0, y: -1)
    static let counterClockwiseVector = float2(x: 0, y: 1)
    
    // MARK: Control Handling
    
    func handleMouseDownEvent() {
        delegate?.controlInputSourceDidBeginAttacking(self)
    }
    
    func handleMouseUpEvent() {
        delegate?.controlInputSourceDidFinishAttacking(self)
    }
    
    /// The logic matching a key press to `ControlInputSourceDelegate` calls.
    func handleKeyDown(forCharacter character: Character) {
        // Ignore repeat input.
        if downKeys.contains(character) {
            return
        }
        downKeys.insert(character)
        
        // Retrieve the `relativeDisplacement` vector mapped for each displacement character ("wasd" and arrow keys).
        if let relativeDisplacement = relativeDisplacementForCharacter(character) {
            // Add to the `currentDisplacement` to track the overall displacement.
            currentDisplacement += relativeDisplacement
            
            if isDirectionalDisplacementVector(relativeDisplacement) {
                // Forward or backward displacement.
                delegate?.controlInputSource(self, didUpdateWithRelativeDisplacement: currentDisplacement)
            }
            else {
                // Rotational displacement.
                delegate?.controlInputSource(self, didUpdateWithRelativeAngularDisplacement: currentDisplacement)
            }
            
            /*
                Game focus navigation relies on strict 2D coordinates.
                Translate the relative input into directional coordinates.
            */
            let directionalVector = float2(x: -relativeDisplacement.y, y: relativeDisplacement.x)
            if let direction = ControlInputDirection(vector: directionalVector) {
                gameStateDelegate?.controlInputSource(self, didSpecifyDirection: direction)
            }
        }
        else if isAttackCharacter(character) {
            // An attack command was requested.
            delegate?.controlInputSourceDidBeginAttacking(self)
            
            // Ignore the spacebar for game selection behavior. All other attack commands are valid. 
            if character != " " {
                gameStateDelegate?.controlInputSourceDidSelect(self)
            }
        }
        else {
            // Account for the other possible kinds of actions.
            #if DEBUG
            switch character {
                case "/":
                    gameStateDelegate?.controlInputSourceDidToggleDebugInfo(self)
                
                case "[":
                    gameStateDelegate?.controlInputSourceDidTriggerLevelSuccess(self)
                
                case "]":
                    gameStateDelegate?.controlInputSourceDidTriggerLevelFailure(self)
              
                default: break
            }
            #endif
        }
    }
    
    // Handle the logic matching when a key is released to `ControlInputSource` delegate calls.
    func handleKeyUp(forCharacter character: Character) {
        // Ensure the character was accounted for by `handleKeyDown(forCharacter:)`.
        guard downKeys.remove(character) != nil else { return }
        
        if let relativeDisplacement = relativeDisplacementForCharacter(character) {
            // Subtract from the `currentDisplacement` if a displacement key has been released.
            currentDisplacement -= relativeDisplacement
            
            if downKeys.isEmpty {
                // Ensure that the `currentDisplacement` is zero if there are no keys pressed.
                currentDisplacement = float2()
            }
            
            if isDirectionalDisplacementVector(relativeDisplacement) {
                delegate?.controlInputSource(self, didUpdateWithRelativeDisplacement: currentDisplacement)
            }
            else {
                delegate?.controlInputSource(self, didUpdateWithRelativeAngularDisplacement: currentDisplacement)
            }
        }
        else if isAttackCharacter(character) {
            // An attack command finished.
            delegate?.controlInputSourceDidFinishAttacking(self)
        }
        else {
            // Account for the other possible kinds of actions.
            switch character {
                case "p":
                    gameStateDelegate?.controlInputSourceDidTogglePauseState(self)

                default: break
            }
        }
    }
    
    // MARK: ControlInputSourceType
    
    func resetControlState() {
        // Reset the `currentDisplacement` and clear the currently tracked keys.
        currentDisplacement = float2()
        downKeys.removeAll()
        
        delegate?.controlInputSource(self, didUpdateWithRelativeDisplacement: currentDisplacement)
        delegate?.controlInputSource(self, didUpdateWithRelativeAngularDisplacement: currentDisplacement)
    }
    
    // MARK: Convenience
    
    private func isDirectionalDisplacementVector(_ displacement: float2) -> Bool {
        return displacement == KeyboardControlInputSource.forwardVector
            || displacement == KeyboardControlInputSource.backwardVector
    }
    
    private func relativeDisplacementForCharacter(_ character: Character) -> float2? {
        let mapping: [Character: float2] = [
            // Up arrow.
            Character(UnicodeScalar(0xF700)!):   KeyboardControlInputSource.forwardVector,
            "w":                                 KeyboardControlInputSource.forwardVector,
            
            // Down arrow.
            Character(UnicodeScalar(0xF701)!):   KeyboardControlInputSource.backwardVector,
            "s":                                 KeyboardControlInputSource.backwardVector,
            
            // Left arrow.
            Character(UnicodeScalar(0xF702)!):   KeyboardControlInputSource.counterClockwiseVector,
            "a":                                 KeyboardControlInputSource.counterClockwiseVector,
            
            // Right arrow.
            Character(UnicodeScalar(0xF703)!):   KeyboardControlInputSource.clockwiseVector,
            "d":                                 KeyboardControlInputSource.clockwiseVector
        ]
        
        return mapping[character]
    }
    
    /// Indicates if the provided character should trigger an attack.
    private func isAttackCharacter(_ character: Character) -> Bool {
        return ["f", " ", "\r"].contains(character)
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An implementation of the `ControlInputSourceType` protocol that enables support for `GCController`s on all platforms.
*/

import SpriteKit
import GameController

class GameControllerInputSource: ControlInputSourceType {
    // MARK: Properties
    
    /// `ControlInputSourceType` delegates.
    weak var gameStateDelegate: ControlInputSourceGameStateDelegate?
    weak var delegate: ControlInputSourceDelegate?
    
    let allowsStrafing = true

    let gameController: GCController

    // MARK: Initializers
    
    init(gameController: GCController) {
        self.gameController = gameController
        
        registerPauseEvent()
        registerAttackEvents()
        registerMovementEvents()
        registerRotationEvents()
    }
    
    // MARK: Gamepad Registration Methods
    
    private func registerPauseEvent() {
        gameController.controllerPausedHandler = { [unowned self] _ in
            self.gameStateDelegate?.controlInputSourceDidTogglePauseState(self)
        }
    }
    
    private func registerAttackEvents() {
        /// A handler for button press events that trigger an attack action.
        let attackHandler: GCControllerButtonValueChangedHandler = { [unowned self] button, _, pressed in
            if pressed {
                self.delegate?.controlInputSourceDidBeginAttacking(self)

                #if os(tvOS)
                if let microGamepad = self.gameController.microGamepad, button == microGamepad.buttonA || button == microGamepad.buttonX {
                    self.gameStateDelegate?.controlInputSourceDidSelect(self)
                }
                #else
                if let gamepad = self.gameController.gamepad, button == gamepad.buttonA || button == gamepad.buttonX {
                    self.gameStateDelegate?.controlInputSourceDidSelect(self)
                }
                #endif
            }
            else {
                self.delegate?.controlInputSourceDidFinishAttacking(self)
            }
        }
        
        #if os(tvOS)
        // `GCMicroGamepad` button handlers.
        if let microGamepad = gameController.microGamepad {
            microGamepad.buttonA.pressedChangedHandler = attackHandler
            microGamepad.buttonX.pressedChangedHandler = attackHandler
        }
        #endif
    
        // `GCGamepad` button handlers.
        if let gamepad = gameController.gamepad {
            /*
                Assign an action to every button, even if this means that multiple
                buttons provide the same functionality. It's better to have repeated
                functionality than to have a button that doesn't do anything.
            */
            gamepad.buttonA.pressedChangedHandler = attackHandler
            gamepad.buttonB.pressedChangedHandler = attackHandler
            gamepad.buttonX.pressedChangedHandler = attackHandler
            gamepad.buttonY.pressedChangedHandler = attackHandler
            gamepad.leftShoulder.pressedChangedHandler = attackHandler
            gamepad.rightShoulder.pressedChangedHandler = attackHandler
        }
        
        // `GCExtendedGamepad` trigger handlers.
        if let extendedGamepad = gameController.extendedGamepad {
            extendedGamepad.rightTrigger.pressedChangedHandler = attackHandler
            extendedGamepad.leftTrigger.pressedChangedHandler  = attackHandler
        }
    }
    
    private func registerMovementEvents() {
        /// An analog movement handler for D-pads and movement thumbsticks.
        let movementHandler: GCControllerDirectionPadValueChangedHandler = { [unowned self] _, xValue, yValue in
            // Move toward the direction of the axis.
            let displacement = float2(x: xValue, y: yValue)
            
            self.delegate?.controlInputSource(self, didUpdateDisplacement: displacement)
            
            if let direction = ControlInputDirection(vector: displacement) {
                self.gameStateDelegate?.controlInputSource(self, didSpecifyDirection: direction)
            }
        }
        
        #if os(tvOS)
        // `GCMicroGamepad` D-pad handler.
        if let microGamepad = gameController.microGamepad {
            // Allow the gamepad to handle transposing D-pad values when rotating the controller.
            microGamepad.allowsRotation = true
            microGamepad.dpad.valueChangedHandler = movementHandler
        }
        #endif
        
        // `GCGamepad` D-pad handler.
        if let gamepad = gameController.gamepad {
            gamepad.dpad.valueChangedHandler = movementHandler 
        }
        
        // `GCExtendedGamepad` left thumbstick.
        if let extendedGamepad = gameController.extendedGamepad {
            extendedGamepad.leftThumbstick.valueChangedHandler = movementHandler
        }
    }
    
    private func registerRotationEvents() {
        // `GCExtendedGamepad` right thumbstick controls rotational attack independent of movement direction.
        if let extendedGamepad = gameController.extendedGamepad {
        
            extendedGamepad.rightThumbstick.valueChangedHandler = { [unowned self] _, xValue, yValue in
                // Rotate by the angle formed from the supplied axis.
                let angularDisplacement = float2(x: xValue, y: yValue)
                
                self.delegate?.controlInputSource(self, didUpdateAngularDisplacement: angularDisplacement)
                
                // Attack while rotating. This closely mirrors the behavior of the iOS touch controls.
                if length(angularDisplacement) > 0 {
                    self.delegate?.controlInputSourceDidBeginAttacking(self)
                }
                else {
                    self.delegate?.controlInputSourceDidFinishAttacking(self)
                }
            }
        }
    }
    
    // MARK: ControlInputSourceType
    
    func resetControlState() {
        /*
            Check the current values of the dpad and right thumbstick to see if
            any direction is currently being requested for focused based navigation.
        
            This allows for continuous scrolling while using game controllers.
        */
        guard let dpad = gameController.gamepad?.dpad else { return }
        let dpadDisplacement = float2(x: dpad.xAxis.value, y: dpad.yAxis.value)
        
        if let inputDirection = ControlInputDirection(vector: dpadDisplacement) {
            gameStateDelegate?.controlInputSource(self, didSpecifyDirection: inputDirection)
            return
        }
        
        guard let thumbStick = gameController.extendedGamepad?.leftThumbstick else { return }
        let thumbStickDisplacement = float2(x: thumbStick.xAxis.value, y: thumbStick.yAxis.value)
        
        if let inputDirection = ControlInputDirection(vector: thumbStickDisplacement) {
            gameStateDelegate?.controlInputSource(self, didSpecifyDirection: inputDirection)
        }
    }

}


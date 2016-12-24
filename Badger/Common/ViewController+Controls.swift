/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Handles keyboard (macOS), touch (iOS) and controller (iOS, tvOS) input for controlling the game.
*/

import GameKit

#if os(OSX)
protocol KeyboardEventsDelegate {
    func keyDown(in view: NSView, with event: NSEvent) -> Bool
    func keyUp(in view: NSView, with event: NSEvent) -> Bool
}
    
private enum KeyboardDirection: UInt16 {
    case left   = 123
    case right  = 124
    case down   = 125
    case up     = 126
}
    
extension ViewController: KeyboardEventsDelegate {}
#endif

extension ViewController {
    
    // MARK: Game Controller Events

    func setupGameControllers() {
        #if os(OSX)
        sceneView.eventsDelegate = self
        #endif
        
        #if os(iOS) || os(tvOS)
        // Gesture recognizers
        let directions: [UISwipeGestureRecognizerDirection] = [.right, .left, .up, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe))
            gesture.direction = direction
            sceneView.addGestureRecognizer(gesture)
        }
        #endif
    }
    
    @objc func handleControllerDidConnectNotification(_ notification: NSNotification) {
        let gameController = notification.object as! GCController
        registerCharacterMovementEvents(gameController)
    }

    private func registerCharacterMovementEvents(_ gameController: GCController) {
        // An analog movement handler for D-pads and thumbsticks.
        let movementHandler: GCControllerDirectionPadValueChangedHandler = { [unowned self] dpad, _, _ in
            self.controllerDPad = dpad
        }
        
        #if os(tvOS)
            
        // Apple TV remote
        if let microGamepad = gameController.microGamepad {
            // Allow the gamepad to handle transposing D-pad values when rotating the controller.
            microGamepad.allowsRotation = true
            microGamepad.dpad.valueChangedHandler = movementHandler
        }
            
        #endif
        
        // Gamepad D-pad
        if let gamepad = gameController.gamepad {
            gamepad.dpad.valueChangedHandler = movementHandler
        }
        
        // Extended gamepad left thumbstick
        if let extendedGamepad = gameController.extendedGamepad {
            extendedGamepad.leftThumbstick.valueChangedHandler = movementHandler
        }
    }
    
    // MARK: Touch Events
    
    #if os(iOS) || os(tvOS)
    func didSwipe(sender: UISwipeGestureRecognizer) {
        if startGameIfNeeded() {
            return
        }
    
        switch sender.direction {
            case UISwipeGestureRecognizerDirection.up: jump()
            case UISwipeGestureRecognizerDirection.down: squat()
            case UISwipeGestureRecognizerDirection.left: leanLeft()
            case UISwipeGestureRecognizerDirection.right: leanRight()
            default: break
        }
    }
    #endif
    
    // MARK: Keyboard Events
    
    #if os(OSX)
    func keyDown(in view: NSView, with event: NSEvent) -> Bool {
        if event.isARepeat {
            return true
        }
        
        if startGameIfNeeded() {
            return true
        }

        if let direction = KeyboardDirection(rawValue: event.keyCode) {
            switch direction {
                case .up: jump()
                case .down: squat()
                case .left: leanLeft()
                case .right: leanRight()
            }
            return true
        }
        return false
    }
    
    func keyUp(in view: NSView, with event: NSEvent) -> Bool {
        let direction = KeyboardDirection(rawValue: event.keyCode)
        return direction != nil ? true : false
    }
    #endif
}

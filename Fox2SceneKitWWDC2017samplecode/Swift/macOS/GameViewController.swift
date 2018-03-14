/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The app's main view controller.
 */

import Cocoa
import SceneKit

class GameViewControllerMacOS: NSViewController {
    var gameView: GameViewMacOS {
        guard let gameView = view as? GameViewMacOS else {
            fatalError("Expected \(GameViewMacOS.self) from Main.storyboard.")
        }
        return gameView
    }
    
    var gameController: GameController?

    override func viewDidLoad() {
        super.viewDidLoad()

        gameController = GameController(scnView: gameView)

        // Configure the view
        gameView.backgroundColor = NSColor.black

        // Link view and controller
        gameView.viewController = self
    }
    
    func keyDown(_ view: NSView, event theEvent: NSEvent) -> Bool {
        var characterDirection = self.gameController!.characterDirection
        var cameraDirection = self.gameController!.cameraDirection

        var updateCamera = false
        var updateCharacter = false

        switch theEvent.keyCode {
            case 126:
                // Up
                if !theEvent.isARepeat {
                    characterDirection.y = -1
                    updateCharacter = true
                }
            case 125:
                // Down
                if !theEvent.isARepeat {
                    characterDirection.y = 1
                    updateCharacter = true
                }
            case 123:
                // Left
                if !theEvent.isARepeat {
                    characterDirection.x = -1
                    updateCharacter = true
                }
            case 124:
                // Right
                if !theEvent.isARepeat {
                    characterDirection.x = 1
                    updateCharacter = true
                }
            case 13:
                // Camera Up
                if !theEvent.isARepeat {
                    cameraDirection.y = -1
                    updateCamera = true
                }
            case 1:
                // Camera Down
                if !theEvent.isARepeat {
                    cameraDirection.y = 1
                    updateCamera = true
                }
            case 0:
                // Camera Left
                if !theEvent.isARepeat {
                    cameraDirection.x = -1
                    updateCamera = true
                }
            case 2:
                // Camera Right
                if !theEvent.isARepeat {
                    cameraDirection.x = 1
                    updateCamera = true
                }
            case 49:
                // Space
                if !theEvent.isARepeat {
                    gameController!.controllerJump(true)
                }
                return true
            case 8:
                // c
                if !theEvent.isARepeat {
                    gameController!.controllerAttack()
                }
                return true
        default:
            return false
        }

        if updateCharacter {
            self.gameController?.characterDirection = characterDirection.allZero() ? characterDirection: simd_normalize(characterDirection)
        }

        if updateCamera {
            self.gameController?.cameraDirection = cameraDirection.allZero() ? cameraDirection: simd_normalize(cameraDirection)
        }

        return true
    }

    func keyUp(_ view: NSView, event theEvent: NSEvent) -> Bool {
        var characterDirection = gameController!.characterDirection
        var cameraDirection = gameController!.cameraDirection

        var updateCamera = false
        var updateCharacter = false

        switch theEvent.keyCode {
            case 36:
                if !theEvent.isARepeat {
                    gameController!.resetPlayerPosition()
                }
                return true
            case 126:
                // Up
                if !theEvent.isARepeat && characterDirection.y < 0 {
                    characterDirection.y = 0
                    updateCharacter = true
                }
            case 125:
                // Down
                if !theEvent.isARepeat && characterDirection.y > 0 {
                    characterDirection.y = 0
                    updateCharacter = true
                }
            case 123:
                // Left
                if !theEvent.isARepeat && characterDirection.x < 0 {
                    characterDirection.x = 0
                    updateCharacter = true
                }
            case 124:
                // Right
                if !theEvent.isARepeat && characterDirection.x > 0 {
                    characterDirection.x = 0
                    updateCharacter = true
                }
            case 13:
                // Camera Up
                if !theEvent.isARepeat && cameraDirection.y < 0 {
                    cameraDirection.y = 0
                    updateCamera = true
                }
            case 1:
                // Camera Down
                if !theEvent.isARepeat && cameraDirection.y > 0 {
                    cameraDirection.y = 0
                    updateCamera = true
                }
            case 0:
                // Camera Left
                if !theEvent.isARepeat && cameraDirection.x < 0 {
                    cameraDirection.x = 0
                    updateCamera = true
                }
            case 2:
                // Camera Right
                if !theEvent.isARepeat && cameraDirection.x > 0 {
                    cameraDirection.x = 0
                    updateCamera = true
                }

            case 49:
                // Space
                if !theEvent.isARepeat {
                    gameController!.controllerJump(false)
                }
                return true
            default:
                break
        }
        
        if updateCharacter {
            self.gameController?.characterDirection = characterDirection.allZero() ? characterDirection: simd_normalize(characterDirection)
            return true
        }

        if updateCamera {
            self.gameController?.cameraDirection = cameraDirection.allZero() ? cameraDirection: simd_normalize(cameraDirection)
            return true
        }

        return false
    }
}

class GameViewMacOS: SCNView {
    weak var viewController: GameViewControllerMacOS?

    // MARK: - EventHandler

    override func keyDown(with theEvent: NSEvent) {
        if viewController?.keyDown(self, event: theEvent) == false {
            super.keyDown(with: theEvent)
        }
    }

    override func keyUp(with theEvent: NSEvent) {
        if viewController?.keyUp(self, event: theEvent) == false {
            super.keyUp(with: theEvent)
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        (overlaySKScene as? Overlay)?.layout2DOverlay()
    }

    override func viewDidMoveToWindow() {
        //disable retina
        layer?.contentsScale = 1.0
    }
}

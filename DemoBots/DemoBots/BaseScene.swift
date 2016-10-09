/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The base class for all scenes in the app.
*/

import SpriteKit

#if os(iOS)
import ReplayKit
#endif

/**
    A base class for all of the scenes in the app.
*/
class BaseScene: SKScene, GameInputDelegate, ControlInputSourceGameStateDelegate {
    // MARK: Properties

    #if os(iOS)
    /// ReplayKit preview view controller used when viewing recorded content.
    var previewViewController: RPPreviewViewController?
    #endif
    
    /**
        The native size for this scene. This is the height at which the scene
        would be rendered if it did not need to be scaled to fit a window or device.
        Defaults to `zeroSize`; the actual value to use is set in `createCamera()`.
    */
    var nativeSize = CGSize.zero
    
    /**
        The background node for this `BaseScene` if needed. Provided by those subclasses
        that use a background scene in their SKS file to center the scene on screen.
    */
    var backgroundNode: SKSpriteNode? {
        return nil
    }
    
    /// All buttons currently in the scene. Updated by assigning the result of `findAllButtonsInScene()`.
    var buttons = [ButtonNode]()
    
    /**
        A flag to indicate if focus based navigation is currently enabled. Also
        used to ensure buttons are navigated at a reasonable rate by toggling this
        flag after a short delay in `controlInputSource(_: didSpecifyDirection:)`.
    */
    var focusChangesEnabled = false
    
    /// The current scene overlay (if any) that is displayed over this scene.
    var overlay: SceneOverlay? {
        didSet {
            // Clear the `buttons` in preparation for new buttons in the overlay.
            buttons = []
            
            if let overlay = overlay, let camera = camera {
                overlay.backgroundNode.removeFromParent()
                camera.addChild(overlay.backgroundNode)
                
                // Animate the overlay in.
                overlay.backgroundNode.alpha = 0.0
                overlay.backgroundNode.run(SKAction.fadeIn(withDuration: 0.25))
                overlay.updateScale()

                buttons = findAllButtonsInScene()
                
                // Reset the focus.
                resetFocus()
            }
            
            // Animate the old overlay out.
            oldValue?.backgroundNode.run(SKAction.fadeOut(withDuration: 0.25)) {
                oldValue?.backgroundNode.removeFromParent()
            }
        }
    }
    
    /// A reference to the scene manager for scene progression.
    weak var sceneManager: SceneManager!
    
    // MARK: SKScene Life Cycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        updateCameraScale()
        overlay?.updateScale()
        
        // Listen for updates to the player's controls.
        sceneManager.gameInput.delegate = self
        
        // Find all the buttons and set the initial focus.
        buttons = findAllButtonsInScene()
        resetFocus()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        updateCameraScale()
        overlay?.updateScale()
    }
    
    // MARK: GameInputDelegate
    
    func gameInputDidUpdateControlInputSources(gameInput: GameInput) {
        // Ensure all player controlInputSources delegate game actions to `BaseScene`.
        for controlInputSource in gameInput.controlInputSources {
            controlInputSource.gameStateDelegate = self
        }
        
        #if os(iOS)
        /*
            On iOS, show or hide touch controls and focus based navigation when 
            game controllers are connected or disconnected.
        */
        touchControlInputNode.hideThumbStickNodes = sceneManager.gameInput.isGameControllerConnected
        resetFocus()
        #endif
    }
    
    // MARK: ControlInputSourceGameStateDelegate
    
    func controlInputSourceDidSelect(_ controlInputSource: ControlInputSourceType) {
        focusedButton?.buttonTriggered()
    }
    
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didSpecifyDirection direction: ControlInputDirection) {
        // Check that this scene has focus changes enabled, otherwise ignore.
        guard focusChangesEnabled else { return }
        
        #if os(iOS)
        // On iOS, ensure that a game controller is connected otherwise ignore.
        guard sceneManager.gameInput.isGameControllerConnected else { return }
        #endif
        
        /*
            Create the button focus graph to ensure it represents what's being displayed and
            includes any buttons that may have been added to the scene.
        */
        createButtonFocusGraph()
        
        /*
            Update the focused button to the neighbor of the currently focused button that
            lies in the direction the input source specified.
        */
        if let currentFocusedButton = focusedButton {
            if let newFocusButton = currentFocusedButton.focusableNeighbors[direction] {
                focusedButton = newFocusButton
                
                /*
                    Reset `focusChangesEnabled` after a 0.2 second delay to ensure
                    buttons are traversed at a reasonable rate even in the presence of
                    constant input.
                */
                focusChangesEnabled = false
                let deadline = DispatchTime.now() + DispatchTimeInterval.microseconds(200)
                DispatchQueue.main.asyncAfter(deadline: deadline) {
                    self.focusChangesEnabled = true

                    /* 
                        Resetting the control state will check the current values
                        and possibly call `controlInputSource(_: didSpecifyDirection:)` again.
                    */
                    controlInputSource.resetControlState()
                }
            }
            else {
                // Indicate that a neighboring button does not exist for the requested direction.
                currentFocusedButton.performInvalidFocusChangeAnimationForDirection(direction: direction)
            }
        }
        else {
            // Set the initial focus if there is no currently focused button.
            resetFocus()
        }
    }
    
    func controlInputSourceDidTogglePauseState(_ controlInputSource: ControlInputSourceType) {
        // Subclasses implement to toggle pause state.
    }
    
    #if DEBUG
    func controlInputSourceDidToggleDebugInfo(_ controlInputSource: ControlInputSourceType) {
        // Subclasses implement if necessary, to display useful debug info.
    }
    
    func controlInputSourceDidTriggerLevelSuccess(_ controlInputSource: ControlInputSourceType) {
        // Implemented by subclasses to switch to next level while debugging.
    }
    
    func controlInputSourceDidTriggerLevelFailure(_ controlInputSource: ControlInputSourceType) {
        // Implemented by subclasses to force failing the level while debugging.
    }
    #endif
    
    // MARK: Camera Actions
    
    /**
        Creates a camera for the scene, and updates its scale.
        This method should be called when initializing an instance of a `BaseScene` subclass.
    */
    func createCamera() {
        if let backgroundNode = backgroundNode {
            // If the scene has a background node, use its size as the native size of the scene.
            nativeSize = backgroundNode.size
        }
        else {
            // Otherwise, use the scene's own size as the native size of the scene.
            nativeSize = size
        }
        
        let camera = SKCameraNode()
        self.camera = camera
        addChild(camera)
        
        updateCameraScale()
    }
    
    /// Centers the scene's camera on a given point.
    func centerCameraOnPoint(point: CGPoint) {
        if let camera = camera {
            camera.position = point
        }
    }
    
    /// Scales the scene's camera.
    func updateCameraScale() {
        /*
            Because the game is normally playing in landscape, use the scene's current and
            original heights to calculate the camera scale.
        */
        if let camera = camera {
            camera.setScale(nativeSize.height / size.height)
        }
    }
}

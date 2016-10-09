/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An `SKScene` used to represent and manage the home and end scenes of the game.
*/

import SpriteKit

class HomeEndScene: BaseScene {
    // MARK: Properties
    
    /// Returns the background node from the scene.
    override var backgroundNode: SKSpriteNode? {
        return childNode(withName: "backgroundNode") as? SKSpriteNode
    }
    
    /// The screen recorder button for the scene (if it has one).
    var screenRecorderButton: ButtonNode? {
        return backgroundNode?.childNode(withName: ButtonIdentifier.screenRecorderToggle.rawValue) as? ButtonNode
    }
    
    /// The "NEW GAME" button which allows the player to proceed to the first level.
    var proceedButton: ButtonNode? {
        return backgroundNode?.childNode(withName: ButtonIdentifier.proceedToNextScene.rawValue) as? ButtonNode
    }

    /// An array of objects for `SceneLoader` notifications.
    private var sceneLoaderNotificationObservers = [Any]()

    // MARK: Deinitialization
    
    deinit {
        // Deregister for scene loader notifications.
        for observer in sceneLoaderNotificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: Scene Life Cycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        #if os(iOS)
        screenRecorderButton?.isSelected = screenRecordingToggleEnabled
        #else
        screenRecorderButton?.isHidden = true
        #endif
        
        // Enable focus based navigation. 
        focusChangesEnabled = true
        
        registerForNotifications()
        centerCameraOnPoint(point: backgroundNode!.position)
        
        // Begin loading the first level as soon as the view appears.
        sceneManager.prepareScene(identifier: .level(1))
        
        let levelLoader = sceneManager.sceneLoader(forSceneIdentifier: .level(1))
        
        // If the first level is not ready, hide the buttons until we are notified.
        if !(levelLoader.stateMachine.currentState is SceneLoaderResourcesReadyState) {
            proceedButton?.alpha = 0.0
            proceedButton?.isUserInteractionEnabled = false
            
            screenRecorderButton?.alpha = 0.0
            screenRecorderButton?.isUserInteractionEnabled = false
        }
    }
    
    func registerForNotifications() {
        // Only register for notifications if we haven't done so already.
        guard sceneLoaderNotificationObservers.isEmpty else { return }
        
        // Create a closure to pass as a notification handler for when loading completes or fails.
        let handleSceneLoaderNotification: (Notification) -> () = { [unowned self] notification in
            let sceneLoader = notification.object as! SceneLoader
            
            // Show the proceed button if the `sceneLoader` pertains to a `LevelScene`.
            if sceneLoader.sceneMetadata.sceneType is LevelScene.Type {
                // Allow the proceed and screen to be tapped or clicked.
                self.proceedButton?.isUserInteractionEnabled = true
                self.screenRecorderButton?.isUserInteractionEnabled = true

                // Fade in the proceed and screen recorder buttons.
                self.screenRecorderButton?.run(SKAction.fadeIn(withDuration: 1.0))

                // Clear the initial `proceedButton` focus.
                self.proceedButton?.isFocused = false
                self.proceedButton?.run(SKAction.fadeIn(withDuration: 1.0)) {
                    // Indicate that the `proceedButton` is focused.
                    self.resetFocus()
                }
            }
        }
        
        // Register for scene loader notifications.
        let completeNotification = NotificationCenter.default.addObserver(forName: NSNotification.Name.SceneLoaderDidCompleteNotification, object: nil, queue: OperationQueue.main, using: handleSceneLoaderNotification)
        let failNotification = NotificationCenter.default.addObserver(forName: NSNotification.Name.SceneLoaderDidFailNotification, object: nil, queue: OperationQueue.main, using: handleSceneLoaderNotification)
        
        // Keep track of the notifications we are registered to so we can remove them in `deinit`.
        sceneLoaderNotificationObservers += [completeNotification, failNotification]
    }
}

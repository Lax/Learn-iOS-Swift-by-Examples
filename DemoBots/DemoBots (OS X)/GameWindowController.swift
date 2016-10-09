/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An `NSWindowController` subclass to simplify the game's interaction with window resizing on OS X.
*/

import Cocoa
import SpriteKit

class GameWindowController: NSWindowController, NSWindowDelegate {
    // MARK: Properties
    
    var view: SKView {
        let gameViewController = window!.contentViewController as! GameViewController
        return gameViewController.view as! SKView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        window?.delegate = self
    }
    
    // MARK: NSWindowDelegate
    func windowWillStartLiveResize(_ notification: Notification) {
        // Pause the scene while the window resizes if the game is active.
        if let levelScene = view.scene as? LevelScene, levelScene.stateMachine.currentState is LevelSceneActiveState {
            levelScene.isPaused = true
        }
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        // Un-pause the scene when the window stops resizing if the game is active.
        if let levelScene = view.scene as? LevelScene, levelScene.stateMachine.currentState is LevelSceneActiveState {
            levelScene.isPaused = false
        }
    }
    
    // OS X games that use a single window for the entire game should quit when that window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}

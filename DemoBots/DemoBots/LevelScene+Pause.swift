/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension on `LevelScene` which ensures that game play is paused when the app enters the background for a number of user initiated events.
*/

#if os(OSX)
import AppKit
#else
import UIKit
#endif

extension LevelScene {
    // MARK: Properties
    
    /**
        The scene's `paused` property is set automatically when the
        app enters the background. Override to check if an `overlay` node is
        being presented to determine if the game should be paused.
    */
    override var paused: Bool {
        didSet {
            if overlay != nil {
                worldNode.paused = true
            }
        }
    }
    
    /// Platform specific notifications about the app becoming inactive.
    var pauseNotificationNames: [String] {
        #if os(OSX)
        return [
            NSApplicationWillResignActiveNotification,
            NSWindowDidMiniaturizeNotification
        ]
        #else
        return [
            UIApplicationWillResignActiveNotification
        ]
        #endif
    }
    
    // MARK: Convenience
    
    /**
        Register for notifications about the app becoming inactive in
        order to pause the game. 
    */
    func registerForPauseNotifications() {
        for notificationName in pauseNotificationNames {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LevelScene.pauseGame), name: notificationName, object: nil)
        }
    }
    
    func pauseGame() {
        stateMachine.enterState(LevelScenePauseState.self)
    }
    
    func unregisterForPauseNotifications() {
        for notificationName in pauseNotificationNames {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: notificationName, object: nil)
        }
    }
}
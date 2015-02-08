/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Application delegate for the OS X version of Adventure.
*/


import SpriteKit

    class AdventureWindow: NSWindow {}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    // MARK: Properties

    var scene: AdventureScene!
    
    @IBOutlet weak var coverView: NSView!
    
    @IBOutlet weak var view: SKView!
    
    @IBOutlet weak var loadingProgressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var gameLogo: NSImageView!
    
    @IBOutlet weak var archerButton: NSButton!
    
    @IBOutlet weak var warriorButton: NSButton!
    
    var adventureWindow: NSWindow {
        let windows = NSApplication.sharedApplication().windows as [NSWindow]
        
        for window in windows {
            if window.isKindOfClass(AdventureWindow.self) {
                return window
            }
        }
        
        fatalError("There should always be an Adventure window.")
    }

    // MARK: Application Life Cycle

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        loadingProgressIndicator.startAnimation(self)

        AdventureScene.loadSceneAssetsWithCompletionHandler { loadedScene in
            let adventureWindow = self.adventureWindow
            
            adventureWindow.delegate = self
            self.scene = loadedScene
            
            let windowRect = adventureWindow.contentRectForFrameRect(adventureWindow.frame)
            self.scene.size = windowRect.size
            
            self.scene.finishedMovingToView = {
                // Remove the cover view so the user can see the scene.
                self.coverView.removeFromSuperview()
                
                // Stop the loading indicator once the scene is completely loaded.
                self.loadingProgressIndicator.stopAnimation(self)
                self.loadingProgressIndicator.hidden = true
                
                // Show the character selection buttons so the user can start playing.
                self.archerButton.alphaValue = 1.0
                self.warriorButton.alphaValue = 1.0
            }
            
            self.view.presentScene(self.scene)
        }

        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        view.showsDrawCount = true
        #endif
    }
    
    // MARK: NSWindowDelegate
    
    func windowWillResize(sender: NSWindow, toSize frameSize: NSSize) -> NSSize {
        scene.paused = true
        return frameSize
    }
    
    func windowDidResize(notification: NSNotification) {
        let window = notification.object as NSWindow
        let windowSize = window.contentRectForFrameRect(window.frame)
        
        scene.size = CGSize(width: windowSize.width, height: windowSize.height)
        view.frame.size = CGSize(width: windowSize.width, height: windowSize.height)
        
        scene.paused = false
    }
    
    // MARK: IBActions

    @IBAction func chooseArcher(_: AnyObject) {
        scene.startLevel(.Archer)
        gameLogo.hidden = true

        archerButton.alphaValue = 0.0
        warriorButton.alphaValue = 0.0
    }

    @IBAction func chooseWarrior(_: AnyObject) {
        scene.startLevel(.Warrior)
        gameLogo.hidden = true

        archerButton.alphaValue = 0.0
        warriorButton.alphaValue = 0.0
    }
}

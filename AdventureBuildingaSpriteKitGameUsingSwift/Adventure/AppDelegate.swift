/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Application delegate for OS X Adventure
      
*/


import SpriteKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var scene: AdventureScene!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        loadingProgressIndicator.startAnimation(self)

        AdventureScene.loadSceneAssetsWithCompletionHandler {
            self.scene = AdventureScene(size: CGSize(width: 1024, height: 768))
            self.scene.scaleMode = SKSceneScaleMode.AspectFit

            self.skView.presentScene(self.scene)

            self.loadingProgressIndicator.stopAnimation(self)
            self.loadingProgressIndicator.hidden = true

            self.archerButton.alphaValue = 1.0
            self.warriorButton.alphaValue = 1.0
        }

        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsDrawCount = true
    }

    @IBAction func chooseArcher(sender: AnyObject) {
        scene.startLevel(.Archer)
        gameLogo.hidden = true

        archerButton.alphaValue = 0.0
        warriorButton.alphaValue = 0.0
    }

    @IBAction func chooseWarrior(sender: AnyObject) {
        scene.startLevel(.Warrior)
        gameLogo.hidden = true

        archerButton.alphaValue = 0.0
        warriorButton.alphaValue = 0.0
    }

    @IBOutlet var skView: SKView
    @IBOutlet var loadingProgressIndicator: NSProgressIndicator
    @IBOutlet var gameLogo: NSImageView
    @IBOutlet var archerButton : NSButton
    @IBOutlet var warriorButton : NSButton
}

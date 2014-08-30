/*
  Copyright (C) 2014 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  
        Defines the iOS view controller for Adventure
      
*/

import SpriteKit

class ViewController: UIViewController {
    @IBOutlet var skView: SKView
    @IBOutlet var imageView: UIImageView
    @IBOutlet var gameLogo: UIImageView
    @IBOutlet var loadingProgressIndicator: UIActivityIndicatorView
    @IBOutlet var archerButton: UIButton
    @IBOutlet var warriorButton: UIButton
    
    var scene: AdventureScene!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Start the progress indicator animation.
        loadingProgressIndicator.startAnimating()

        AdventureScene.loadSceneAssetsWithCompletionHandler {
            var viewSize = self.view.bounds.size

            // On iPhone/iPod touch we want to see a similar amount of the scene as on iPad.
            // So, we set the size of the scene to be double the size of the view, which is
            // the whole screen, 3.5- or 4- inch. This effectively scales the scene to 50%.
            if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                viewSize.height *= 2
                viewSize.width *= 2
            }

            self.scene = AdventureScene(size: viewSize)
            self.scene.scaleMode = .AspectFill

            self.loadingProgressIndicator.stopAnimating()
            self.loadingProgressIndicator.hidden = true

            self.skView.showsDrawCount = true
            self.skView.showsFPS = true

            self.skView.presentScene(self.scene)

            UIView.animateWithDuration(2.0) {
                self.archerButton.alpha = 1.0
                self.warriorButton.alpha = 1.0
            }
        }
    }

    @IBAction func chooseArcher(_: AnyObject) {
        scene.startLevel(.Archer)
        gameLogo.hidden = true 
        warriorButton.hidden = true
        archerButton.hidden = true
    }

    @IBAction func chooseWarrior(_: AnyObject) {
        scene.startLevel(.Warrior)
        gameLogo.hidden = true 
        warriorButton.hidden = true
        archerButton.hidden = true
    }
}


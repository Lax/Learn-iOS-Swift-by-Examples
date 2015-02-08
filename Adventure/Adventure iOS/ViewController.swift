/*
  Copyright (C) 2015 Apple Inc. All Rights Reserved.
  See LICENSE.txt for this sample’s licensing information
  
  Abstract:
  Defines the iOS view controller for Adventure.
*/

import SpriteKit

class ViewController: UIViewController {
    // MARK: Properties

    @IBOutlet weak var coverView: UIImageView!
    
    @IBOutlet weak var skView: SKView!

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var gameLogo: UIImageView!
    
    @IBOutlet weak var loadingProgressIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var archerButton: UIButton!
    
    @IBOutlet weak var warriorButton: UIButton!
    
    var scene: AdventureScene!
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        // On iPhone/iPod touch we want to see a similar amount of the scene as on iPad.
        // So, we set the scale of the image to be used to double the scale of the image,
        // This effectively scales the cover image to 50%, matching the scene scaling.
        var image = UIImage(named: "cover")!
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            image = UIImage(CGImage: image.CGImage, scale: image.scale * 2.0, orientation: UIImageOrientation.Up)!
        }

        coverView.image = image
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Start the progress indicator animation.
        loadingProgressIndicator.startAnimating()

        AdventureScene.loadSceneAssetsWithCompletionHandler { loadedScene in
            var viewSize = self.view.bounds.size

            // On iPhone/iPod touch we want to see a similar amount of the scene as on iPad.
            // So, we set the size of the scene to be double the size of the view, which is
            // the whole screen, 3.5- or 4- inch. This effectively scales the scene to 50%.
            if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
                viewSize.height *= 2
                viewSize.width *= 2
            }

            self.scene = loadedScene
            self.scene.size = viewSize
            self.scene.scaleMode = .AspectFill

            #if DEBUG
            self.skView.showsDrawCount = true
            self.skView.showsFPS = true
            #endif

            self.scene.finishedMovingToView = {
                UIView.animateWithDuration(2.0, animations: {
                    self.archerButton.alpha = 1.0
                    self.warriorButton.alpha = 1.0
                    self.coverView.alpha = 0.0
                }, completion: { finished in
                    self.loadingProgressIndicator.stopAnimating()
                    self.loadingProgressIndicator.hidden = true
                    self.coverView.removeFromSuperview()
                })
            }

            self.skView.presentScene(self.scene)
        }
    }
    
    // MARK: IBActions

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


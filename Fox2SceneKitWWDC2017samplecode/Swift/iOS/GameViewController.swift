/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The app's main view controller.
 */

import SceneKit
import UIKit

class GameViewControllerIOS: UIViewController {
    
    var gameView: SCNView {
        return view as! SCNView
    }
    
    var gameController: GameController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1.3x on iPads
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.gameView.contentScaleFactor = min(1.3, self.gameView.contentScaleFactor)
            self.gameView.preferredFramesPerSecond = 60
        }
        
        gameController = GameController(scnView: gameView)

        // Configure the view
        gameView.backgroundColor = UIColor.black
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    override var shouldAutorotate: Bool { return true }
}

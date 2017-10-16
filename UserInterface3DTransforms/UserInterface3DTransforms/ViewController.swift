/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The app's view controller.
 */

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.addSubview( SwitcherView( frame: UIScreen.main.bounds ) )
    }

    // Rotation is disabled for the purposes of this sample.
    override var shouldAutorotate: Bool {
        get { return false }
    }

    // Status bar is hidden for maximum visibility of the demonstration.
    override var prefersStatusBarHidden: Bool {
        get { return true }
    }
    
    // For the purposes of this sample, the controller locks orientation to portrait mode.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get { return .portrait }
    }
}


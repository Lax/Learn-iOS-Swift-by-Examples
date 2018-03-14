/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	A view controller that shows video looping playback via an object that implements the Looper protocol.
*/

import UIKit

class LooperViewController: UIViewController {
    // MARK: Properties

    var looper: Looper?

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        looper?.start(in: view.layer)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        looper?.stop()
    }
}

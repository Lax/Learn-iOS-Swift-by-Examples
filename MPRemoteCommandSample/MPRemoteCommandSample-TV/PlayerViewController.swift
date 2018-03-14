/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `PlayerViewController` is a subclass of `UIViewController` with a `PlayerView` as its `view` and is used to play the HLS asset
 */

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {
    
    // MARK: Properties
    
    var playerView: PlayerView {
        get {
            return view as! PlayerView
        }
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `PlayerView` is a subclass of `UIView` with a layerClass of `AVPlayerLayer`.
 */

import UIKit
import AVFoundation

class PlayerView: UIView {
    
    // MARK: Properties
    
    /// The `AVPlayer` associated with the `AVPlayerLayer` of `PlayerView`.
    var player: AVPlayer? {
        get {
            return playerLayer().player
        }
        
        set {
            playerLayer().player = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    /// This is a convenience method for easily getting the layer associated with the `PlayerView` casted as an `AVPlayerLayer`.
    func playerLayer() -> AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
}

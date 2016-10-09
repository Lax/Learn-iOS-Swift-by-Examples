/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that enables an animated entity to track its current orientation (i.e. the direction it is facing). This information is used when choosing an appropriate animation.
*/

import SpriteKit
import GameplayKit

class OrientationComponent: GKComponent {
    // MARK: Properties
    
    var zRotation: CGFloat = 0.0 {
        didSet {
            let twoPi = CGFloat(M_PI * 2)
            zRotation = (zRotation + twoPi).truncatingRemainder(dividingBy: twoPi)
        }
    }
    
    var compassDirection: CompassDirection {
        get {
            return CompassDirection(zRotation: zRotation)
        }
        
        set {
            zRotation = newValue.zRotation
        }
    }
}

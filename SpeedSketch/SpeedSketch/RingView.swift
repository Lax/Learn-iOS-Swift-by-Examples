/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The custom views used in the ring control.
*/

import UIKit

enum RingControlState {
    case selected
    case normal
    case locationFan
    case locationOrigin
}

class RingView: UIView {
    /// Closures that configure the view for the corresponding state.
    var stateClosures = [RingControlState : (()->())]()
    var selected = false
    var fannedOut = false
    
    /// The actionClosure will be executed on selection.
    var actionClosure: (() -> ())?
    
    
    var selectionState: (()->())? {
        if selected {
            return stateClosures[.selected]
        } else {
            return stateClosures[.normal]
        }
    }
    var locationState: (()->())? {
        if selected {
            if fannedOut {
                return stateClosures[.locationFan]
            } else {
                return stateClosures[.locationOrigin]
            }
        } else {
            let fanState = stateClosures[.locationFan]
            let transform = fannedOut ? CGAffineTransform.identity : CGAffineTransform.init(scaleX: 0.01, y: 0.01)
            let alpha: CGFloat = fannedOut ? 1.0 : 0.0
            return { [unowned self]()->() in
                fanState?()
                self.transform = transform
                self.alpha = alpha
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        let layer = self.layer
        layer.cornerRadius = frame.width / 2.0
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 2.0
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Quadrance as the square of the length requires less computation and cases
        let quadrance = (bounds.center - point).quadrance
        let maxQuadrance = pow(bounds.width/2.0, 2.0)
        return quadrance < maxQuadrance
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



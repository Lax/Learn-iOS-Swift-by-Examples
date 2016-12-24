/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The content of the scroll view. Adds some margin and a shadow. Setting the documentView places this view, and sizes it to the canvasSize.
*/

import UIKit

class CanvasContainerView : UIView {
    let canvasSize: CGSize
    
    let canvasView: UIView
    
    var documentView: UIView? {
        willSet {
            if let previousView = documentView {
                previousView.removeFromSuperview()
            }
        }
        didSet {
            if let newView = documentView {
                newView.frame = canvasView.bounds
                canvasView.addSubview(newView)
            }
        }
    }
    
    required init(canvasSize: CGSize) {
        let screenBounds = UIScreen.main.bounds
        let minDimension = max(screenBounds.width, screenBounds.height)
        self.canvasSize = canvasSize
        let baseInset = CGFloat(44.0)
        var size = canvasSize + (baseInset * 2)
        size.width  = max(minDimension, size.width)
        size.height = max(minDimension, size.height)
        
        let frame = CGRect(origin: .zero, size: size)
        
        let canvasOrigin = CGPoint(x: (frame.width - canvasSize.width) / 2.0, y: (frame.height - canvasSize.height) / 2.0)
        let canvasFrame = CGRect(origin: canvasOrigin, size: canvasSize)
        canvasView = UIView(frame:canvasFrame)
        canvasView.backgroundColor = UIColor.white
        canvasView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        canvasView.layer.shadowRadius = 4.0
        canvasView.layer.shadowColor = UIColor.darkGray.cgColor
        canvasView.layer.shadowOpacity = 1.0
        
        super.init(frame:frame)
        self.backgroundColor = UIColor.lightGray
        self.addSubview(canvasView)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

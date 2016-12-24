/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `MapOverlayView` draws the circle over the `MapViewController`.
*/

import MapKit

/**
    A simple `UIView` subclass to draw a selection circle over
    a MKMapView of the same size.
*/
class MapOverlayView: UIView {
    
    /**
        Draws a dashed circle in the center of the `rect` with
        a radius 1/4th of the `rect`'s smallest side.
    */
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        
        let strokeColor = UIColor.blueColor()
        
        let circleDiameter: CGFloat = min(rect.width, rect.height) / 2.0
        let circleRadius = circleDiameter / 2.0
        let cirlceRect = CGRect(x: rect.midX - circleRadius, y: rect.midY - circleRadius, width: circleDiameter, height: circleDiameter)
        let circlePath = UIBezierPath(ovalInRect: cirlceRect)
        
        strokeColor.setStroke()
        circlePath.lineWidth = 3
        CGContextSaveGState(context!)
        CGContextSetLineDash(context!, 0, [6, 6], 2)
        circlePath.stroke()
        CGContextRestoreGState(context!)
    }
    
    /// - returns:  `false` to accept no touches.
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return false
    }
}

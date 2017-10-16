/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates Quartz Blend modes.
 */





import UIKit



class QuartzBlendingView: QuartzView {



    var sourceColor: UIColor = UIColor.white {
        didSet(prevSourceColor) {
            if prevSourceColor != sourceColor {
                setNeedsDisplay()
            }
        }
    }



    var destinationColor: UIColor = UIColor.black {
        didSet(prevDestinationColor) {
            if prevDestinationColor != destinationColor {
                setNeedsDisplay()
            }
        }
    }



    var blendMode: CGBlendMode = .copy {
        didSet(prevBlendMode) {
            if prevBlendMode != blendMode {
                setNeedsDisplay()
            }
        }
    }



    override func drawInContext(_ context: CGContext) {

        // Start with a background whose color we don't use in the demo
        context.setFillColor(gray: 0.2, alpha: 1.0)
        context.fill(bounds)

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:270.0, height:255.0))

        // We want to just lay down the background without any blending so we use the Copy mode rather than Normal
        context.setBlendMode(.copy)

        // Draw a rect with the "background" color - this is the "Destination" for the blending formulas
        context.setFillColor(destinationColor.cgColor)
        context.fill(CGRect(x: 110.0, y: 20.0, width: 100.0, height: 100.0))

        // Set up our blend mode
        context.setBlendMode(blendMode)

        // And draw a rect with the "foreground" color - this is the "Source" for the blending formulas
        context.setFillColor(sourceColor.cgColor)
        context.fill(CGRect(x: 60.0, y: 45.0, width: 200.0, height: 200.0))
    }
    
    
}

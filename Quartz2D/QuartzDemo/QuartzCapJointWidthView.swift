/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates Quartz line drawing facilities including stroke width, line cap and line join.
 */





import UIKit



class QuartzCapJointWidthView: QuartzView {



    var cap: CGLineCap = .butt {
        didSet(prevCapValue) {
            if prevCapValue != cap {
                setNeedsDisplay()
            }
        }
    }



    var join: CGLineJoin = .miter {
        didSet(prevJoinValue) {
            if prevJoinValue != join {
                setNeedsDisplay()
            }
        }
    }



    var width: CGFloat = 1.0 {
        didSet(prevLineWidth) {
            if prevLineWidth != width {
                setNeedsDisplay()
            }
        }
    }



    override func drawInContext(_ context: CGContext) {

        let drawnBounds = CGRect(x:0.0, y:0.0, width:290.0, height:80.0)

        // Drawing lines with a white stroke color
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        // Preserve the current drawing state
        context.savingGState {

            // center the drawing
            centerDrawing(inContext: context, drawingExtent: drawnBounds)

            // Setup the horizontal line to demostrate caps
            context.move(to: CGPoint(x: 40.0, y: 30.0))
            context.addLine(to: CGPoint(x: 280.0, y: 30.0))

            // Set the line width & cap for the cap demo
            context.setLineWidth(width)
            context.setLineCap(cap)
            context.strokePath()
        }

        context.savingGState {

            // center the drawing
            centerDrawing(inContext: context, drawingExtent: drawnBounds)

            // Setup the angled line to demonstrate joins
            context.move(to: CGPoint(x: 40.0, y: 190.0))
            context.addLine(to: CGPoint(x: 160.0, y: 70.0))
            context.addLine(to: CGPoint(x: 280.0, y: 190.0))

            // Set the line width, join, & cap for the cap/join demo
            context.setLineWidth(width)
            context.setLineJoin(join)
            context.setLineCap(cap)
            context.strokePath()
        }

        // center the drawing
        centerDrawing(inContext: context, drawingExtent: drawnBounds)

        // If the stroke width is large enough, display the path that generated these lines
        if width >= 4.0 {  // arbitrarily only show when the line is at least twice as wide as our target stroke
            context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            context.move(to: CGPoint(x: 40.0, y: 30.0))
            context.addLine(to: CGPoint(x: 280.0, y: 30.0))
            context.move(to: CGPoint(x: 40.0, y: 190.0))
            context.addLine(to: CGPoint(x: 160.0, y: 70.0))
            context.addLine(to: CGPoint(x: 280.0, y: 190.0))
            context.setLineWidth(2.0)
            context.strokePath()
        }
    }


}

/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz to stroke  fill rectangles
 */





import UIKit



class QuartzRectView: QuartzView {


    override func drawInContext(_ context: CGContext) {

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:280.0, height:280.0))

        // Drawing lines with a white stroke color
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        // And drawing with a blue fill color
        context.setFillColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        // Draw them with a 2.0 stroke width so they are a bit more visible.
        context.setLineWidth(2.0)


        // Add Rect to the current path, then stroke it
        context.addRect(CGRect(x: 30.0, y: 30.0, width: 60.0, height: 60.0))
        context.strokePath()

        // Stroke Rect convenience that is equivalent to above
        context.stroke(CGRect(x: 30.0, y: 120.0, width: 60.0, height: 60.0))

        // Stroke rect convenience equivalent to the above with built-in call to CGContextSetLineWidth().
        context.stroke(CGRect(x: 30.0, y: 210.0, width: 60.0, height: 60.0), width: 10.0)

        // Demonstate the stroke is on both sides of the path.
        context.savingGState {

            context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            context.stroke(CGRect(x: 30.0, y: 210.0, width: 60.0, height: 60.0), width: 2.0)

        }

        
        // Bulk call to add multiple rects to the current path.
        let rects = [
            CGRect(x: 120.0, y: 30.0, width: 60.0, height: 60.0),
            CGRect(x: 120.0, y: 120.0, width: 60.0, height: 60.0),
            CGRect(x: 120.0, y: 210.0, width: 60.0, height: 60.0)
        ]
        // Equivalent to:
        //     for i in 1..<rects.count {
        //         context.addRect(rects[i])
        //     }
        context.addRects(rects)
        context.strokePath()


        // Create filled rectangles via two different paths.
        // Add/Fill path
        context.addRect(CGRect(x: 210.0, y: 30.0, width: 60.0, height: 60.0))
        context.fillPath()

        // Fill convienience.
        context.fill(CGRect(x: 210.0, y: 120.0, width: 60.0, height: 60.0))
        
    }
    
}




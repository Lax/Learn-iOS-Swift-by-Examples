/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates Quartz line drawing facilities including stroke width, line cap and line join.
 */





import UIKit



class QuartzDashView: QuartzView {



    var dashPhase: CGFloat = 0.0 {
        didSet(prevPhaseValue) {
            if prevPhaseValue != dashPhase {
                setNeedsDisplay()
            }
        }
    }



    var dashPattern: [CGFloat] = [] {
        didSet(prevdashPattern) {
           // redraw if the contents of the array has changed
            if prevdashPattern.count != dashPattern.count {
                setNeedsDisplay()
            } else {
                for (index, value) in dashPattern.enumerated() {
                    if prevdashPattern[index] != value {
                        setNeedsDisplay()
                        break
                    }
                }
            }
        }
    }



    override func drawInContext(_ context: CGContext) {

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:320.0, height:140.0))

        // Drawing lines with a white stroke color
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        // Each dash entry is a run-length in the current coordinate system
        // The concept is first you determine how many points in the current system you need to fill.
        // Then you start consuming that many pixels in the dash pattern for each element of the pattern.
        // So for example, if you have a dash pattern of {10, 10}, then you will draw 10 points, then skip 10 points, and repeat.
        // As another example if your dash pattern is {10, 20, 30}, then you draw 10 points, skip 20 points, draw 30 points,
        // skip 10 points, draw 20 points, skip 30 points, and repeat.
        // The dash phase factors into this by stating how many points into the dash pattern to skip.
        // So given a dash pattern of {10, 10} with a phase of 5, you would draw 5 points (since phase plus 5 yields 10 points),
        // then skip 10, draw 10, skip 10, draw 10, etc.

        context.setLineDash(phase: dashPhase, lengths: dashPattern)

        // Draw a horizontal line, vertical line, rectangle and circle for comparison
        context.move(to: CGPoint(x: 10.0, y: 30.0))
        context.addLine(to: CGPoint(x: 310.0, y: 20.0))
        context.move(to: CGPoint(x: 160.0, y: 30.0))
        context.addLine(to: CGPoint(x: 160.0, y: 130.0))
        context.addRect(CGRect(x:10.0, y:30.0, width:100.0, height:100.0))
        context.addEllipse(in: CGRect(x:210.0, y:30.0, width:100.0, height:100.0))

        // And width 2.0 so they are a bit more visible
        context.setLineWidth(2.0)
        context.strokePath()
    }
    
}





/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates Quartz line drawing facilities
 */





import UIKit



class QuartzLineView: QuartzView {


    override func drawInContext(_ context: CGContext) {

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:320.0, height:160.0))

        // Drawing lines with a white stroke color
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        // Draw them with a 2.0 stroke width so they are a bit more visible.
        context.setLineWidth(2.0)


        // Draw a single line from left to right
        context.move(to: CGPoint(x: 10.0, y: 30.0))
        context.addLine(to: CGPoint(x: 310.0, y: 30.0))
        context.strokePath()


        // Draw a connected sequence of line segments
        let addLines = [
            CGPoint(x: 10.0, y: 90.0),
            CGPoint(x: 70.0, y: 60.0),
            CGPoint(x: 130.0, y: 90.0),
            CGPoint(x: 190.0, y: 60.0),
            CGPoint(x: 250.0, y: 90.0),
            CGPoint(x: 310.0, y: 60.0)
        ]
        // Bulk call to add lines to the current path.
        // Equivalent to:
        //     context.move(to: addLines[0])
        //     for i in 1..<addLines.count {
        //         context.addLine(to: addLines[i+1])
        //     }
        context.addLines(between: addLines)
        context.strokePath()


        // Draw a series of line segments. Each pair of points is a segment
        let strokeSegments = [
            CGPoint(x: 10.0, y: 150.0),
            CGPoint(x: 70.0, y: 120.0),
            CGPoint(x: 130.0, y: 150.0),
            CGPoint(x: 190.0, y: 120.0),
            CGPoint(x: 250.0, y: 150.0),
            CGPoint(x: 310.0, y: 120.0)
        ]
        // Bulk call to stroke a sequence of line segments.
        // Equivalent to:
        //     context.addLines(between: strokeSegments)
        //     context.strokePath()
        context.strokeLineSegments(between: strokeSegments)

    }


}

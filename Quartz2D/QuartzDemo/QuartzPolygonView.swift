/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz to stroke  fill polygons (QuartzPolygonView).
 */





import UIKit



class QuartzPolygonView: QuartzView {



    var drawingMode: CGPathDrawingMode = .fill {
        didSet(prevDrawingMode) {
            if prevDrawingMode != drawingMode {
                setNeedsDisplay()
            }
        }
    }



    override func drawInContext(_ context: CGContext) {

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:280.0, height:280.0))

        // Drawing lines with a white stroke color
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        // And drawing with a blue fill color
        context.setFillColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        // Draw them with a 2.0 stroke width so they are a bit more visible.
        context.setLineWidth(2.0)

                    // Add a star to the current path
        var center = CGPoint(x: 90, y: 90)
        context.move(to: CGPoint(x: center.x, y: center.y + 60.0))
        for i in 1..<5 {
            let x = CGFloat(60.0 * sinf(Float(i) * 4.0 * Float.pi / 5.0))
            let y = CGFloat(60.0 * cosf(Float(i) * 4.0 * Float.pi / 5.0))
            context.addLine(to: CGPoint(x: center.x + x, y: center.y + y))
        }
        // And close the subpath.
        context.closePath()


        // Now add the hexagon to the current path
        center = CGPoint(x: 210, y: 90)
        context.move(to: CGPoint(x: center.x, y: center.y + 60.0))
        for i in 1..<6 {
            let x = CGFloat(60.0 * sinf(Float(i) * 2.0 * Float.pi / 6.0))
            let y = CGFloat(60.0 * cosf(Float(i) * 2.0 * Float.pi / 6.0))
            context.addLine(to: CGPoint(x: center.x + x, y: center.y + y))
        }
        // And close the subpath.
        context.closePath()

        // Now draw the star & hexagon with the current drawing mode.
        context.drawPath(using: drawingMode)

    }
    
}






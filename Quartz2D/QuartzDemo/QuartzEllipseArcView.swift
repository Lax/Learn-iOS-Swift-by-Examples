/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz to draw ellipses  arcs.
 */





import UIKit



class QuartzEllipseArcView: QuartzView {


    override func drawInContext(_ context: CGContext) {

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:280.0, height:280.0))

        // Drawing lines with a white stroke color
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        // And drawing with a blue fill color
        context.setFillColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        // Draw them with a 2.0 stroke width so they are a bit more visible.
        context.setLineWidth(2.0)

        // Add an ellipse circumscribed in the given rect to the current path, then stroke it
        context.addEllipse(in: CGRect(x: 30.0, y: 30.0, width: 60.0, height: 60.0))
        context.strokePath()

        // Stroke ellipse convenience that is equivalent to context.addEllipse(in:), context.strokePath()
        context.strokeEllipse(in: CGRect(x: 30.0, y: 120.0, width: 60.0, height: 60.0))

        // Fill rect convenience equivalent to context.addEllipse(in:), context.strokePath()
        context.fillEllipse(in: CGRect(x: 30.0, y: 210.0, width: 60.0, height: 60.0))

        // Stroke 2 seperate arcs
        context.addArc(center: CGPoint(x: 150.0, y: 60.0), radius: 30.0, startAngle: 0.0, endAngle: CGFloat.pi/2.0, clockwise: false)
        context.strokePath()
        context.addArc(center: CGPoint(x: 150.0, y: 60.0), radius: 30.0, startAngle: 3.0*CGFloat.pi/2.0, endAngle: CGFloat.pi, clockwise: true)
        context.strokePath()

        // Stroke 2 arcs together going opposite directions.
        context.addArc(center: CGPoint(x: 150.0, y: 150.0), radius: 30.0, startAngle: 0.0, endAngle: CGFloat.pi/2.0, clockwise: false)
        context.addArc(center: CGPoint(x: 150.0, y: 150.0), radius: 30.0, startAngle: 3.0*CGFloat.pi/2.0, endAngle: CGFloat.pi, clockwise: true)
        context.strokePath()

        // Stroke 2 arcs together going the same direction..
        context.addArc(center: CGPoint(x: 150.0, y: 240.0), radius: 30.0, startAngle: 0.0, endAngle: CGFloat.pi/2.0, clockwise: false)
        context.addArc(center: CGPoint(x: 150.0, y: 240.0), radius: 30.0, startAngle: 3.0*CGFloat.pi/2.0, endAngle: CGFloat.pi, clockwise: false)
        context.strokePath()

        // Stroke an arc using tangent points
        let p = [
            CGPoint(x: 210.0, y: 30.0),
            CGPoint(x: 210.0, y: 60.0),
            CGPoint(x: 240.0, y: 60.0)
        ]
        context.move(to: p[0])
        context.addArc(tangent1End: p[1], tangent2End: p[2], radius: 30.0)
        context.strokePath()


        // Show the two segments that are used to determine the tangent lines to draw the arc.
        context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.addLines(between: p)
        context.strokePath()


        // As a bonus, we'll combine arcs to create a round rectangle!

        // Drawing with a white stroke color
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)


        // If you were making this as a routine, you would probably accept a rectangle
        // that defines its bounds, and a radius reflecting the "rounded-ness" of the rectangle.
        let rrect = CGRect(x: 210.0, y: 90.0, width: 60.0, height: 60.0)
        let rrradius: CGFloat = 10.0
        // NOTE: At this point you may want to verify that your radius is no more than half
        // the width and height of your rectangle, as this technique degenerates for those cases.

        // In order to draw a rounded rectangle, we will take advantage of the fact that
        // CGContextAddArcToPoint will draw straight lines past the start and end of the arc
        // in order to create the path from the current position and the destination position.

        // In order to create the 4 arcs correctly, we need to know the min, mid and max positions
        // on the x and y lengths of the given rectangle.
        let minx = rrect.minX, midx = rrect.midX, maxx = rrect.maxX
        let miny = rrect.minY, midy = rrect.midY, maxy = rrect.maxY

        // Next, we will go around the rectangle in the order given by the figure below.
        //       minx    midx    maxx
        // miny    2       3       4
        // midy   1 9              5
        // maxy    8       7       6
        // Which gives us a coincident start and end point, which is incidental to this technique, but still doesn't
        // form a closed path, so we still need to close the path to connect the ends correctly.
        // Thus we start by moving to point 1, then adding arcs through each pair of points that follows.
        // You could use a similar tecgnique to create any shape with rounded corners.

        // Start at 1
        context.move(to: CGPoint(x: minx, y: midy))
        // Add an arc through 2 to 3
        context.addArc(tangent1End: CGPoint(x: minx, y: miny), tangent2End: CGPoint(x: midx, y: miny), radius: rrradius)
        // Add an arc through 4 to 5
        context.addArc(tangent1End: CGPoint(x: maxx, y: miny), tangent2End: CGPoint(x: maxx, y: midy), radius: rrradius)
        // Add an arc through 6 to 7
        context.addArc(tangent1End: CGPoint(x: maxx, y: maxy), tangent2End: CGPoint(x: midx, y: maxy), radius: rrradius)
        // Add an arc through 8 to 9
        context.addArc(tangent1End: CGPoint(x: minx, y: maxy), tangent2End: CGPoint(x: minx, y: midy), radius: rrradius)
        // Close the path
        context.closePath()
        // Fill & stroke the path
        context.drawPath(using: .fillStroke)

    }

}









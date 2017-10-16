/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz to draw bezier  quadratic curves.
 */





import UIKit



class QuartzBezierView: QuartzView {


    override func drawInContext(_ context: CGContext) {

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:320.0, height:300.0))

        // Drawing lines with a white stroke color
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        // Draw them with a 2.0 stroke width so they are a bit more visible.
        context.setLineWidth(2.0)


        // Draw a bezier curve with end points s,e and control points cp1,cp2
        var s = CGPoint(x: 30.0, y: 120.0)
        var e = CGPoint(x: 300.0, y: 120.0)
        var cp1 = CGPoint(x: 120.0, y: 30.0)
        let cp2 = CGPoint(x: 210.0, y: 210.0)
        context.move(to: s)
        context.addCurve(to: cp1, control1: cp2, control2: e)
        context.strokePath()


        // Show the control points.
        context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.move(to: s)
        context.addLine(to: cp1)
        context.move(to: e)
        context.addLine(to: cp2)
        context.strokePath()


        // Draw a quad curve with end points s,e and control point cp1
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        s = CGPoint(x: 30.0, y: 300.0)
        e = CGPoint(x: 270.0, y: 300.0)
        cp1 = CGPoint(x: 150.0, y: 180.0)
        context.move(to: s)
        context.addQuadCurve(to: cp1, control: e)
        context.strokePath()


        // Show the control point.
        context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.move(to: s)
        context.addLine(to: cp1)
        context.strokePath()

    }

}








/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz for drawing gradients.
 */





import UIKit



class QuartzGradientView: QuartzView {


    enum GradientType: Int {
        case kLinearGradient = 0
        case kRadialGradient = 1
    }


    var gradient: CGGradient = {
        var rgb = CGColorSpaceCreateDeviceRGB()
        var colors: [CGFloat] = [
            204.0 / 255.0, 224.0 / 255.0, 244.0 / 255.0, 1.00,
            29.0 / 255.0, 156.0 / 255.0, 215.0 / 255.0, 1.00,
            0.0 / 255.0,  50.0 / 255.0, 126.0 / 255.0, 1.00
        ]
        return CGGradient(colorSpace: rgb, colorComponents: colors, locations: nil, count: colors.count)!
    }()



    var gradientTypeToDisplay: GradientType = .kLinearGradient {
        didSet(prevGradientTypeToDisplayValue) {
            if prevGradientTypeToDisplayValue != gradientTypeToDisplay {
                setNeedsDisplay()
            }
        }
    }



    var extendsPastStart: Bool = false {
        didSet(prevExtendsPastStartValue) {
            if prevExtendsPastStartValue != extendsPastStart {
                setNeedsDisplay()
            }
        }
    }



    var extendsPastEnd: Bool = false {
        didSet(prevExtendsPastEnd) {
            if prevExtendsPastEnd != extendsPastEnd {
                setNeedsDisplay()
            }
        }
    }



    // Returns an appropriate starting point for the demonstration of a linear gradient
    func demoLGStart(_ bounds: CGRect) -> CGPoint {
        return CGPoint(x: bounds.origin.x, y: bounds.origin.y + bounds.size.height * 0.25)
    }



    // Returns an appropriate ending point for the demonstration of a linear gradient
    func demoLGEnd(_ bounds: CGRect) -> CGPoint {
        return CGPoint(x: bounds.origin.x, y: bounds.origin.y + bounds.size.height * 0.75)
    }



    // Returns the center point for for the demonstration of the radial gradient
    func demoRGCenter(_ bounds: CGRect) -> CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }



    // Returns an appropriate inner radius for the demonstration of the radial gradient
    func demoRGInnerRadius(_ bounds: CGRect) -> CGFloat {
        return min(bounds.size.width, bounds.size.height) * 0.125
    }



    // Returns an appropriate outer radius for the demonstration of the radial gradient
    func demoRGOuterRadius(_ bounds: CGRect) -> CGFloat {
        return max(bounds.size.width, bounds.size.height) * 0.5
    }



    func drawingOptions() -> CGGradientDrawingOptions {
        var options: CGGradientDrawingOptions = []
        if extendsPastStart {
            options.insert(.drawsBeforeStartLocation)
        }
        if extendsPastEnd {
            options.insert(.drawsAfterEndLocation)
        }
        return options
    }
    



    override func drawInContext(_ context: CGContext) {

        // Use the clip bounding box, sans a generous border
        let clip = context.boundingBoxOfClipPath.insetBy(dx: 20.0, dy: 20.0)

        // Clip to area to draw the gradient, and draw it. Since we are clipping, we save the graphics state
        // so that we can revert to the previous larger area.
        context.savingGState {

            context.clip(to: clip)

            let options: CGGradientDrawingOptions = drawingOptions()

            switch gradientTypeToDisplay {

                case .kLinearGradient:
                    // A linear gradient requires only a starting & ending point.
                    // The colors of the gradient are linearly interpolated along the line segment connecting these two points
                    // A gradient location of 0.0 means that color is expressed fully at the 'start' point
                    // a location of 1.0 means that color is expressed fully at the 'end' point.
                    // The gradient fills outwards perpendicular to the line segment connectiong start & end points
                    // (which is why we need to clip the context, or the gradient would fill beyond where we want it to).
                    // The gradient options (last) parameter determines what how to fill the clip area that is "before" and "after"
                    // the line segment connecting start & end.
                    context.drawLinearGradient(gradient, start: demoLGStart(clip), end: demoLGEnd(clip), options: options)

                case .kRadialGradient:
                    // A radial gradient requires a start & end point as well as a start & end radius.
                    // Logically a radial gradient is created by linearly interpolating the center, radius and color of each
                    // circle using the start and end point for the center, start and end radius for the radius, and the color ramp
                    // inherant to the gradient to create a set of stroked circles that fill the area completely.
                    // The gradient options specify if this interpolation continues past the start or end points as it does with
                    // linear gradients.
                    context.drawRadialGradient(gradient,
                                               startCenter: demoRGCenter(clip),
                                               startRadius: demoRGInnerRadius(clip),
                                               endCenter: demoRGCenter(clip),
                                               endRadius: demoRGOuterRadius(clip),
                                               options: options)
            }

        }

        // Show the clip rect
        context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.stroke(clip, width: 2.0)
    }
    
    
}

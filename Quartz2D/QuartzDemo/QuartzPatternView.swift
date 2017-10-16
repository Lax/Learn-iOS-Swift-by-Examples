/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz for drawing patterns.
 */





import UIKit



class QuartzPatternView: QuartzView {



    var coloredPatternColor: CGColor = {

        // Colored Pattern setup.  CGPatterns have callbacks to do the drawing.
        var coloredPatternCallbacks =
            CGPatternCallbacks(version: 0,
                               drawPattern: { (info: UnsafeMutableRawPointer?, context: CGContext) -> Swift.Void in
                                // Dark Blue
                                context.setFillColor(red: 29.0 / 255.0, green: 156.0 / 255.0, blue: 215.0 / 255.0, alpha: 1.00)
                                context.fill(CGRect(x: 0.0, y: 0.0, width: 8.0, height: 8.0))
                                context.fill(CGRect(x: 8.0, y: 8.0, width: 8.0, height: 8.0))
                                // Light Blue
                                context.setFillColor(red: 204.0 / 255.0, green: 224.0 / 255.0, blue: 244.0 / 255.0, alpha: 1.00)
                                context.fill(CGRect(x: 8.0, y: 0.0, width: 8.0, height: 8.0))
                                context.fill(CGRect(x: 0.0, y: 8.0, width: 8.0, height: 8.0)) },
                               releaseInfo: nil)

        // First we need to create a CGPatternRef that specifies the qualities of our pattern.
        let coloredPattern = CGPattern(info: nil,
                                       bounds: CGRect(x: 0.0, y: 0.0, width: 16.0, height: 16.0),
                                       matrix: CGAffineTransform.identity,
                                       xStep: 16.0,
                                       yStep: 16.0,
                                       tiling: .noDistortion,
                                       isColored: true,
                                       callbacks: &coloredPatternCallbacks)!
        // To draw a pattern, you need a pattern colorspace.
        // Since this is an colored pattern, the parent colorspace is NULL, indicating that it only has an alpha value.
        var coloredPatternColorSpace = CGColorSpace(patternBaseSpace: nil)!
        var alpha: CGFloat = 1.0

        // Since this pattern is colored, we'll create a CGColorRef for it to make drawing it easier and more efficient.
        // From here on, the colored pattern is referenced entirely via the associated CGColorRef rather than the
        // originally created CGPatternRef.
        return CGColor(patternSpace: coloredPatternColorSpace, pattern: coloredPattern, components: &alpha)!
    }()



    var uncoloredPattern: CGPattern = {
        var uncoloredPatternCallbacks =
            CGPatternCallbacks(version: 0,
                               drawPattern: {(info: UnsafeMutableRawPointer?, context: CGContext) -> Swift.Void in
                                // Dark Blue
                                context.fill(CGRect(x: 0.0, y: 0.0, width: 8.0, height: 8.0))
                                context.fill(CGRect(x: 8.0, y: 8.0, width: 8.0, height: 8.0)) },
                               releaseInfo: nil)

        // As above, we create a CGPatternRef that specifies the qualities of our pattern
        return CGPattern(info: nil,
                         bounds: CGRect(x: 0.0, y: 0.0, width: 16.0, height: 16.0),
                         matrix: CGAffineTransform.identity,
                         xStep: 16.0, yStep: 16.0,
                         tiling: .noDistortion,
                         isColored: false,
                         callbacks: &uncoloredPatternCallbacks)!
    }()



    var uncoloredPatternColorSpace: CGColorSpace = {
        var deviceRGB: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        return CGColorSpace(patternBaseSpace: deviceRGB)!
    }()



    override func drawInContext(_ context: CGContext) {

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:220.0, height:330.0))

        // Draw the colored pattern. Since we have a CGColorRef for this pattern, we just set
        // that color current and draw.
        context.setFillColor(coloredPatternColor)
        context.fill(CGRect(x: 10.0, y: 10.0, width: 90.0, height: 90.0))

        // You can also stroke with a pattern.
        context.setStrokeColor(coloredPatternColor)
        context.stroke(CGRect(x: 120.0, y: 10.0, width: 90.0, height: 90.0), width: 8)

        // Since we aren't encapsulating our pattern in a CGColorRef for the uncolored pattern case, setup requires two steps.
        // First you have to set the context's current colorspace (fill or stroke) to a pattern colorspace,
        // indicating to Quartz that you want to draw a pattern.
        context.setFillColorSpace(uncoloredPatternColorSpace)
        // Next you set the pattern and the color that you want the pattern to draw with.
        let color1: [CGFloat] = [1.0, 0.0, 0.0, 1.0]
        context.setFillPattern(uncoloredPattern, colorComponents: color1)
        // And finally you draw!
        context.fill(CGRect(x: 10.0, y: 120.0, width: 90.0, height: 90.0))

        // As long as the current colorspace is a pattern colorspace, you are free to change the pattern or pattern color
        let color2: [CGFloat] = [0.0, 1.0, 0.0, 1.0]
        context.setFillPattern(uncoloredPattern, colorComponents: color2)
        context.fill(CGRect(x: 10.0, y: 230.0, width: 90.0, height: 90.0))

        // And of course, just like the colored case, you can stroke with a pattern as well.
        context.setStrokeColorSpace(uncoloredPatternColorSpace)
        context.setStrokePattern(uncoloredPattern, colorComponents: color1)
        context.stroke(CGRect(x: 120.0, y: 120.0, width: 90.0, height: 90.0), width: 8)
        
    }

}







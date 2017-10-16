/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using CoreText for drawing text in a CGContext
 */





import UIKit
import CoreText

class QuartzTextView: QuartzView {


    override func drawInContext(_ context: CGContext) {

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:320.0, height:320.0))

        // Drawing lines with a white stroke color
        context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        // And drawing with a red fill color
        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        // Stroke the letters with one point line
        context.setLineWidth(1.0)

        // Some initial setup for our text drawing needs.
        // First, we will be doing our drawing in Helvetica-36pt with the MacRoman encoding.
        // This is an 8-bit encoding that can reference standard ASCII characters
        // and many common characters used in the Americas and Western Europe.
        let demoFont = UIFont(name: "Helvetica", size: 36.0)

        // Next we set the text matrix to flip our text upside down. We do this because the context itself
        // is flipped upside down relative to the expected orientation for drawing text (much like the case for drawing Images & PDF).
        context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)

        // set up an attributed string using CoreText attributes.  Here, we set
        // up the string to use the demo font, and to take the forground color from the context.
        let lineText = NSMutableAttributedString(string:"Hello from CoreText")
        lineText.addAttribute(kCTFontAttributeName as String, value: demoFont!, range: NSMakeRange(0, lineText.length))
        lineText.addAttribute(kCTForegroundColorFromContextAttributeName as String, value: true, range: NSMakeRange(0, lineText.length))

        // format the text as a CoreText line
        let lineToDraw: CTLine = CTLineCreateWithAttributedString(lineText)

        // fill the text
        context.setTextDrawingMode(.fill)
        context.textPosition = CGPoint(x: 10.0, y: 30.0)
        CTLineDraw(lineToDraw, context)

        // stroke the outline of the text
        context.setTextDrawingMode(.stroke)
        context.textPosition = CGPoint(x: 10.0, y: 70.0)
        CTLineDraw(lineToDraw, context)

        // fill and stroke the text
        context.setTextDrawingMode(.fillStroke)
        context.textPosition = CGPoint(x: 10.0, y: 110.0)
        CTLineDraw(lineToDraw, context)


        // Now lets try the more complex Glyph functions. These functions allow you to draw any glyph available in a font,
        // but provide no assistance with converting characters to glyphs or layout, and as such require considerably more knowledge
        // of text to use correctly. Specifically, you need to understand Unicode encoding and how to interpret the information
        // present in the font itself, such as the cmap table.
        // To get you started, we are going to do the minimum necessary to draw a glyphs into the current context.
        let helvetica = CTFontCreateWithName("Helvetica" as CFString, 12.0, nil)
        context.setTextDrawingMode(.fill)
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        var start: CGGlyph = 0
        let font_height = CTFontGetAscent(helvetica) + CTFontGetDescent(helvetica) + CTFontGetLeading(helvetica)
        context.textPosition = CGPoint(x: 10.0, y: 30.0+(19.0*font_height))
        let lettersPerLine = 32
        let numberOfLines = 20
        for y: Int in 0..<numberOfLines {

            var glyphs: [CGGlyph] = Array(repeating: CGGlyph(0), count: lettersPerLine)
            var points: [CGPoint] = Array(repeating: CGPoint(x: 0.0, y: 0.0), count: lettersPerLine)
            var advances: [CGSize] = Array(repeating: CGSize(width:0, height:0), count: lettersPerLine)
            for i: Int in 0..<lettersPerLine {
                glyphs[i] = start + CGGlyph(i)
            }
            CTFontGetAdvancesForGlyphs(helvetica, .default, &glyphs, &advances, lettersPerLine)
            var x_offset: CGFloat = 10.0
            for i: Int in 0..<lettersPerLine {
                points[i] = CGPoint(x: x_offset, y: 110.0 - CGFloat(y) * font_height)
                x_offset += advances[i].width
            }
            start += CGGlyph(lettersPerLine)
            CTFontDrawGlyphs(helvetica, &glyphs, &points, lettersPerLine, context)
        }
    }

}








/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz for drawing PDF files
 */





import UIKit



class QuartzPDFView: QuartzView {


    let pdfDocument: CGPDFDocument = {
        return CGPDFDocument(Bundle.main.url(forResource: "Quartz", withExtension: "pdf")! as CFURL)!
    }()


    override func drawInContext(_ context: CGContext) {

        // PDF page drawing expects a Lower-Left coordinate system, so we flip the coordinate system
        // before we start drawing.
        context.translateBy(x: 0.0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // Grab the first PDF page
        let page = pdfDocument.page(at: 1)!

        // We're about to modify the context CTM to draw the PDF page where we want it, so save the graphics state in case we want to do more drawing
        context.saveGState()

        // page.getDrawingTransform provides an easy way to get the transform for a PDF page. It will scale down to fit, including any
        // base rotations necessary to display the PDF page correctly.
        let pdfTransform = page.getDrawingTransform(.cropBox, rect: bounds, rotate: 0, preserveAspectRatio: true)
        
        // And apply the transform.
        context.concatenate(pdfTransform)

        // Finally, we draw the page
        context.drawPDFPage(page)

        // restore the graphics state for further manipulations!
        context.restoreGState()
    }
    
    
}

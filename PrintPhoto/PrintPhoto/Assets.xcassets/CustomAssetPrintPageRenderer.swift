/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `UIPrintPageRenderer` subclass for drawing an image for print.
*/

import UIKit

/// A `UIPrintPageRenderer` subclass to print an image.
class CustomAssetPrintPageRenderer: UIPrintPageRenderer {
    // MARK: Properties
    
    var image: UIImage
    
    // MARK: Initilization
    
    init(image: UIImage) {
        self.image = image
    }
    
    // MARK: UIPrintPageRenderer Overrides
    
    override func numberOfPages() -> Int {
        return 1
    }
    
    override func drawPageAtIndex(pageIndex: Int, inRect printableRect: CGRect) {
        /*
            When `drawPageAtIndex(_:inRect:)` is invoked, `paperRect` reflects the
            size of the paper we are printing on and `printableRect` reflects the
            rectangle describing the imageable area of the page, that is the portion
            of the page that the printer can mark without clipping.
        */
        let paperSize = paperRect.size
        let imageableAreaSize = printableRect.size
        
        /*
            If `paperRect` and `printableRect` are the same size, the sheet is
            borderless and we will use the fill algorithm. Otherwise we will uniformly
            scale the image to fit the imageable area as close as is possible without
            clipping.
        */
        let fillsSheet = paperSize == imageableAreaSize
        
        let imageSize = image.size
        
        let destinationRect: CGRect
        if fillsSheet {
            destinationRect = CGRect(origin: .zero, size: paperSize)
        }
        else {
            destinationRect = printableRect
        }
        
        /*
            Calculate the ratios of the destination rectangle width and height to
            the image width and height.
        */
        let widthScale = destinationRect.width / imageSize.width
        let heightScale = destinationRect.height / imageSize.height
        
        // Scale the image to have some padding within the page.
        let scale: CGFloat

        if fillsSheet {
            // Produce a fill to the entire sheet and clips content.
            scale = (widthScale > heightScale ? widthScale : heightScale)
        }
        else {
            // Show all the content at the expense of additional white space.
            scale = (widthScale < heightScale ? widthScale : heightScale)
        }
        
        /*
            Compute the coordinates for `centeredDestinationRect` so that the scaled
            image is centered on the sheet.
        */
        let printOriginX = (paperSize.width - imageSize.width * scale) / 2
        let printOriginY = (paperSize.height - imageSize.height * scale) / 2
        let printWidth = imageSize.width * scale
        let printHeight = imageSize.height * scale

        let printRect = CGRect(x: printOriginX, y: printOriginY, width: printWidth, height: printHeight)
        
        // Inset the printed image by 10% of the size of the image.
        let inset = max(printRect.width, printRect.height) * 0.1
        let insettedPrintRect = printRect.insetBy(dx: inset, dy: inset)
        
        // Create the vignette clipping.
        let context = UIGraphicsGetCurrentContext()!
        CGContextAddEllipseInRect(context, insettedPrintRect)
        CGContextClip(context)

        image.drawInRect(insettedPrintRect)
    }
}

/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz for drawing images.
 */





import UIKit



class QuartzImageView: QuartzView {


    static let image: CGImage = {
        let u = Bundle.main.url(forResource: "Demo", withExtension: "png")!
        let i = UIImage(contentsOfFile: u.path)!
        return i.cgImage!
    }()

    

    override func drawInContext(_ context: CGContext) {

        // spare out the width and height of the view for less typing below
        let w = bounds.size.width
        let h = bounds.size.height
        let img = QuartzImageView.image


        // Note: The images are actually drawn upside down because Quartz image drawing expects
        // the coordinate system to have the origin in the lower-left corner, but a UIView
        // puts the origin in the upper-left corner. For the sake of brevity (and because
        // it likely would go unnoticed for the image used) this is not addressed here.
        // For the demonstration of PDF drawing however, it is addressed, as it would definitely
        // be noticed, and one method of addressing it is shown there.

        // draw the image centered in the top part of the view
        var imageRect = CGRect(x: (w-CGFloat(img.width))/2.0, y: ((80.0+h*0.20)-CGFloat(img.height))/2.0, width: CGFloat(img.width), height: CGFloat(img.height))
        context.draw(img, in: imageRect)


        // Tile the same image in the bottom part of the view

        // CGContextDrawTiledImage() will fill the entire clipping area with the image, so to avoid
        // filling the entire view, we'll clip the view to the rect below inset by 20%. This rect extends
        // past the region of the view, but since the view's rectangle has already been applied as a clip
        // to our drawing area, it will be intersected with this rect to form the final clipping area
        context.clip(to: CGRect(x: 0.0, y: 80.0, width: w, height: h).insetBy(dx: w*0.20, dy: h*0.20))


        // The origin of the image rect works similarly to the phase parameter for SetLineDash and
        // SetPatternPhase and specifies where in the coordinate system the "first" image is drawn.
        // The size (previously set to 64x64) specifies the size the image is scaled to before being tiled.
        imageRect.origin = CGPoint(x: 32.0, y: 112.0)
        context.draw(img, in: imageRect, byTiling: true)


        // Drawing lines with a white stroke color
        // Draw them with a 2.0 stroke width so they are a bit more visible.
        context.setLineWidth(2.0)


        // Highlight the "first" image from the DrawTiledImage call.
        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        context.fill(imageRect)
        // And stroke the clipped area
        context.setLineWidth(3.0)
        context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.stroke(context.boundingBoxOfClipPath)

    }

}

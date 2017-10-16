/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz for clipping.
 */





import UIKit



class QuartzClippingView: QuartzView {



    static let image: CGImage = {
        let u = Bundle.main.url(forResource: "Ship", withExtension: "png")!
        let i = UIImage(contentsOfFile: u.path)!
        return i.cgImage!
    }()


    
    func addStarToContext(_ context: CGContext, centeredAt center: CGPoint, withRadius radius: CGFloat, andAngle angle: CGFloat) {
        var x = radius * CGFloat(sinf(Float(angle) * Float.pi / 5.0)) + center.x
        var y = radius * CGFloat(cosf(Float(angle) * Float.pi / 5.0)) + center.y
        context.move(to: CGPoint(x: x, y: y))
        for i in 1...4 {
            x = radius * CGFloat(sinf((Float(i) * 4.0 * Float.pi + Float(angle)) / 5.0)) + center.x
            y = radius * CGFloat(cosf((Float(i) * 4.0 * Float.pi + Float(angle)) / 5.0)) + center.y
            context.addLine(to: CGPoint(x: x, y: y))
        }
        // And close the subpath.
        context.closePath()
    }



    override func drawInContext(_ context: CGContext) {

        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:320.0, height:160.0))

        // So that the images in this demo appear right-side-up, we flip the context
        // In doing so we need to specify all of our Y positions relative to the height of the view.
        // The value we subtract from the height is the Y coordinate for the *bottom* of the image.
        let height = self.bounds.size.height
        context.translateBy(x: 0.0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

        // We'll draw the original image for comparision
        context.draw(QuartzClippingView.image, in: CGRect(x: 10.0, y: height - 100.0, width: 90.0, height: 90.0))


        // First we'll use clipping rectangles to remove the body of the ship.
        // We use CGContext.clip(to: [CGRect]) to clip to a set of rectangles.
        context.savingGState {

            // For this operation we extract the 35 pixel strip on each side of the source image.
            let clips = [
                CGRect(x: 110.0, y: height - 100.0, width: 35.0, height: 90.0),
                CGRect(x: 165.0, y: height - 100.0, width: 35.0, height: 90.0)
            ]
            // While convinient, this is just the equivalent of adding each rectangle to the current path,
            // then calling CGContextClip().
            context.clip(to: clips)
            context.draw(QuartzClippingView.image, in: CGRect(x: 110.0, y: height - 100.0, width: 90.0, height: 90.0))
        }



        // You can also clip to aribitrary shapes, which can be useful for special effects.
        // In this case we are going to clip to a star.
        // We will actually clip the image twice, using the different clipping modes.
        addStarToContext(context, centeredAt: CGPoint(x: 55.0, y: height - 150.0), withRadius: 45.0, andAngle: 0.0)
        context.savingGState {

            // Clip to the current path using the non-zero winding number rule.
            context.clip()

            // To make the area we draw to a bit more obvious, we'll the image over a red rectangle.
            context.fill(CGRect(x: 10.0, y: height - 190.0, width: 90.0, height: 90.0))

            // And finally draw the image
            context.draw(QuartzClippingView.image, in: CGRect(x: 10.0, y: height - 190.0, width: 90.0, height: 90.0))
        }



        addStarToContext(context, centeredAt: CGPoint(x: 155.0, y: height - 150.0), withRadius: 45.0, andAngle: 0.0)
        context.savingGState {

            // Clip to the current path using the even-odd rule.
            context.clip(using: .evenOdd)

            // To make the area we draw to a bit more obvious, we'll the image over a red rectangle.
            context.fill(CGRect(x: 110.0, y: height - 190.0, width: 90.0, height: 90.0))

            // And finally draw the image
            context.draw(QuartzClippingView.image, in: CGRect(x: 110.0, y: height - 190.0, width: 90.0, height: 90.0))

        }



        // Finally making the path slightly more complex by enscribing it in a rectangle changes what is clipped
        // For EO clipping mode this will invert the clip (for non-zero winding this is less predictable).
        addStarToContext(context, centeredAt: CGPoint(x: 255.0, y: height - 150.0), withRadius: 45.0, andAngle: 0.0)
        context.addRect(CGRect(x: 210.0, y: height - 190.0, width: 90.0, height: 90.0))
        context.savingGState {

            // Clip to the current path using the even-odd rule.
            context.clip(using: .evenOdd)

            // To make the area we draw to a bit more obvious, we'll the image over a red rectangle.
            context.fill(CGRect(x: 210.0, y: height - 190.0, width: 90.0, height: 90.0))

            // And finally draw the image
            context.draw(QuartzClippingView.image, in: CGRect(x: 210.0, y: height - 190.0, width: 90.0, height: 90.0))

        }
    }


}







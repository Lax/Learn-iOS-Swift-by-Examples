/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates using Quartz for masking.
 */





import UIKit


class QuartzMaskingView: QuartzView {


    static let alphaImage: CGImage = {
        let u = Bundle.main.url(forResource: "Ship", withExtension: "png")!
        let i = UIImage(contentsOfFile: u.path)!
        return i.cgImage!
    }()


    static let maskingImage: CGImage = {

        let imageWidth: Int = QuartzMaskingView.alphaImage.width
        let imageHeight: Int = QuartzMaskingView.alphaImage.height
        let bitsPerPixel: Int = 8
        let bytesPerPixel: Int = bitsPerPixel / 8
        let bytesPerRow: Int = imageWidth * bytesPerPixel
        let rasterBufferSize: Int = imageWidth * imageHeight * bytesPerPixel

        // To show the difference with an image mask, we take the alphaImage image and process it to extract
        // the alpha channel as a mask.

        // Allocate data
        let rasterBuffer: CFMutableData = CFDataCreateMutable(nil, rasterBufferSize)!
        CFDataSetLength(rasterBuffer, rasterBufferSize)

        // Create a bitmap context
        let context = CGContext(data: CFDataGetMutableBytePtr(rasterBuffer),
                                width: imageWidth,
                                height: imageHeight,
                                bitsPerComponent: bitsPerPixel,
                                bytesPerRow: bytesPerRow,
                                space: CGColorSpaceCreateDeviceGray(),
                                bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)!

        // Set the blend mode to copy to avoid any alteration of the source data
        context.setBlendMode(.copy)

        // Draw the image to extract the alpha channel
        context.draw(QuartzMaskingView.alphaImage, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(imageWidth), height: CGFloat(imageHeight)))

        // Now the alpha channel has been copied into our NSData object above, so lets make an image mask.

        // Create a data provider for our data object (NSMutableData is tollfree bridged to CFMutableDataRef, which is compatible with CFDataRef)
        let dataProvider: CGDataProvider = CGDataProvider(data: rasterBuffer)!

        // Create our new mask image with the same size as the original image
        return CGImage(maskWidth: imageWidth,
                       height: imageHeight,
                       bitsPerComponent: bitsPerPixel,
                       bitsPerPixel: bitsPerPixel,
                       bytesPerRow: bytesPerRow,
                       provider: dataProvider,
                       decode: nil,
                       shouldInterpolate: true)!
    }()





    override func drawInContext(_ context: CGContext) {

        let height = bounds.height

        let rr = CGRect(x: 110.0, y: height - 390.0, width: 180.0, height: 180.0)


        //centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:320.0, height:220.0))
        centerDrawing(inContext: context,  drawingExtent: CGRect(x:0.0, y:0.0, width:rr.maxX, height:rr.maxY))


        // NOTE
        // So that the images in this demo appear right-side-up, we flip the context
        // In doing so we need to specify all of our Y positions relative to the height of the view.
        // The value we subtract from the height is the Y coordinate for the *bottom* of the image.
        context.translateBy(x: 0.0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)



        // Quartz also allows you to mask to an image or image mask, the primary difference being
        // how the image data is interpreted. Note that you can use any image
        // When you use a regular image, the alpha channel is interpreted as the alpha values to use,
        // that is a 0.0 alpha indicates no pass and a 1.0 alpha indicates full pass.
        context.savingGState {

            context.clip(to: CGRect(x: 10.0, y: height - 100.0, width: 90.0, height: 90.0), mask: QuartzMaskingView.alphaImage)
            // Because we're clipping, we aren't going to be particularly careful with our rect.
            context.fill(bounds)

        }



        context.savingGState {

            // You can also use the clip rect given to scale the mask image
            context.clip(to: CGRect(x: 110.0, y: height - 190.0, width: 180.0, height: 180.0), mask: QuartzMaskingView.alphaImage)
            // As above, not being careful with bounds since we are clipping.
            context.fill(bounds)

        }



        // Alternatively when you use a mask image the mask data is used much like an inverse alpha channel,
        // that is 0.0 indicates full pass and 1.0 indicates no pass.
        context.savingGState {

            context.clip(to: CGRect(x: 10.0, y: height - 300.0, width: 90.0, height: 90.0), mask: QuartzMaskingView.maskingImage)
            // As above, not being careful with bounds since we are clipping.
            context.fill(bounds)

        }

        

        context.savingGState {

            // You can also use the clip rect given to scale the mask image
            context.clip(to: CGRect(x: 110.0, y: height - 390.0, width: 180.0, height: 180.0), mask: QuartzMaskingView.maskingImage)
            // As above, not being careful with bounds since we are clipping.
            context.fill(bounds)
            
        }

    }


}

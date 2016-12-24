/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Extends `IceCream` to add methods to render the ice cream as a `UIImage`.
*/

import UIKit

extension IceCream {
    
    private struct StickerProperties {
        /// The desired size of an ice cream sticker image.
        static let size = CGSize(width: 300.0, height: 300.0)
        
        /**
            The amount of padding to apply to a sticker when drawn with an opaque
            background.
        */
        static let opaquePadding = CGSize(width: 60.0, height: 10.0)
    }
    
    func renderSticker(opaque: Bool) -> UIImage? {
        guard let partsImage = renderParts() else { return nil }
        
        // Determine the size to draw as a sticker.
        let outputSize: CGSize
        let iceCreamSize: CGSize

        if opaque {
            // Scale the ice cream image to fit in the center of the sticker.
            let scale = min((StickerProperties.size.width - StickerProperties.opaquePadding.width) / partsImage.size.height,
                            (StickerProperties.size.height - StickerProperties.opaquePadding.height) / partsImage.size.width)
            iceCreamSize = CGSize(width: partsImage.size.width * scale, height: partsImage.size.height * scale)
            outputSize = StickerProperties.size
        }
        else {
            // Scale the ice cream to fit it's height into the sticker.
            let scale = StickerProperties.size.width / partsImage.size.height
            iceCreamSize = CGSize(width: partsImage.size.width * scale, height: partsImage.size.height * scale)
            outputSize = iceCreamSize
        }
        
        // Scale the ice cream image to the correct size.
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let image = renderer.image { context in
            let backgroundColor: UIColor
            if opaque {
                // Give the image a colored background.
                backgroundColor = UIColor(red: 250.0 / 255.0, green: 225.0 / 255.0, blue: 235.0 / 255.0, alpha: 1.0)
            }
            else {
                // Give the image a clear background
                backgroundColor = UIColor.clear
            }
            
            // Draw the background
            backgroundColor.setFill()
            context.fill(CGRect(origin: CGPoint.zero, size: StickerProperties.size))
            
            // Draw the scaled composited image.
            var drawRect = CGRect.zero
            drawRect.size = iceCreamSize
            drawRect.origin.x = (outputSize.width / 2.0) - (iceCreamSize.width / 2.0)
            drawRect.origin.y = (outputSize.height / 2.0) - (iceCreamSize.height / 2.0)
            
            partsImage.draw(in: drawRect)
        }
        
        return image
    }

    /// Composites the valid ice cream parts into a single `UIImage`.
    private func renderParts() -> UIImage? {
        // Determine which parts to draw.
        let allParts: [IceCreamPart?] = [topping, scoops, base]
        let partImages = allParts.flatMap { $0?.stickerImage }
        
        guard !partImages.isEmpty else { return nil }
        
        // Calculate the size of the composited ice cream parts image.
        var outputImageSize = CGSize.zero
        outputImageSize.width = partImages.reduce(0) { largestWidth, image in
            return max(largestWidth, image.size.width)
        }
        outputImageSize.height = partImages.reduce(0) { totalHeight, image in
            return totalHeight + image.size.height
        }
        
        // Render the part images into a single composite image.
        let renderer = UIGraphicsImageRenderer(size: outputImageSize)
        let image = renderer.image { context in
            // Draw each of the body parts in a vertica stack.
            var nextYPosition = CGFloat(0.0)
            for partImage in partImages {
                var position = CGPoint.zero
                position.x = outputImageSize.width / 2.0 - partImage.size.width / 2.0
                position.y = nextYPosition
                
                partImage.draw(at: position)
                
                nextYPosition += partImage.size.height
            }
        }
        
        return image
    }
}

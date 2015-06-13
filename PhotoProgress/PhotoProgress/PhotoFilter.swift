/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
                PhotoFilter has a class function for returning a filtered image.
            
*/

import UIKit

class PhotoFilter {
    /// This supports implicit progress composition.
    class func filteredImage(image: UIImage) -> UIImage? {
        /*
            Set up the progress. First thing! It's indeterminate since we don't
            have any information about how long this is going to take.
            
            `NSProgress(totalUnitCount:)` convenience adds itself as a child to the currentProgress.
        */
        let progress = NSProgress(totalUnitCount: -1)
        progress.cancellable = false
        progress.pausable = false
        
        var outputImage: UIImage? = nil
        
        if let filter = CIFilter(name: "CIPhotoEffectTransfer"), cgImage = image.CGImage {
            let ciImage = CIImage(CGImage: cgImage)
            
            filter.setValue(ciImage, forKey: "inputImage")
            
            let outputCIImage = filter.outputImage
            
            let ciContext = CIContext(options: [:])
            
            let outputCGImage = ciContext.createCGImage(outputCIImage, fromRect: outputCIImage.extent)

            outputImage = UIImage(CGImage: outputCGImage)
        }
        
        // We have finished.
        progress.completedUnitCount = 1
        progress.totalUnitCount = 1
        
        return outputImage
    }
}

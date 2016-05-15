/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class that contains all the information needed to display the circular progress indicator badge in the Glance.
*/

import WatchKit

/**
    The `GlanceBadge` class is responsible for rendering the glance badge text found in the Glance. It's also
    responsible for maintaining the image and animation information for the circular indicator displayed in the
    Glance. The information is calculated based on the percentage of complete items out of the total number
    of items.
*/
class GlanceBadge {
    // MARK: Types
    
    struct Constants {
        static let maxDuration: NSTimeInterval = 0.75
    }
    
    // MARK: Properties
    
    /// The total number of items.
    let totalItemCount: Int

    /// The number of complete items.
    let completeItemCount: Int
    
    /// The number of incomplete items.
    let incompleteItemCount: Int
    
    /// The image name of the image to be used for the Glance badge.
    let imageName = "glance-"
    
    /// The range of images to display in the Glance badge.
    var imageRange: NSRange {
        return NSMakeRange(0, rangeLength)
    }
    
    /// The length that the Glance badge image will animate.
    var animationDuration: NSTimeInterval {
        return percentage * Constants.maxDuration
    }
    
    /**
        The background image to be displayed in the Glance badge. The `groupBackgroundImage` draws the text that
        containing the number of remaining items to complete.
    */
    var groupBackgroundImage: UIImage {
        UIGraphicsBeginImageContextWithOptions(groupBackgroundImageSize, false, 2.0)
        
        drawCompleteItemsCountInCurrentContext()
        
        let frame = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
        
        return frame
    }
    
    let groupBackgroundImageSize = CGSizeMake(136, 101)
    
    private let percentage: Double
    
    /**
        Determines the number of images to animate based on `percentage`. If `percentage` is larger than 1.0,
        the `rangeLength` is the total number of available images.
    */
    private var rangeLength: Int {
        var normalizedPercentage = percentage
        
        if normalizedPercentage > 1.0 {
            normalizedPercentage = 1.0
        }
        else if normalizedPercentage == 0.0 {
            return 1
        }
        
        return Int(normalizedPercentage * 45)
    }
    
    /// The color that is used to draw the number of complete items.
    private var completeTextPathColor: UIColor {
        return UIColor(hue: 199.0 / 360.0, saturation: 0.64, brightness: 0.98, alpha: 1.0)
    }

    // MARK: Initializers

    /**
        Initialize a `GlanceBadge` with the information it needs to render the `groupBackgroundImage` in addition
        to the information it needs to animate the circular progress indicator.
    */
    init(totalItemCount: Int, completeItemCount: Int) {
        self.totalItemCount = totalItemCount
        
        self.completeItemCount = completeItemCount

        incompleteItemCount = totalItemCount - completeItemCount

        percentage = totalItemCount > 0 ? Double(completeItemCount) / Double(totalItemCount) : 0
    }
    
    // MARK: Drawing

    /// Draw the text containing the number of complete items.
    func drawCompleteItemsCountInCurrentContext() {
        let center = CGPoint(x: groupBackgroundImageSize.width / 2.0, y: groupBackgroundImageSize.height / 2.0)
        
        let itemsCompleteText = "\(completeItemCount)"
        let completeAttributes = [
            NSFontAttributeName: UIFont.systemFontOfSize(36),
            NSForegroundColorAttributeName: completeTextPathColor
        ]
        let completeSize = itemsCompleteText.sizeWithAttributes(completeAttributes)
        
        // Build and gather information about the done string.
        let doneText = NSLocalizedString("Done", comment: "")
        let doneAttributes = [
            NSFontAttributeName: UIFont.systemFontOfSize(16),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        let doneSize = doneText.sizeWithAttributes(doneAttributes)
        
        let completeRect = CGRect(x: center.x - 0.5 * completeSize.width, y: center.y - 0.5 * completeSize.height - 0.5 * doneSize.height, width: completeSize.width, height: completeSize.height)

        let doneRect = CGRect(x: center.x - 0.5 * doneSize.width, y: center.y + 0.125 * doneSize.height, width: doneSize.width, height: doneSize.height)
        
        itemsCompleteText.drawInRect(completeRect.integral, withAttributes: completeAttributes)

        doneText.drawInRect(doneRect.integral, withAttributes: doneAttributes)
    }
}

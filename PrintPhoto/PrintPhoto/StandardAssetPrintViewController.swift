/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `UIViewController` subclass to handle picking, viewing, and printing of a photo.
*/

import MobileCoreServices
import UIKit

class StandardAssetPrintViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet weak var imageView: UIImageView!

    // MARK: Target / Action Methods
    
    /// Invoked when the user chooses the action icon for printing.
    @IBAction func shareImage() {
        // The image should never be nil (it's set in Interface Builder).
        let image = imageView.image!
        
        // Create a print info object for the activity.
        let printInfo = UIPrintInfo.printInfo()
        
        /*
            This application prints photos. UIKit will pick a paper size and print
            quality appropriate for this content type.
        */
        printInfo.outputType = .Photo
        
        // Use the name from the image metadata we've set.
        printInfo.jobName = "Horse"
        
        let printActivityItems: [AnyObject] = [
            printInfo,
            image
        ]
        
        /*
            Let the `UIActivityViewController` class handle presenting an action
            sheet that will let the user print the image.
        */
        let activityViewController = UIActivityViewController(activityItems: printActivityItems, applicationActivities: nil)
        
        presentViewController(activityViewController, animated: true, completion: nil)
    }
}
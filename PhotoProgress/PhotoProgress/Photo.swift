/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
                Photo represents an image that can be imported.
            
*/

import UIKit

class Photo: NSObject {
    // MARK: Properties

    let imageURL: NSURL
    
    /// Marked "dynamic" so it is KVO observable.
    dynamic var image: UIImage?
    
    /// The photoImport is KVO observable for its progress.
    dynamic var photoImport: PhotoImport?
    
    // MARK: Initializers

    init(URL: NSURL) {
        imageURL = URL.copy() as! NSURL
        
        image = UIImage(named: "PhotoPlaceholder")
    }
    
    /// Kick off the import
    func startImport() -> NSProgress {
        let newImport = PhotoImport(URL: imageURL)

        newImport.completionHandler = { image, error in
            if let image = image {
                // The import is finished. Set our image to the result
                self.image = image
            }
            else {
                self.reportError(error!)
            }

            self.photoImport = nil
        }
        
        newImport.start()
        
        photoImport = newImport
        
        return newImport.progress
    }
    
    private func reportError(error: NSError) {
        if error.domain != NSCocoaErrorDomain || error.code != NSUserCancelledError {
            print("Error importing photo: \(error.localizedDescription)")
        }
    }
    
    /// Go back to the initial state.
    func reset() {
        image = UIImage(named: "PhotoPlaceholder")
        photoImport = nil
    }
}

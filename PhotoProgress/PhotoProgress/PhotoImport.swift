/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
                PhotoImport represents the import operation of a Photo. It combines both the PhotoDownload and PhotoFilter operations.
            
*/

import UIKit

class PhotoImport: NSObject, NSProgressReporting {
    // MARK: Properties

    var completionHandler: ((image: UIImage?, error: NSError?) -> Void)?

    let progress: NSProgress

    let download: PhotoDownload

    // MARK: Initializers

    init(URL: NSURL) {
        progress = NSProgress()
        /* 
            This progress's children are weighted: The download takes up 90% 
            and the filter takes the remaining portion.
        */
        progress.totalUnitCount = 10

        download = PhotoDownload(URL: URL)
    }

    func start() {
        /*
            Use explicit composition to add the download's progress to ours,
            taking 9/10 units.
        */
        progress.addChild(download.progress, withPendingUnitCount: 9)

        download.completionHandler = { data, error in
            guard let imageData = data, image = UIImage(data: imageData) else {
                self.callCompletionHandler(image: nil, error: error)
                return
            }

            /*
                Make self.progress the currentProgress. Since the filteredImage
                supports implicit progress reporting, it will add its progress
                to ours.
            */
            self.progress.becomeCurrentWithPendingUnitCount(1)
            let filteredImage = PhotoFilter.filteredImage(image)
            self.progress.resignCurrent()
            
            self.callCompletionHandler(image: filteredImage, error: nil)
        }

        download.start()
    }
    
    private func callCompletionHandler(image image: UIImage?, error: NSError?) {
        completionHandler?(image: image, error: error)
        completionHandler = nil
    }
}
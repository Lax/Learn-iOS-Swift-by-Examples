/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TodayListManager` class implements convenience methods to create and retrieve the Today list document from the user's ubiquity container.
*/

import Foundation

public class TodayListManager {
    /**
        Fetches the ubiquity container URL for the Today list document. If one isn't found, the block is invoked
        with a `nil` value.
    */
    public class func fetchTodayDocumentURLWithCompletionHandler(completionHandler: (url: NSURL?) -> Void) {
        let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

        dispatch_async(defaultQueue) {
            let url = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)

            let successURL = self.createTodayDocumentURLWithContainerURL(url)
            
            completionHandler(url: successURL)
        }
    }

    public class func createTodayDocumentURLWithContainerURL(containerURL: NSURL?) -> NSURL? {
        if containerURL == nil {
            return nil
        }

        let todayDocumentFolderURL = containerURL!.URLByAppendingPathComponent("Documents")

        let todayDocumentURL = todayDocumentFolderURL.URLByAppendingPathComponent(AppConfiguration.localizedTodayDocumentName).URLByAppendingPathExtension(AppConfiguration.listerFileExtension)

        let fileManager = NSFileManager.defaultManager()

        if fileManager.fileExistsAtPath(todayDocumentURL.path!) {
            return todayDocumentURL
        }

        do {
            try fileManager.createDirectoryAtURL(todayDocumentFolderURL, withIntermediateDirectories: true, attributes: nil)
            
            let sampleTodayDocumentURL = NSBundle(forClass: self).URLForResource("Today", withExtension: AppConfiguration.listerFileExtension)
            
            try fileManager.copyItemAtURL(sampleTodayDocumentURL!, toURL: todayDocumentURL)
            // Make the file's extension hidden.
            try fileManager.setAttributes([NSFileExtensionHidden: true], ofItemAtPath: todayDocumentURL.path!)
            
            return todayDocumentURL
        }
        catch {
            return nil
        }
    }
}

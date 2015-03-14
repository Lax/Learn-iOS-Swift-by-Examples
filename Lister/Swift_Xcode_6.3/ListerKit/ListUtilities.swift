/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListUtilities` class provides a suite of convenience methods for interacting with `List` objects and their associated files.
*/

import Foundation

/// An internal queue to the `ListUtilities` class that is used for `NSFileCoordinator` callbacks.
private let listUtilitiesQueue = NSOperationQueue()

public class ListUtilities {
    // MARK: Properties

    public class var localDocumentsDirectory: NSURL  {
        let documentsURL = sharedApplicationGroupContainer.URLByAppendingPathComponent("Documents", isDirectory: true)
        
        var error: NSError?
        // This will return `true` for success if the directory is successfully created, or already exists.
        let success = NSFileManager.defaultManager().createDirectoryAtURL(documentsURL, withIntermediateDirectories: true, attributes: nil, error: &error)
        
        if success {
            return documentsURL
        }
        else {
            fatalError("The shared application group documents directory doesn't exist and could not be created. Error: \(error!.localizedDescription)")
        }
    }
    
    private class var sharedApplicationGroupContainer: NSURL {
        let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(AppConfiguration.ApplicationGroups.primary)

        if containerURL == nil {
            fatalError("The shared application group container is unavailable. Check your entitlements and provisioning profiles for this target. Details on proper setup can be found in the PDFs referenced from the README.")
        }
        
        return containerURL!
    }
    
    // MARK: List Handling Methods
    
    public class func copyInitialLists() {
        let defaultListURLs = NSBundle.mainBundle().URLsForResourcesWithExtension(AppConfiguration.listerFileExtension, subdirectory: "") as! [NSURL]
        
        for url in defaultListURLs {
            copyURLToDocumentsDirectory(url)
        }
    }
    
    public class func copyTodayList() {
        let url = NSBundle.mainBundle().URLForResource(AppConfiguration.localizedTodayDocumentName, withExtension: AppConfiguration.listerFileExtension)!
        copyURLToDocumentsDirectory(url)
    }

    public class func migrateLocalListsToCloud() {
        let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

        dispatch_async(defaultQueue) {
            let fileManager = NSFileManager.defaultManager()
            
            // Note the call to URLForUbiquityContainerIdentifier(_:) should be on a background queue.
            if let cloudDirectoryURL = fileManager.URLForUbiquityContainerIdentifier(nil) {
                let documentsDirectoryURL = cloudDirectoryURL.URLByAppendingPathComponent("Documents")
                
                let localDocumentURLs = fileManager.contentsOfDirectoryAtURL(ListUtilities.localDocumentsDirectory, includingPropertiesForKeys: nil, options: .SkipsPackageDescendants, error: nil) as? [NSURL]
                
                if let localDocumentURLs = localDocumentURLs {
                    for URL in localDocumentURLs {
                        if URL.pathExtension == AppConfiguration.listerFileExtension {
                            self.makeItemUbiquitousAtURL(URL, documentsDirectoryURL: documentsDirectoryURL)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Convenience
    
    private class func makeItemUbiquitousAtURL(sourceURL: NSURL, documentsDirectoryURL: NSURL) {
        let destinationFileName = sourceURL.lastPathComponent!
        
        let fileManager = NSFileManager()
        let destinationURL = documentsDirectoryURL.URLByAppendingPathComponent(destinationFileName)
        
        if fileManager.isUbiquitousItemAtURL(destinationURL) ||
            fileManager.fileExistsAtPath(destinationURL.path!) {
            // If the file already exists in the cloud, remove the local version and return.
            removeListAtURL(sourceURL, completionHandler: nil)
            return
        }
        
        let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(defaultQueue) {
            fileManager.setUbiquitous(true, itemAtURL: sourceURL, destinationURL: destinationURL, error: nil)
            return
        }
    }

    class func readListAtURL(url: NSURL, completionHandler: (List?, NSError?) -> Void) {
        let fileCoordinator = NSFileCoordinator()
        
        // `url` may be a security scoped resource.
        let successfulSecurityScopedResourceAccess = url.startAccessingSecurityScopedResource()
        
        let readingIntent = NSFileAccessIntent.readingIntentWithURL(url, options: .WithoutChanges)
        fileCoordinator.coordinateAccessWithIntents([readingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                if successfulSecurityScopedResourceAccess {
                    url.stopAccessingSecurityScopedResource()
                }
                
                completionHandler(nil, accessError)
                
                return
            }
            
            // Local variables that will be used as parameters to `completionHandler`.
            var deserializedList: List?
            var readError: NSError?

            if let contents = NSData(contentsOfURL: readingIntent.URL, options: .DataReadingUncached, error: &readError) {
                deserializedList = NSKeyedUnarchiver.unarchiveObjectWithData(contents) as? List
                
                assert(deserializedList != nil, "The provided URL must correspond to a `List` object.")
            }

            if successfulSecurityScopedResourceAccess {
                url.stopAccessingSecurityScopedResource()
            }
            
            completionHandler(deserializedList, readError)
        }
    }

    class func createList(list: List, atURL url: NSURL, completionHandler: (NSError? -> Void)? = nil) {
        let fileCoordinator = NSFileCoordinator()
        
        let writingIntent = NSFileAccessIntent.writingIntentWithURL(url, options: .ForReplacing)
        fileCoordinator.coordinateAccessWithIntents([writingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                completionHandler?(accessError)
                
                return
            }
            
            var error: NSError?

            let seralizedListData = NSKeyedArchiver.archivedDataWithRootObject(list)
            
            let success = seralizedListData.writeToURL(writingIntent.URL, options: .DataWritingAtomic, error: &error)
            
            if success {
                let fileAttributes = [NSFileExtensionHidden: true]
                
                NSFileManager.defaultManager().setAttributes(fileAttributes, ofItemAtPath: writingIntent.URL.path!, error: nil)
            }
            
            completionHandler?(error)
        }
    }
    
    class func removeListAtURL(url: NSURL, completionHandler: (NSError? -> Void)? = nil) {
        let fileCoordinator = NSFileCoordinator()
        
        // `url` may be a security scoped resource.
        let successfulSecurityScopedResourceAccess = url.startAccessingSecurityScopedResource()

        let writingIntent = NSFileAccessIntent.writingIntentWithURL(url, options: .ForDeleting)
        fileCoordinator.coordinateAccessWithIntents([writingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                completionHandler?(accessError)
                
                return
            }
            
            let fileManager = NSFileManager()
            
            var error: NSError?
            
            fileManager.removeItemAtURL(writingIntent.URL, error: &error)
            
            if successfulSecurityScopedResourceAccess {
                url.stopAccessingSecurityScopedResource()
            }

            completionHandler?(error)
        }
    }
    
    // MARK: Convenience
    
    private class func copyURLToDocumentsDirectory(url: NSURL) {
        let toURL = ListUtilities.localDocumentsDirectory.URLByAppendingPathComponent(url.lastPathComponent!)
        let fileCoordinator = NSFileCoordinator()
        var error: NSError?
        
        if NSFileManager().fileExistsAtPath(toURL.path!) {
            // If the file already exists, don't attempt to copy the version from the bundle.
            return
        }
        
        // `url` may be a security scoped resource.
        let successfulSecurityScopedResourceAccess = url.startAccessingSecurityScopedResource()
        
        let movingIntent = NSFileAccessIntent.writingIntentWithURL(url, options: .ForMoving)
        let replacingIntent = NSFileAccessIntent.writingIntentWithURL(toURL, options: .ForReplacing)
        fileCoordinator.coordinateAccessWithIntents([movingIntent, replacingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                println("Couldn't move file: \(movingIntent.URL) to: \(replacingIntent.URL) error: \(accessError.localizedDescription).")
                return
            }
            
            var success = false
            
            let fileManager = NSFileManager()
            
            success = fileManager.copyItemAtURL(movingIntent.URL, toURL: replacingIntent.URL, error: &error)
            
            if success {
                let fileAttributes = [NSFileExtensionHidden: true]
                
                fileManager.setAttributes(fileAttributes, ofItemAtPath: replacingIntent.URL.path!, error: nil)
            }
            
            if successfulSecurityScopedResourceAccess {
                url.stopAccessingSecurityScopedResource()
            }
            
            if !success {
                // An error occured when moving `url` to `toURL`. In your app, handle this gracefully.
                println("Couldn't move file: \(url) to: \(toURL).")
            }
        }
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListUtilities` class provides a suite of convenience methods for interacting with `List` objects and their associated files.
*/

import Foundation

/// An internal queue to the `ListUtilities` class that is used for `NSFileCoordinator` callbacks.
private var listUtilitiesQueue: NSOperationQueue = {
    let queue = NSOperationQueue()
    queue.maxConcurrentOperationCount = 1
    
    return queue
}()

public class ListUtilities {
    // MARK: Properties

    public class var localDocumentsDirectory: NSURL  {
        let documentsURL = sharedApplicationGroupContainer.URLByAppendingPathComponent("Documents", isDirectory: true)
        
        do {
            // This will throw if the directory cannot be successfully created, or does not already exist.
            try NSFileManager.defaultManager().createDirectoryAtURL(documentsURL, withIntermediateDirectories: true, attributes: nil)
            
            return documentsURL
        }
        catch let error as NSError {
            fatalError("The shared application group documents directory doesn't exist and could not be created. Error: \(error.localizedDescription)")
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
        let defaultListURLs = NSBundle.mainBundle().URLsForResourcesWithExtension(AppConfiguration.listerFileExtension, subdirectory: "")!
        
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
                
                do {
                    let localDocumentURLs = try fileManager.contentsOfDirectoryAtURL(ListUtilities.localDocumentsDirectory, includingPropertiesForKeys: nil, options: .SkipsPackageDescendants)
                
                    for URL in localDocumentURLs {
                        if URL.pathExtension == AppConfiguration.listerFileExtension {
                            self.makeItemUbiquitousAtURL(URL, documentsDirectoryURL: documentsDirectoryURL)
                        }
                    }
                }
                catch let error as NSError {
                    print("The contents of the local documents directory could not be accessed. Error: \(error.localizedDescription)")
                }
                // Requiring an additional catch to satisfy exhaustivity is a known issue.
                catch {}
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
            do {
                try fileManager.setUbiquitous(true, itemAtURL: sourceURL, destinationURL: destinationURL)
                return
            }
            catch let error as NSError {
                print("Failed to make list ubiquitous. Error: \(error.localizedDescription)")
            }
            // Requiring an additional catch to satisfy exhaustivity is a known issue.
            catch {}
        }
    }

    public class func readListAtURL(url: NSURL, completionHandler: (List?, NSError?) -> Void) {
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
            
            do {
                let contents = try NSData(contentsOfURL: readingIntent.URL, options: .DataReadingUncached)
                deserializedList = NSKeyedUnarchiver.unarchiveObjectWithData(contents) as? List
                
                assert(deserializedList != nil, "The provided URL must correspond to a `List` object.")
            }
            catch let error as NSError {
                readError = error as NSError
            }
            // Requiring an additional catch to satisfy exhaustivity is a known issue.
            catch {}

            if successfulSecurityScopedResourceAccess {
                url.stopAccessingSecurityScopedResource()
            }
            
            completionHandler(deserializedList, readError)
        }
    }

    public class func createList(list: List, atURL url: NSURL, completionHandler: (NSError? -> Void)? = nil) {
        let fileCoordinator = NSFileCoordinator()
        
        let writingIntent = NSFileAccessIntent.writingIntentWithURL(url, options: .ForReplacing)
        fileCoordinator.coordinateAccessWithIntents([writingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                completionHandler?(accessError)
                
                return
            }
            
            var writeError: NSError?

            let seralizedListData = NSKeyedArchiver.archivedDataWithRootObject(list)
            
            do {
                try seralizedListData.writeToURL(writingIntent.URL, options: .DataWritingAtomic)
            
                let fileAttributes = [NSFileExtensionHidden: true]
                
                try NSFileManager.defaultManager().setAttributes(fileAttributes, ofItemAtPath: writingIntent.URL.path!)
            }
            catch let error as NSError {
                writeError = error
            }
            // Requiring an additional catch to satisfy exhaustivity is a known issue.
            catch {}
            
            completionHandler?(writeError)
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
            
            var removeError: NSError?
            
            do {
                try fileManager.removeItemAtURL(writingIntent.URL)
            }
            catch let error as NSError {
                removeError = error
            }
            // Requiring an additional catch to satisfy exhaustivity is a known issue.
            catch {}
            
            if successfulSecurityScopedResourceAccess {
                url.stopAccessingSecurityScopedResource()
            }

            completionHandler?(removeError)
        }
    }
    
    // MARK: Convenience
    
    private class func copyURLToDocumentsDirectory(url: NSURL) {
        let toURL = ListUtilities.localDocumentsDirectory.URLByAppendingPathComponent(url.lastPathComponent!)
        
        if NSFileManager().fileExistsAtPath(toURL.path!) {
            // If the file already exists, don't attempt to copy the version from the bundle.
            return
        }
        
        copyFromURL(url, toURL: toURL)
    }
    
    public class func copyFromURL(fromURL: NSURL, toURL: NSURL) {
        let fileCoordinator = NSFileCoordinator()
        
        // `url` may be a security scoped resource.
        let successfulSecurityScopedResourceAccess = fromURL.startAccessingSecurityScopedResource()
        
        let fileManager = NSFileManager()
        
        // First copy the source file into a temporary location where the replace can be carried out.
        var tempDirectory: NSURL?
        var tempURL: NSURL?
        do {
            tempDirectory = try fileManager.URLForDirectory(.ItemReplacementDirectory, inDomain: .UserDomainMask, appropriateForURL: toURL, create: true)
            tempURL = tempDirectory!.URLByAppendingPathComponent(toURL.lastPathComponent!)
            try fileManager.copyItemAtURL(fromURL, toURL: tempURL!)
        }
        catch let error as NSError {
            // An error occured when moving `url` to `toURL`. In your app, handle this gracefully.
            print("Couldn't create temp file from: \(fromURL) at: \(tempURL) error: \(error.localizedDescription).")
            print("Error\nCode: \(error.code)\nDomain: \(error.domain)\nDescription: \(error.localizedDescription)\nReason: \(error.localizedFailureReason)\nUser Info: \(error.userInfo)\n")
            
            return
        }

        // Now perform a coordinated replace to move the file from the temporary location to its final destination.
        let movingIntent = NSFileAccessIntent.writingIntentWithURL(tempURL!, options: .ForMoving)
        let mergingIntent = NSFileAccessIntent.writingIntentWithURL(toURL, options: .ForMerging)
        fileCoordinator.coordinateAccessWithIntents([movingIntent, mergingIntent], queue: listUtilitiesQueue) { accessError in
            if accessError != nil {
                print("Couldn't move file: \(fromURL.absoluteString) to: \(toURL.absoluteString) error: \(accessError!.localizedDescription).")
                return
            }
            
            do {
                try NSData(contentsOfURL: movingIntent.URL, options: []).writeToURL(mergingIntent.URL, atomically: true)
                
                let fileAttributes = [NSFileExtensionHidden: true]
                
                try fileManager.setAttributes(fileAttributes, ofItemAtPath: mergingIntent.URL.path!)
            }
            catch let error as NSError {
                // An error occured when moving `url` to `toURL`. In your app, handle this gracefully.
                print("Couldn't move file: \(fromURL) to: \(toURL) error: \(error.localizedDescription).")
                print("Error\nCode: \(error.code)\nDomain: \(error.domain)\nDescription: \(error.localizedDescription)\nReason: \(error.localizedFailureReason)\nUser Info: \(error.userInfo)\n")
            }
            // Requiring an additional catch to satisfy exhaustivity is a known issue.
            catch {}
            
            if successfulSecurityScopedResourceAccess {
                fromURL.stopAccessingSecurityScopedResource()
            }
            
            // Cleanup
            guard let directoryToRemove = tempDirectory else { return }
            do {
                try fileManager.removeItemAtURL(directoryToRemove)
            }
            catch {}
        }
    }
}

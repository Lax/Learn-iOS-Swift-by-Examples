/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The ListCoordinator handles file operations and tracking based on the users storage choice (local vs. cloud).
            
*/

import UIKit

class ListCoordinator: NSObject {
    // MARK: Types

    struct Notifications {
        struct StorageDidChange {
            static let name = "storageChoiceDidChangeNotification"
        }
    }
    
    struct SingleInstance {
        static let sharedListCoordinator: ListCoordinator = {
            let listCoordinator = ListCoordinator()
            
            NSNotificationCenter.defaultCenter().addObserver(listCoordinator, selector: "updateDocumentStorageContainerURL", name: AppConfiguration.Notifications.StorageOptionDidChange.name, object: nil)
            
            return listCoordinator
        }()
    }
    
    // MARK: Class Properties

    class var sharedListCoordinator: ListCoordinator {
        return SingleInstance.sharedListCoordinator
    }
    
    // MARK: Properties
    
    var documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
    
    var todayDocumentURL: NSURL {
        return documentsDirectory.URLByAppendingPathComponent(AppConfiguration.localizedTodayDocumentNameAndExtension)
    }
    
    // MARK: Document Management
    
    func copyInitialDocuments() {
        let defaultListURLs = NSBundle.mainBundle().URLsForResourcesWithExtension(AppConfiguration.listerFileExtension, subdirectory: "") as NSURL[]
        
        for url in defaultListURLs {
            copyFileToDocumentsDirectory(url)
        }
    }
    
    func updateDocumentStorageContainerURL() {
        let oldDocumentsDirectory = documentsDirectory
        
        let fileManager = NSFileManager.defaultManager()

        if AppConfiguration.sharedConfiguration.storageOption != .Cloud {
            documentsDirectory = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL

            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.StorageDidChange.name, object: self)
        }
        else {
            let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            dispatch_async(defaultQueue) {
                // The call to URLForUbiquityContainerIdentifier should be on a background queue.
                let cloudDirectory = fileManager.URLForUbiquityContainerIdentifier(nil)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.documentsDirectory = cloudDirectory.URLByAppendingPathComponent("Documents")
                    
                    let localDocuments = fileManager.contentsOfDirectoryAtURL(oldDocumentsDirectory, includingPropertiesForKeys: nil, options: .SkipsPackageDescendants, error: nil) as NSURL[]?
                    
                    if let localDocuments = localDocuments {
                        for url in localDocuments {
                            if url.pathExtension == AppConfiguration.listerFileExtension {
                                self.makeItemUbiquitousAtURL(url)
                            }
                        }
                    }
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.StorageDidChange.name, object: self)
                }
            }
        }
    }
    
    func makeItemUbiquitousAtURL(sourceURL: NSURL) {
        let destinationFileName = sourceURL.lastPathComponent
        let destinationURL = documentsDirectory.URLByAppendingPathComponent(destinationFileName)
        
        // Upload the file to iCloud on a background queue.
        var defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(defaultQueue) {
            let fileManager = NSFileManager()

            let success = fileManager.setUbiquitous(true, itemAtURL: sourceURL, destinationURL: destinationURL, error: nil)
            
            // If the move wasn't successful, try removing the item locally since the document may already exist in the cloud.
            if !success {
                fileManager.removeItemAtURL(sourceURL, error: nil)
            }
        }
    }

    // MARK: Convenience

    func copyFileToDocumentsDirectory(fromURL: NSURL) {
        let toURL = documentsDirectory.URLByAppendingPathComponent(fromURL.lastPathComponent)

        let coordinator = NSFileCoordinator()

        coordinator.coordinateWritingItemAtURL(fromURL, options: .ForMoving, writingItemAtURL: toURL, options: .ForReplacing, error: nil) { sourceURL, destinationURL in
            let fileManager = NSFileManager()
            var moveError: NSError?

            let success = fileManager.copyItemAtURL(sourceURL, toURL: destinationURL, error: &moveError)
            
            if success {
                fileManager.setAttributes([ NSFileExtensionHidden: true ], ofItemAtPath: destinationURL.path, error: nil)

                NSLog("Moved file: \(sourceURL.absoluteString) to: \(destinationURL.absoluteString).")
            }
            else {
                // In your app, handle this gracefully.
                NSLog("Couldn't move file: \(sourceURL.absoluteString) to: \(destinationURL.absoluteString). Error: \(moveError.description).")
                abort()
            }
        }
    }
    
    func deleteFileAtURL(fileURL: NSURL) {
        let fileCoordinator = NSFileCoordinator()
        var error: NSError?
        
        fileCoordinator.coordinateWritingItemAtURL(fileURL, options: .ForDeleting, error: &error) { writingURL in
            let fileManager = NSFileManager()
            fileManager.removeItemAtURL(writingURL, error: &error)
        }

        if error {
            // In your app, handle this gracefully.
            NSLog("Couldn't delete file at URL \(fileURL.absoluteString). Error: \(error.description).")
            abort()
        }
    }
    
    // MARK: Document Name Helper Methods
    
    func documentURLForName(name: String) -> NSURL {
        return documentsDirectory.URLByAppendingPathComponent(name).URLByAppendingPathExtension(AppConfiguration.listerFileExtension)
    }
    
    func isValidDocumentName(name: String) -> Bool {
        if name.isEmpty {
            return false
        }
        
        let proposedDocumentPath = documentURLForName(name).path
        
        return !NSFileManager.defaultManager().fileExistsAtPath(proposedDocumentPath)
    }
}

/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `CloudListCoordinator` class handles querying for and interacting with lists stored as files in iCloud Drive.
            
*/

import Foundation

@objc public class CloudListCoordinator: ListCoordinator {
    // MARK: Properties
    
    public weak var delegate: ListCoordinatorDelegate?
    
    /// Initialized asynchronously in init(predicate:).
    private var _documentsDirectory: NSURL!
    
    private var documentsDirectory: NSURL {
        var documentsDirectory: NSURL!
        
        dispatch_sync(documentsDirectoryQueue) {
            documentsDirectory = self._documentsDirectory
        }
        
        return documentsDirectory
    }

    private var metadataQuery: NSMetadataQuery
    
    /// A private, local queue to CloudListCoordinator that is used to ensure serial accesss to documentsDirectory.
    private let documentsDirectoryQueue = dispatch_queue_create("com.example.apple-samplecode.lister.cloudlistcoordinator", DISPATCH_QUEUE_CONCURRENT)
    
    // MARK: Initializers
    
    public convenience init(pathExtension: String) {
        let predicate = NSPredicate(format: "(%K.pathExtension = %@)", argumentArray: [NSMetadataItemURLKey, pathExtension])
        
        self.init(predicate: predicate)
    }
    
    public convenience init(lastPathComponent: String) {
        let predicate = NSPredicate(format: "(%K.lastPathComponent = %@)", argumentArray: [NSMetadataItemURLKey, lastPathComponent])

        self.init(predicate: predicate)
    }
    
    private init(predicate: NSPredicate) {
        metadataQuery = NSMetadataQuery()

        // These search scopes search for files in iCloud Drive.
        metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
        
        metadataQuery.predicate = predicate
        
        dispatch_barrier_async(documentsDirectoryQueue) {
            let cloudContainerURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(nil)

            self._documentsDirectory = cloudContainerURL?.URLByAppendingPathComponent("Documents")
        }
        
        // Observe the query.
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.addObserver(self, selector: "metadataQueryDidFinishGathering:", name: NSMetadataQueryDidFinishGatheringNotification, object: metadataQuery)

        notificationCenter.addObserver(self, selector: "metadataQueryDidUpdate:", name: NSMetadataQueryDidUpdateNotification, object: metadataQuery)
    }
    
    // MARK: Lifetime
    
    deinit {
        // Stop observing the query.
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: NSMetadataQueryDidFinishGatheringNotification, object: metadataQuery)
        notificationCenter.removeObserver(self, name: NSMetadataQueryDidUpdateNotification, object: metadataQuery)
    }
    
    // MARK: ListCoordinator
    
    public func startQuery() {
        metadataQuery.startQuery()
    }
    
    public func stopQuery() {
        metadataQuery.stopQuery()
    }
    
    public func createURLForList(list: List, withName name: String) {
        let documentURL = documentURLForName(name)
        
        ListUtilities.createList(list, atURL: documentURL) { error in
            if let realError = error {
                self.delegate?.listCoordinatorDidFailCreatingListAtURL(documentURL, withError: realError)
            }
            else {
                self.delegate?.listCoordinatorDidUpdateContents(insertedURLs: [documentURL], removedURLs: [], updatedURLs: [])
            }
        }
    }

    public func canCreateListWithName(name: String) -> Bool {
        if name.isEmpty {
            return false
        }
        
        let documentURL = documentURLForName(name)
        
        return !NSFileManager.defaultManager().fileExistsAtPath(documentURL.path!)
    }

    public func removeListAtURL(URL: NSURL) {
        ListUtilities.removeListAtURL(URL) { error in
            if let realError = error {
                self.delegate?.listCoordinatorDidFailRemovingListAtURL(URL, withError: realError)
            }
            else {
                self.delegate?.listCoordinatorDidUpdateContents(insertedURLs: [], removedURLs: [URL], updatedURLs: [])
            }
        }
    }
    
    // MARK: NSMetadataQuery Notifications
    
    @objc private func metadataQueryDidFinishGathering(notifcation: NSNotification) {
        metadataQuery.disableUpdates()

        let metadataItems = metadataQuery.results as [NSMetadataItem]

        let insertedURLs = metadataItems.map { $0.valueForAttribute(NSMetadataItemURLKey) as NSURL }

        delegate?.listCoordinatorDidUpdateContents(insertedURLs: insertedURLs, removedURLs: [], updatedURLs: [])
        
        metadataQuery.enableUpdates()
    }

    /**
        Private methods that are used with Objective-C for notifications, target / action, etc. should
        be marked as @objc.
    */
    @objc private func metadataQueryDidUpdate(notification: NSNotification) {
        metadataQuery.disableUpdates()
        
        var insertedURLs = [NSURL]()
        var removedURLs = [NSURL]()
        var updatedURLs = [NSURL]()
        
        let metadataItemToURLTransform: NSMetadataItem -> NSURL = { metadataItem in
            return metadataItem.valueForAttribute(NSMetadataItemURLKey) as NSURL
        }

        let insertedMetadataItemsOrNil: AnyObject? = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey]
        if let insertedMetadataItems = insertedMetadataItemsOrNil as? [NSMetadataItem] {
            insertedURLs += insertedMetadataItems.map(metadataItemToURLTransform)
        }
        
        let removedMetadataItemsOrNil: AnyObject? = notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey]
        if let removedMetadataItems = removedMetadataItemsOrNil as? [NSMetadataItem] {
            removedURLs += removedMetadataItems.map(metadataItemToURLTransform)
        }
        
        let updatedMetadataItemsOrNil: AnyObject? = notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey]
        if let updatedMetadataItems = updatedMetadataItemsOrNil as? [NSMetadataItem] {
            let completelyDownloadedUpdatedMetadataItems = updatedMetadataItems.filter { updatedMetadataItem in
                let downloadStatus = updatedMetadataItem.valueForAttribute(NSMetadataUbiquitousItemDownloadingStatusKey) as String

                return downloadStatus == NSMetadataUbiquitousItemDownloadingStatusCurrent
            }

            updatedURLs += completelyDownloadedUpdatedMetadataItems.map(metadataItemToURLTransform)
        }
        
        delegate?.listCoordinatorDidUpdateContents(insertedURLs: insertedURLs, removedURLs: removedURLs, updatedURLs: updatedURLs)
        
        metadataQuery.enableUpdates()
    }
    
    // MARK: Convenience
    
    private func documentURLForName(name: String) -> NSURL {
        let documentURLWithoutExtension = documentsDirectory.URLByAppendingPathComponent(name)
        
        return documentURLWithoutExtension.URLByAppendingPathExtension(AppConfiguration.listerFileExtension)
    }
}

/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `LocalListCoordinator` class handles querying for and interacting with lists stored as local files.
            
*/

import Foundation

@objc public class LocalListCoordinator: ListCoordinator {
    // MARK: Properties

    public weak var delegate: ListCoordinatorDelegate?

    private let predicate: NSPredicate

    // MARK: Initializers
    
    public init(pathExtension: String) {
        predicate = NSPredicate(format: "(pathExtension = %@)", argumentArray: [pathExtension])
    }
    
    public init(lastPathComponent: String) {
        predicate = NSPredicate(format: "(lastPathComponent = %@)", argumentArray: [lastPathComponent])
    }
    
    // MARK: ListCoordinator
    
    public func startQuery() {
        let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

        dispatch_async(defaultQueue) {
            let fileManager = NSFileManager.defaultManager()
            
            // Fetch the list documents from container documents directory.
            let localDocumentURLs = fileManager.contentsOfDirectoryAtURL(ListUtilities.localDocumentsDirectory, includingPropertiesForKeys: nil, options: .SkipsPackageDescendants, error: nil) as [NSURL]
          
            var localListURLs = localDocumentURLs.filter { self.predicate.evaluateWithObject($0) }

            if !localListURLs.isEmpty {
                self.delegate?.listCoordinatorDidUpdateContents(insertedURLs: localListURLs, removedURLs: [], updatedURLs: [])
            }
        }
    }
    
    public func stopQuery() {
        /**
            Nothing to do here since the documents are local and everything gets funnelled this class
            if the storage is local.
        */
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
    
    // MARK: Convenience
    
    private func documentURLForName(name: String) -> NSURL {
        let documentURLWithoutExtension = ListUtilities.localDocumentsDirectory.URLByAppendingPathComponent(name)

        return documentURLWithoutExtension.URLByAppendingPathExtension(AppConfiguration.listerFileExtension)
    }
}

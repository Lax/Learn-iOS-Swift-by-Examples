/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `LocalListCoordinator` class handles querying for and interacting with lists stored as local files.
*/

import Foundation

@objc public class LocalListCoordinator: ListCoordinator, DirectoryMonitorDelegate {
    // MARK: Properties

    public weak var delegate: ListCoordinatorDelegate?
    
    /**
        A GCD based monitor used to observe changes to the local documents directory.
    */
    private var directoryMonitor: DirectoryMonitor
    
    /**
        Closure executed after the first update provided by the coordinator regarding tracked
        URLs.
    */
    private var firstQueryUpdateHandler: (Void -> Void)?

    private let predicate: NSPredicate
    
    private var currentLocalContents: [NSURL] = []

    // MARK: Initializers
    
    public init(pathExtension: String, firstQueryUpdateHandler: (Void -> Void)? = nil) {
        directoryMonitor = DirectoryMonitor(URL: ListUtilities.localDocumentsDirectory)
        
        predicate = NSPredicate(format: "(pathExtension = %@)", argumentArray: [pathExtension])
        self.firstQueryUpdateHandler = firstQueryUpdateHandler
        
        directoryMonitor.delegate = self
    }
    
    public init(lastPathComponent: String, firstQueryUpdateHandler: (Void -> Void)? = nil) {
        directoryMonitor = DirectoryMonitor(URL: ListUtilities.localDocumentsDirectory)
        
        predicate = NSPredicate(format: "(lastPathComponent = %@)", argumentArray: [lastPathComponent])
        self.firstQueryUpdateHandler = firstQueryUpdateHandler
        
        directoryMonitor.delegate = self
    }
    
    // MARK: ListCoordinator
    
    public func startQuery() {
        processChangeToLocalDocumentsDirectory()
        
        directoryMonitor.startMonitoring()
    }
    
    public func stopQuery() {
        directoryMonitor.stopMonitoring()
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
    
    // MARK: DirectoryMonitorDelegate
    
    func directoryMonitorDidObserveChange(directoryMonitor: DirectoryMonitor) {
        processChangeToLocalDocumentsDirectory()
    }
    
    // MARK: Convenience
    
    func processChangeToLocalDocumentsDirectory() {
        let defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(defaultQueue) {
            let fileManager = NSFileManager.defaultManager()
            
            // Fetch the list documents from container documents directory.
            let localDocumentURLs = fileManager.contentsOfDirectoryAtURL(ListUtilities.localDocumentsDirectory, includingPropertiesForKeys: nil, options: .SkipsPackageDescendants, error: nil) as [NSURL]
            
            var localListURLs = localDocumentURLs.filter { self.predicate.evaluateWithObject($0) }
            
            if !localListURLs.isEmpty {
                let insertedURLs = localListURLs.filter { !contains(self.currentLocalContents, $0) }
                let removedURLs = self.currentLocalContents.filter { !contains(localListURLs, $0) }
                
                self.delegate?.listCoordinatorDidUpdateContents(insertedURLs: insertedURLs, removedURLs: removedURLs, updatedURLs: [])
                
                self.currentLocalContents = localListURLs
            }
            
            // Execute the `firstQueryUpdateHandler`, it will contain the closure from initialization on first update.
            if let handler = self.firstQueryUpdateHandler {
                handler()
                // Set `firstQueryUpdateHandler` to an empty closure so that the handler provided is only run on first update.
                self.firstQueryUpdateHandler = nil
            }
        }
    }
    
    private func documentURLForName(name: String) -> NSURL {
        let documentURLWithoutExtension = ListUtilities.localDocumentsDirectory.URLByAppendingPathComponent(name)

        return documentURLWithoutExtension.URLByAppendingPathExtension(AppConfiguration.listerFileExtension)
    }
}

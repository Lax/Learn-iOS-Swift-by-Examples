/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `LocalListCoordinator` class handles querying for and interacting with lists stored as local files.
*/

import Foundation

/**
    An object that conforms to the `LocalListCoordinator` protocol and is responsible for implementing
    entry points in order to communicate with an `ListCoordinatorDelegate`. In the case of Lister,
    this is the `ListsController` instance. The main responsibility of a `LocalListCoordinator` is
    to track different `NSURL` instances that are important. The local coordinator is responsible for
    making sure that the `ListsController` knows about the current set of documents that are available
    in the app's local container.

    There are also other responsibilities that an `LocalListCoordinator` must have that are specific
    to the underlying storage mechanism of the coordinator. A `CloudListCoordinator` determines whether
    or not a new list can be created with a specific name, it removes URLs tied to a specific list, and
    it is also responsible for listening for updates to any changes that occur at a specific URL
    (e.g. a list document is updated on another device, etc.).

    Instances of `LocalListCoordinator` can search for URLs in an asynchronous way. When a new `NSURL`
    instance is found, removed, or updated, the `ListCoordinator` instance must make its delegate
    aware of the updates. If a failure occured in removing or creating an `NSURL` for a given list,
    it must make its delegate aware by calling one of the appropriate error methods defined in the
    `ListCoordinatorDelegate` protocol.
*/
public class LocalListCoordinator: ListCoordinator, DirectoryMonitorDelegate {
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
    
    private var currentLocalContents = [NSURL]()
    
    public var documentsDirectory: NSURL {
        return ListUtilities.localDocumentsDirectory
    }

    // MARK: Initializers
    
    /**
        Initializes an `LocalListCoordinator` based on a path extension used to identify files that can be
        managed by the app. Also provides a block parameter that can be used to provide actions to be executed
        when the coordinator returns its first set of documents. This coordinator monitors the app's local
        container.
        
        - parameter pathExtension: The extension that should be used to identify documents of interest to this coordinator.
        - parameter firstQueryUpdateHandler: The handler that is executed once the first results are returned.
    */
    public init(pathExtension: String, firstQueryUpdateHandler: (Void -> Void)? = nil) {
        directoryMonitor = DirectoryMonitor(URL: ListUtilities.localDocumentsDirectory)
        
        predicate = NSPredicate(format: "(pathExtension = %@)", argumentArray: [pathExtension])
        self.firstQueryUpdateHandler = firstQueryUpdateHandler
        
        directoryMonitor.delegate = self
    }
    
    /**
        Initializes an `LocalListCoordinator` based on a single document used to identify a file that should
        be monitored. Also provides a block parameter that can be used to provide actions to be executed when the
        coordinator returns its initial result. This coordinator monitors the app's local container.
        
        - parameter lastPathComponent: The file name that should be monitored by this coordinator.
        - parameter firstQueryUpdateHandler: The handler that is executed once the first results are returned.
    */
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
    
    public func copyListFromURL(URL: NSURL, toListWithName name: String) {
        let documentURL = documentURLForName(name)
        
        ListUtilities.copyFromURL(URL, toURL: documentURL)
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
            
            do {
                // Fetch the list documents from containerd documents directory.
                let localDocumentURLs = try fileManager.contentsOfDirectoryAtURL(ListUtilities.localDocumentsDirectory, includingPropertiesForKeys: nil, options: .SkipsPackageDescendants)
                
                let localListURLs = localDocumentURLs.filter { self.predicate.evaluateWithObject($0) }
                
                if !localListURLs.isEmpty {
                    let insertedURLs = localListURLs.filter { !self.currentLocalContents.contains($0) }
                    let removedURLs = self.currentLocalContents.filter { !localListURLs.contains($0) }
                    
                    self.delegate?.listCoordinatorDidUpdateContents(insertedURLs: insertedURLs, removedURLs: removedURLs, updatedURLs: [])
                    
                    self.currentLocalContents = localListURLs
                }
            }
            catch let error as NSError {
                print("An error occurred accessing the contents of a directory. Domain: \(error.domain) Code: \(error.code)")
            }
            // Requiring an additional catch to satisfy exhaustivity is a known issue.
            catch {}
            
            // Execute the `firstQueryUpdateHandler`, it will contain the closure from initialization on first update.
            if let handler = self.firstQueryUpdateHandler {
                handler()
                // Set `firstQueryUpdateHandler` to an empty closure so that the handler provided is only run on first update.
                self.firstQueryUpdateHandler = nil
            }
        }
    }
    
    private func documentURLForName(name: String) -> NSURL {
        let documentURLWithoutExtension = documentsDirectory.URLByAppendingPathComponent(name)

        return documentURLWithoutExtension.URLByAppendingPathExtension(AppConfiguration.listerFileExtension)
    }
}

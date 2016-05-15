/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the `DocumentBrowserController` which handles display of all elements of the Document Browser.  It listens for notifications from the `DocumentBrowserQuery`, `RecentModelObjectsManager`, and `ThumbnailCache` and updates the `UICollectionView` for the Document Browser when events
                occur.
*/

import UIKit

/**
    The `DocumentBrowserController` registers for notifications from the `ThumbnailCache`,
    the `RecentModelObjectsManager`, and the `DocumentBrowserQuery` and updates the UI for
    changes.  It also handles pushing the `DocumentViewController` when a document is
    selected.
*/
class DocumentBrowserController: UICollectionViewController, DocumentBrowserQueryDelegate, RecentModelObjectsManagerDelegate, ThumbnailCacheDelegate {
    // MARK: Properties
    
    static let recentsSection = 0
    static let documentsSection = 1

    var documents = [DocumentBrowserModelObject]()
    
    var recents = [RecentModelObject]()
    
    var browserQuery = DocumentBrowserQuery()
    
    let recentsManager = RecentModelObjectsManager()
    
    let thumbnailCache = ThumbnailCache(thumbnailSize: CGSize(width: 220, height: 270))
    
    private let coordinationQueue: NSOperationQueue = {
        let coordinationQueue = NSOperationQueue()
        
        coordinationQueue.name = "com.example.apple-samplecode.ShapeEdit.documentbrowser.coordinationQueue"
        
        return coordinationQueue
    }()
    
    // MARK: View Controller Override
    
    override func awakeFromNib() {
        // Initialize ourself as the delegate of our created queries.
        browserQuery.delegate = self

        thumbnailCache.delegate = self
        
        recentsManager.delegate = self
        
        title = "My Favorite Shapes & Colors"
    }

    override func viewDidAppear(animated: Bool) {
        /*
            Our app only supports iCloud Drive so display an error message when 
            it is disabled.
        */
        if NSFileManager().ubiquityIdentityToken == nil {
            let alertController = UIAlertController(title: "iCloud is disabled", message: "Please enable iCloud Drive in Settings to use this app", preferredStyle: .Alert)
            
            let alertAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            
            alertController.addAction(alertAction)
            
            presentViewController(alertController, animated: true, completion: nil)
        }
    }

    @IBAction func insertNewObject(sender: UIBarButtonItem) {
        // Create a document with the default template.
        let templateURL = NSBundle.mainBundle().URLForResource("Template", withExtension: "shapeFile")!

        createNewDocumentWithTemplate(templateURL)
    }
    
    // MARK: DocumentBrowserQueryDelegate

    func documentBrowserQueryResultsDidChangeWithResults(results: [DocumentBrowserModelObject], animations: [DocumentBrowserAnimation]) {
        if animations == [.Reload] {
            /*
                Reload means we're reloading all items, so mark all thumbnails
                dirty and reload the collection view.
            */
            documents = results
            thumbnailCache.markThumbnailCacheDirty()
            collectionView?.reloadData()
        }
        else {
            var indexPathsNeedingReload = [NSIndexPath]()
            
            let collectionView = self.collectionView!

            collectionView.performBatchUpdates({
                /*
                    Perform all animations, and invalidate the thumbnail cache 
                    where necessary.
                */
                indexPathsNeedingReload = self.processAnimations(animations, oldResults: self.documents, newResults: results, section: DocumentBrowserController.documentsSection)

                // Save the new results.
                self.documents = results
            }, completion: { success in
                if success {
                    collectionView.reloadItemsAtIndexPaths(indexPathsNeedingReload)
                }
            })
        }
    }

    // MARK: RecentModelObjectsManagerDelegate
    
    func recentsManagerResultsDidChange(results: [RecentModelObject], animations: [DocumentBrowserAnimation]) {
        if animations == [.Reload] {
            recents = results
            
            let indexSet = NSIndexSet(index: DocumentBrowserController.recentsSection)

            collectionView?.reloadSections(indexSet)
        }
        else {
            var indexPathsNeedingReload = [NSIndexPath]()

            let collectionView = self.collectionView!
            collectionView.performBatchUpdates({
                /*
                    Perform all animations, and invalidate the thumbnail cache 
                    where necessary.
                */
                indexPathsNeedingReload = self.processAnimations(animations, oldResults: self.recents, newResults: results, section: DocumentBrowserController.recentsSection)

                // Save the results
                self.recents = results
            }, completion: { success in
                if success {
                    collectionView.reloadItemsAtIndexPaths(indexPathsNeedingReload)
                }
            })
        }
    }
    
    // MARK: Animation Support

    private func processAnimations<ModelType: ModelObject>(animations: [DocumentBrowserAnimation], oldResults: [ModelType], newResults: [ModelType], section: Int) -> [NSIndexPath] {
        let collectionView = self.collectionView!
        
        var indexPathsNeedingReload = [NSIndexPath]()
        
        for animation in animations {
            switch animation {
                case .Add(let row):
                    collectionView.insertItemsAtIndexPaths([
                        NSIndexPath(forRow: row, inSection: section)
                    ])
                
                case .Delete(let row):
                    collectionView.deleteItemsAtIndexPaths([
                        NSIndexPath(forRow: row, inSection: section)
                    ])
                    
                    let URL = oldResults[row].URL
                    self.thumbnailCache.removeThumbnailForURL(URL)
                    
                case .Move(let from, let to):
                    let fromIndexPath = NSIndexPath(forRow: from, inSection: section)
                    
                    let toIndexPath = NSIndexPath(forRow: to, inSection: section)
                    
                    collectionView.moveItemAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
                
                case .Update(let row):
                    indexPathsNeedingReload += [
                        NSIndexPath(forRow: row, inSection: section)
                    ]
                    
                    let URL = newResults[row].URL
                    self.thumbnailCache.markThumbnailDirtyForURL(URL)
                    
                case .Reload:
                    fatalError("Unreachable")
            }
        }
        
        return indexPathsNeedingReload
    }

    // MARK: ThumbnailCacheDelegateType
    
    func thumbnailCache(thumbnailCache: ThumbnailCache, didLoadThumbnailsForURLs URLs: Set<NSURL>) {
        let documentPaths: [NSIndexPath] = URLs.flatMap { URL in
            guard let matchingDocumentIndex = documents.indexOf({ $0.URL == URL }) else { return nil }
            
            return NSIndexPath(forItem: matchingDocumentIndex, inSection: DocumentBrowserController.documentsSection)
        }
        
        let recentPaths: [NSIndexPath] = URLs.flatMap { URL in
            guard let matchingRecentIndex = recents.indexOf({ $0.URL == URL }) else { return nil }
            
            return NSIndexPath(forItem: matchingRecentIndex, inSection: DocumentBrowserController.recentsSection)
        }
        
        self.collectionView!.reloadItemsAtIndexPaths(documentPaths + recentPaths)
    }

    // MARK: - Collection View

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == DocumentBrowserController.recentsSection {
            return recents.count
        }

        return documents.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! DocumentCell

        let document = documentForIndexPath(indexPath)
        
        cell.title = document.displayName
        cell.subtitle = document.subtitle
        
        cell.thumbnail = thumbnailCache.loadThumbnailForURL(document.URL)
        
        return cell
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "Header", forIndexPath: indexPath) as! HeaderView

            header.title = indexPath.section == DocumentBrowserController.recentsSection ? "Recently Viewed" : "All Shapes"
            
            return header
        }

        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath)
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // Locate the selected document and open it.
        let document = documentForIndexPath(indexPath)

        openDocumentAtURL(document.URL)
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let document = documentForIndexPath(indexPath)
        
        let visibleURLs: [NSURL] = collectionView.indexPathsForVisibleItems().map { indexPath in
            let document = documentForIndexPath(indexPath)
            
            return document.URL
        }
        
        if !visibleURLs.contains(document.URL) {
            thumbnailCache.cancelThumbnailLoadForURL(document.URL)
        }
    }

    
    // MARK: Document handling support
        
    private func documentBrowserModelObjectForURL(url: NSURL) -> DocumentBrowserModelObject? {
        guard let matchingDocumentIndex = documents.indexOf({ $0.URL == url }) else { return nil }
        
        return documents[matchingDocumentIndex]
    }

    private func documentForIndexPath(indexPath: NSIndexPath) -> ModelObject {
        if indexPath.section == DocumentBrowserController.recentsSection {
            return recents[indexPath.row]
        }
        else if indexPath.section == DocumentBrowserController.documentsSection {
            return documents[indexPath.row]
        }

        fatalError("Unknown section.")
    }
    
    private func presentCloudDisabledAlert() {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            let alertController = UIAlertController(title: "iCloud is disabled", message: "Please enable iCloud Drive in Settings to use this app", preferredStyle: .Alert)
            
            let alertAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            
            alertController.addAction(alertAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    private func createNewDocumentWithTemplate(templateURL: NSURL) {
        /*
            We don't create a new document on the main queue because the call to
            fileManager.URLForUbiquityContainerIdentifier could potentially block
        */
        coordinationQueue.addOperationWithBlock {
            let fileManager = NSFileManager()
            guard let baseURL = fileManager.URLForUbiquityContainerIdentifier(nil)?.URLByAppendingPathComponent("Documents").URLByAppendingPathComponent("Untitled") else {
                
                self.presentCloudDisabledAlert()
                
                return
            }

            let ext = "shapeFile"
            
            var target = baseURL.URLByAppendingPathExtension(ext)
            
            /*
                We will append this value to our name until we find a path that
                doesn't exist.
            */
            var nameSuffix = 2
            
            /*
                Find a suitable filename that doesn't already exist on disk.
                Do not use `fileManager.fileExistsAtPath(target.path!)` because
                the document might not have downloaded yet.
            */
            while target.checkPromisedItemIsReachableAndReturnError(nil) {
                target = NSURL(fileURLWithPath: baseURL.path! + "-\(nameSuffix).\(ext)")

                nameSuffix += 1
            }
            
            // Coordinate reading on the source path and writing on the destination path to copy.
            let readIntent = NSFileAccessIntent.readingIntentWithURL(templateURL, options: [])

            let writeIntent = NSFileAccessIntent.writingIntentWithURL(target, options: .ForReplacing)
            
            NSFileCoordinator().coordinateAccessWithIntents([readIntent, writeIntent], queue: self.coordinationQueue) { error in
                if error != nil {
                    return
                }
                
                do {
                    try fileManager.copyItemAtURL(readIntent.URL, toURL: writeIntent.URL)
                    
                    try writeIntent.URL.setResourceValue(true, forKey: NSURLHasHiddenExtensionKey)
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.openDocumentAtURL(writeIntent.URL)
                    }
                }
                catch {
                    fatalError("Unexpected error during trivial file operations: \(error)")
                }
            }
        }
    }
    
    // MARK: - Document Opening
    
    func documentWasOpenedSuccessfullyAtURL(URL: NSURL) {
        recentsManager.addURLToRecents(URL)
    }
    
    func openDocumentAtURL(url: NSURL) {
        // Push a view controller which will manage editing the document.
        let controller = storyboard!.instantiateViewControllerWithIdentifier("Document") as! DocumentViewController

        controller.documentURL = url
        
        showViewController(controller, sender: self)
    }

    func openDocumentAtURL(url: NSURL, copyBeforeOpening: Bool) {
        if copyBeforeOpening  {
            // Duplicate the document and open it.
            createNewDocumentWithTemplate(url)
        }
        else {
            openDocumentAtURL(url)
        }
    }
}

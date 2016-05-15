/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `ThumbnailCache` manages loading thumbnails on background queues and keeping track of which thumbnails are up to date. It also stores thumbnails in a cache for quick access at a later time.
*/

import UIKit

/**
    This delegate protocol is implemented so we can receive a callback when the
    thumbnail is loaded.
*/
protocol ThumbnailCacheDelegate: class {
    func thumbnailCache(thumbnailCache: ThumbnailCache, didLoadThumbnailsForURLs: Set<NSURL>)
}

/**
    The thumbnail cache class handles loading thumbnails, scaling the thumbnails
    to the propper size for our UI and informing its delegate once they're loaded.
*/
class ThumbnailCache {
    // MARK: Properties

    private let cache: NSCache = {
        let cache = NSCache()
        
        cache.name = "com.example.apple-samplecode.ShapeEdit.thumbnailcache.cache"
        cache.countLimit = 64
        
        return cache
    }()

    private let workerQueue: NSOperationQueue = {
        let workerQueue = NSOperationQueue()
        
        workerQueue.name = "com.example.apple-samplecode.ShapeEdit.thumbnailcache.workerQueue"
        
        workerQueue.maxConcurrentOperationCount = ThumbnailCache.concurrentThumbnailOperations
        
        return workerQueue
    }()
    
    let thumbnailSize: CGSize
    
    private var URLsNeedingReload = Set<NSURL>()
    
    private var pendingThumbnails = [Int: Set<NSURL>]()
    
    private var cleanThumbnailDocumentIDs = Set<Int>()
    
    private var unscheduledDocumentIDs = [Int]()
    
    private var runningDocumentIDCount = 0
    
    private var scheduleSource: dispatch_source_t
    
    private var flushSource: dispatch_source_t
    
    weak var delegate: ThumbnailCacheDelegate?
    
    static let concurrentThumbnailOperations = 4

    // MARK: Initialization

    init (thumbnailSize:CGSize) {
        self.thumbnailSize = thumbnailSize
        
        scheduleSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_OR, 0, 0, dispatch_get_main_queue())
        
        flushSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_OR, 0, 0, dispatch_get_main_queue())
        
        // Set up our scheduler which will manage an array of pending thumbnails
        dispatch_source_set_event_handler(scheduleSource) { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.scheduleThumbnailLoading()
        }
        
        dispatch_resume(scheduleSource)
        
        // Set up our source which will push a batch of thumbnail updates at once.
        dispatch_source_set_event_handler(flushSource) { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.thumbnailCache(strongSelf, didLoadThumbnailsForURLs: strongSelf.URLsNeedingReload)
            strongSelf.URLsNeedingReload.removeAll()
        }
        
        dispatch_resume(flushSource)
    }

    // MARK: Cache Management
    
    func markThumbnailCacheDirty() {
        // We've been asked to reload the UI and need to reload all items in the cache.
        cleanThumbnailDocumentIDs.removeAll()
    }

    func markThumbnailDirtyForURL(URL: NSURL) {
        /*
            Mark the item dirty so that we know the next time we are asked for the
            thumbnail that we need to reload it.
        */
        if let documentIdentifier = documentIdentifierForURL(URL) {
            cleanThumbnailDocumentIDs.remove(documentIdentifier)
        }
    }

    func removeThumbnailForURL(URL: NSURL) {
        /*
            Remove the item entirely from the cache because the item existing in the cache no
            longer makes sense for that URL.
        */
        if let documentIdentifier = documentIdentifierForURL(URL) {
            cache.removeObjectForKey(documentIdentifier)
            
            cleanThumbnailDocumentIDs.remove(documentIdentifier)
        }
    }
    
    func cancelThumbnailLoadForURL(URL: NSURL) {
        if let documentIdentifier = documentIdentifierForURL(URL) {
            if let index = unscheduledDocumentIDs.indexOf(documentIdentifier) {
                unscheduledDocumentIDs.removeAtIndex(index)
                
                pendingThumbnails[documentIdentifier] = nil
            }
        }
    }
    

    // MARK: Thumbnail Loading
    
    private func documentIdentifierForURL(URL: NSURL) -> Int? {
        // Look up the document identifier on the URL which uniquely identifies a document.
        do {
            var documentIdentifier: AnyObject?
            try URL.getPromisedItemResourceValue(&documentIdentifier, forKey: NSURLDocumentIdentifierKey)
            
            return documentIdentifier as? Int
        }
        catch {
            return nil
        }
    }
    
    private func scheduleThumbnailLoading() {
        // While we have work left to schedule, schedule a thumbnail fetch in the background
        while self.runningDocumentIDCount < ThumbnailCache.concurrentThumbnailOperations {
            guard let nextDocumentID = self.unscheduledDocumentIDs.first else { break }
            
            let index = self.unscheduledDocumentIDs.indexOf(nextDocumentID)!
            self.unscheduledDocumentIDs.removeAtIndex(index)
            
            self.runningDocumentIDCount += 1
            
            let thumbnailURL = self.pendingThumbnails[nextDocumentID]!.first!
            
            let alreadyCached = self.cache.objectForKey(nextDocumentID) != nil ? true : false
            
            self.loadThumbnailInBackgroundForURL(thumbnailURL, documentIdentifier: nextDocumentID, alreadyCached: alreadyCached)
        }
    }
    
    private func loadThumbnailInBackgroundForURL(URL: NSURL, documentIdentifier: Int, alreadyCached: Bool) {
        self.workerQueue.addOperationWithBlock {
            if let thumbnail = self.loadThumbnailFromDiskForURL(URL) {
                // Scale the image to correct size.
                UIGraphicsBeginImageContextWithOptions(self.thumbnailSize, false, UIScreen.mainScreen().scale)
                
                let thumbnailRect = CGRect(x: 0, y: 0, width: self.thumbnailSize.width, height: self.thumbnailSize.height)
                
                thumbnail.drawInRect(thumbnailRect)
                
                let scaledThumbnail = UIGraphicsGetImageFromCurrentImageContext()
                
                UIGraphicsEndImageContext()
                
                /*
                    Thumbnail loading succeeded. Save the thumbnail and call the
                    reload blocks to reload the UI.
                */
                self.cache.setObject(scaledThumbnail, forKey: documentIdentifier)
                
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.cleanThumbnailDocumentIDs.insert(documentIdentifier)
                    
                    // Fetch all URLs for this `documentIdentifier`, not just the provided `URL` parameter.
                    let URLsForDocumentIdentifier = self.pendingThumbnails[documentIdentifier]!
                    
                    // Join the URLs for this identifier to any other URLs due for updating.
                    self.URLsNeedingReload.unionInPlace(URLsForDocumentIdentifier)
                    
                    self.pendingThumbnails[documentIdentifier] = nil
                    
                    // Trigger the event handler for the `flushSource` updating a batch of thumbnails.
                    dispatch_source_merge_data(self.flushSource, 1)

                    self.runningDocumentIDCount -= 1
                    
                    // Trigger the event handler for the `scheduleSource` scheduling thumbnail loading.
                    dispatch_source_merge_data(self.scheduleSource, 1)
                }
            }
            else {
                // Thumbnail loading failed. Just use the most recent cached thumbail.
                if !alreadyCached {
                    let image = UIImage(named: "MissingThumbnail.png")!
                    self.cache.setObject(image, forKey: documentIdentifier)
                }
                
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.cleanThumbnailDocumentIDs.insert(documentIdentifier)
                    
                    self.pendingThumbnails[documentIdentifier] = nil

                    self.runningDocumentIDCount -= 1
                    
                    // Trigger the event handler for the `scheduleSource` scheduling thumbnail loading.
                    dispatch_source_merge_data(self.scheduleSource, 1)
                }
            }
        }
    }
    
    func loadThumbnailForURL(URL: NSURL) -> UIImage {
        /*
            We load the existing thumbnail (or a placeholder image if none has been
            loaded yet) and check if it is clean or not. If it isn't clean, we 
            load the thumbnail on a background queue to avoid blocking the main
            thread which could hamper scroll performance. Regardless of whether or
            not the thumbnail is clean, return the most up-to-date version of the
            thumbnail so we are sure to display something relatively up-to-date in 
            the UI.
        */
        
        /*
            We cache everything in our thumbnail cache by document identifier which
            is tracked properly accross renames.
        */
        guard let documentIdentifier = documentIdentifierForURL(URL) else {
            print("Failed to load docID and will display placeholder image for \(URL)")
            
            return UIImage(named: "MissingThumbnail.png")!
        }
        
        let existingImage = cache.objectForKey(documentIdentifier) as? UIImage
        
        if let existingImage = existingImage where cleanThumbnailDocumentIDs.contains(documentIdentifier) {
            // Everything fully up-to-date - return the cached image.
            return existingImage
        }

        // Use a placeholder image if one hasn't been loaded yet.
        let loadedThumbnail = existingImage ?? UIImage(named: "MissingThumbnail.png")!

        // If we are already loading that thumbnail, add our url to the reload list.
        if let URLs = pendingThumbnails[documentIdentifier] {
            pendingThumbnails[documentIdentifier] = URLs.union([URL])

            return loadedThumbnail
        }
        
        // Schedule the thumbnail to be loaded on a background queue.
        pendingThumbnails[documentIdentifier] = [URL]
        
        unscheduledDocumentIDs += [documentIdentifier]
        
        // Trigger the event handler for the `scheduleSource` scheduling thumbnail loading.
        dispatch_source_merge_data(scheduleSource, 1)
        
        // Return the most up-to-date image we have currently.
        return loadedThumbnail
    }
    
    private func loadThumbnailFromDiskForURL(URL: NSURL) -> UIImage? {
        do {
            /*
                Load the thumbnail from disk.  Use getPromisedItemResourceValue because
                the document might not have been downloaded yet.
            */
            var thumbnailDictionary: AnyObject?
            try URL.getPromisedItemResourceValue(&thumbnailDictionary, forKey: NSURLThumbnailDictionaryKey)

            /*
                We don't want to hang onto this in the URL cache because the URL 
                is long running and we maintain a separate cache for the thumbnails.
            */
            URL.removeCachedResourceValueForKey(NSURLThumbnailDictionaryKey)
            
            guard let dictionary = thumbnailDictionary as? [String: UIImage],
                image = dictionary[NSThumbnail1024x1024SizeKey] else {
                    throw ShapeEditError.ThumbnailLoadFailed
            }
            
            return image
        }
        catch {
            return nil
        }
    }
}

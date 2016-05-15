/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the Browser Query which manages results form an `NSMetadataQuery` to compute which documents to show in the Browser UI / animations to display when cells move.
*/

import UIKit

/**
    The delegate protocol implemented by the object that receives our results. We
    pass the updated list of results as well as a set of animations.
*/
protocol DocumentBrowserQueryDelegate: class {
    func documentBrowserQueryResultsDidChangeWithResults(results: [DocumentBrowserModelObject], animations: [DocumentBrowserAnimation])
}

/**
    The DocumentBrowserQuery wraps an `NSMetadataQuery` to insulate us from the
    queueing and animation concerns. It runs the query and computes animations
    from the results set.
*/
class DocumentBrowserQuery: NSObject {
    // MARK: Properties

    private var metadataQuery: NSMetadataQuery
    
    private var previousQueryObjects: NSOrderedSet?
    
    private let workerQueue: NSOperationQueue = {
        let workerQueue = NSOperationQueue()
        
        workerQueue.name = "com.example.apple-samplecode.ShapeEdit.browserdatasource.workerQueue"

        workerQueue.maxConcurrentOperationCount = 1
        
        return workerQueue
    }()

    var delegate: DocumentBrowserQueryDelegate? {
        didSet {
            /*
                If we already have results, we send them to the delegate as an
                initial update.
            */
            workerQueue.addOperationWithBlock {
                guard let results = self.previousQueryObjects else { return }
                
                self.updateWithResults(results, removedResults: NSOrderedSet(), addedResults: NSOrderedSet(), changedResults: NSOrderedSet())
            }
        }
    }

    // MARK: Initialization

    override init() {
        metadataQuery = NSMetadataQuery()

        /*
            Ask for both in-container documents and external documents so that
            the user gets to interact with all the documents she or he has ever
            opened in the application, without having to pull the document picker
            again and again.
        */
        metadataQuery.searchScopes = [
            NSMetadataQueryUbiquitousDocumentsScope,
            NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope
        ]

        /*
            We supply our own serializing queue to the `NSMetadataQuery` so that we
            can perform our own background work in sync with item discovery.
            Note that the operationQueue of the `NSMetadataQuery` must be serial.
        */
        metadataQuery.operationQueue = workerQueue

        super.init()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DocumentBrowserQuery.finishGathering(_:)), name: NSMetadataQueryDidFinishGatheringNotification, object: metadataQuery)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DocumentBrowserQuery.queryUpdated(_:)), name: NSMetadataQueryDidUpdateNotification, object: metadataQuery)

        metadataQuery.startQuery()
    }
    
    // MARK: - Notifications

    @objc func queryUpdated(notification: NSNotification) {
        let changedMetadataItems = notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem]
        
        let removedMetadataItems = notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem]
        
        let addedMetadataItems = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem]
        
        let changedResults = buildModelObjectSet(changedMetadataItems ?? [])
        let removedResults = buildModelObjectSet(removedMetadataItems ?? [])
        let addedResults = buildModelObjectSet(addedMetadataItems ?? [])
        
        let newResults = buildQueryResultSet()

        updateWithResults(newResults, removedResults: removedResults, addedResults: addedResults, changedResults: changedResults)
    }

    @objc func finishGathering(notification: NSNotification) {
        metadataQuery.disableUpdates()
        
        let metadataQueryResults = metadataQuery.results as! [NSMetadataItem]
        
        let results = buildModelObjectSet(metadataQueryResults)
                
        metadataQuery.enableUpdates()

        updateWithResults(results, removedResults: NSOrderedSet(), addedResults: NSOrderedSet(), changedResults: NSOrderedSet())
    }

    // MARK: - Result handling/animations

    private func buildModelObjectSet(objects: [NSMetadataItem]) -> NSOrderedSet {
        // Create an ordered set of model objects.
        var array = objects.map { DocumentBrowserModelObject(item: $0) }

        // Sort the array by filename.
        array.sortInPlace { $0.displayName < $1.displayName }

        let results = NSMutableOrderedSet(array: array)

        return results
    }
    
    private func buildQueryResultSet() -> NSOrderedSet {
        /*
           Create an ordered set of model objects from the query's current
           result set.
        */

        metadataQuery.disableUpdates()

        let metadataQueryResults = metadataQuery.results as! [NSMetadataItem]

        let results = buildModelObjectSet(metadataQueryResults)

        metadataQuery.enableUpdates()

        return results
    }

    private func computeAnimationsForNewResults(newResults: NSOrderedSet, oldResults: NSOrderedSet, removedResults: NSOrderedSet, addedResults: NSOrderedSet, changedResults: NSOrderedSet) -> [DocumentBrowserAnimation] {
        /*
           From two sets of result objects, create an array of animations that
           should be run to morph old into new results.
        */
        
        let oldResultAnimations: [DocumentBrowserAnimation] = removedResults.array.flatMap { removedResult in
            let oldIndex = oldResults.indexOfObject(removedResult)
            
            guard oldIndex != NSNotFound else { return nil }
            
            return .Delete(index: oldIndex)
        }
        
        let newResultAnimations: [DocumentBrowserAnimation] = addedResults.array.flatMap { addedResult in
            let newIndex = newResults.indexOfObject(addedResult)
            
            guard newIndex != NSNotFound else { return nil }
            
            return .Add(index: newIndex)
        }

        let movedResultAnimations: [DocumentBrowserAnimation] = changedResults.array.flatMap { movedResult in
            let newIndex = newResults.indexOfObject(movedResult)
            let oldIndex = oldResults.indexOfObject(movedResult)
            
            guard newIndex != NSNotFound else { return nil }
            guard oldIndex != NSNotFound else { return nil }
            guard oldIndex != newIndex   else { return nil }
            
            return .Move(fromIndex: oldIndex, toIndex: newIndex)
        }

        // Find all the changed result animations.
        let changedResultAnimations: [DocumentBrowserAnimation] = changedResults.array.flatMap { changedResult in
            let index = newResults.indexOfObject(changedResult)

            guard index != NSNotFound else { return nil }
            
            return .Update(index: index)
        }
        
        return oldResultAnimations + changedResultAnimations + newResultAnimations + movedResultAnimations
    }

    private func updateWithResults(results: NSOrderedSet, removedResults: NSOrderedSet, addedResults: NSOrderedSet, changedResults: NSOrderedSet) {
        /*
            From a set of new result objects, we compute the necessary animations
            if applicable, then call out to our delegate.
        */

        /*
            We use the `NSOrderedSet` as a fast lookup for computing the animations,
            but use a simple array otherwise for convenience.
        */
        let queryResults = results.array as! [DocumentBrowserModelObject]

        let queryAnimations: [DocumentBrowserAnimation]

        if let oldResults = previousQueryObjects {
            queryAnimations = computeAnimationsForNewResults(results, oldResults: oldResults, removedResults: removedResults, addedResults: addedResults, changedResults: changedResults)
        }
        else {
            queryAnimations = [.Reload]
        }

        // After computing updates, we hang on to the current results for the next round.
        previousQueryObjects = results

        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.delegate?.documentBrowserQueryResultsDidChangeWithResults(queryResults, animations: queryAnimations)
        }
    }
}

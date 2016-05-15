/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the Recents Manager and handles saving the recents list as it changes as well as notifies the delegate when recents are deleted / modified in a way that requires the UI to be refreshed.
*/

import Foundation

/**
    The delegate protocol implemented by the object that receives our results.
    We pass the updated list of results as well as a set of animations.
*/
protocol RecentModelObjectsManagerDelegate: class {
    func recentsManagerResultsDidChange(results: [RecentModelObject], animations: [DocumentBrowserAnimation])
}

/**
    The `RecentModelObjectsManager` manages our list of recents.  It receives
    notifications from the recents as a RecentModelObjectDelegate and computes
    animations from the notifications which is submits to it's delegate.
*/
class RecentModelObjectsManager: RecentModelObjectDelegate {
    // MARK: Properties
    
    var recentModelObjects = [RecentModelObject]()
    
    static let maxRecentModelObjectCount = 3
    
    static let recentsKey = "recents"
    
    private let workerQueue: NSOperationQueue = {
        let coordinationQueue = NSOperationQueue()
        
        coordinationQueue.name = "com.example.apple-samplecode.ShapeEdit.recentobjectsmanager.workerQueue"
        
        coordinationQueue.maxConcurrentOperationCount = 1
        
        return coordinationQueue
    }()

    
    weak var delegate: RecentModelObjectsManagerDelegate? {
        didSet {
            /*
                If we already have results, we send them to the delegate as an
                initial update.
            */
            delegate?.recentsManagerResultsDidChange(recentModelObjects, animations: [.Reload])
        }
    }
    
    // MARK: Initialization
    
    init() {
        loadRecents()
    }
    
    deinit {
        // Be sure we are no longer listening for file presenter notifications.
        for recent in recentModelObjects {
            NSFileCoordinator.removeFilePresenter(recent)
        }
    }
    
    // MARK: Recent Saving / Loading
    
    private func loadRecents() {
        workerQueue.addOperationWithBlock {
            let defaults = NSUserDefaults.standardUserDefaults()
            
            guard let loadedRecentData = defaults.objectForKey(RecentModelObjectsManager.recentsKey) as? [NSData] else {
                return
            }
            
            let loadedRecents = loadedRecentData.flatMap { recentModelObjectData in
                return NSKeyedUnarchiver.unarchiveObjectWithData(recentModelObjectData) as? RecentModelObject
            }
            
            // Remove any existing recents we may have already stored in memory.
            for recent in self.recentModelObjects {
                NSFileCoordinator.removeFilePresenter(recent)
            }
            
            /* 
                Add all newly loaded recents to the recents set and register for
                `NSFilePresenter` notifications on all of them.
            */
            for recent in loadedRecents {
                recent.delegate = self
                NSFileCoordinator.addFilePresenter(recent)
            }
            
            self.recentModelObjects = loadedRecents
            
            // Check if the bookmark data is stale and resave the recents if it is.
            for recent in loadedRecents {
                if recent.bookmarkDataNeedsSave {
                    self.saveRecents()
                }
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                // Notify our delegate that the initial recents were loaded.
                self.delegate?.recentsManagerResultsDidChange(self.recentModelObjects, animations: [.Reload])
            }
        }
    }
    
    private func saveRecents() {
        let recentModels = recentModelObjects.map { recentModelObject in
            return NSKeyedArchiver.archivedDataWithRootObject(recentModelObject)
        }
        
        NSUserDefaults.standardUserDefaults().setObject(recentModels, forKey: RecentModelObjectsManager.recentsKey)
    }
    
    // MARK: Recent List Management
    
    private func removeRecentModelObject(recent: RecentModelObject) {
        // Remove the file presenter so we stop getting notifications on the removed recent.
        NSFileCoordinator.removeFilePresenter(recent)
        
        /*
            Remove the recent from the array and save the recents array to disk
            so they will reflect the correct state when the app is relaunched.
        */
        guard let index = recentModelObjects.indexOf(recent) else { return }

        recentModelObjects.removeAtIndex(index)

        saveRecents()
    }
    
    func addURLToRecents(URL: NSURL) {
        workerQueue.addOperationWithBlock {
            // Add the recent to the recents manager.
            guard let recent = RecentModelObject(URL: URL) else { return }

            var animations = [DocumentBrowserAnimation]()
            
            if let index = self.recentModelObjects.indexOf(recent) {
                self.recentModelObjects.removeAtIndex(index)
                
                if index != 0 {
                    animations += [.Move(fromIndex: index, toIndex: 0)]
                }
            }
            else {
                recent.delegate = self
                
                NSFileCoordinator.addFilePresenter(recent)
                
                animations += [.Add(index: 0)]
            }
            
            self.recentModelObjects.insert(recent, atIndex: 0)
            
            // Prune down the recent documents if there are too many.
            while self.recentModelObjects.count > RecentModelObjectsManager.maxRecentModelObjectCount {
                self.removeRecentModelObject(self.recentModelObjects.last!)
                
                animations += [.Delete(index: self.recentModelObjects.count - 1)]
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.delegate?.recentsManagerResultsDidChange(self.recentModelObjects, animations: animations)
            }
        
            self.saveRecents()
        }
    }
    
    // MARK: RecentModelObjectDelegate
    
    func recentWasDeleted(recent: RecentModelObject) {
        self.workerQueue.addOperationWithBlock {
            guard let index = self.recentModelObjects.indexOf(recent) else { return }
            
            self.removeRecentModelObject(recent)
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.delegate?.recentsManagerResultsDidChange(self.recentModelObjects, animations: [
                    .Delete(index: index)
                ])
            }
        }
    }
    
    func recentNeedsReload(recent: RecentModelObject) {
        self.workerQueue.addOperationWithBlock {
            guard let index = self.recentModelObjects.indexOf(recent) else { return }
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.delegate?.recentsManagerResultsDidChange(self.recentModelObjects, animations: [
                    .Update(index: index)
                ])
            }
        }
    }
}

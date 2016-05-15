/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ConnectivityListsController` and `ConnectivityListsControllerDelegate` infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to `ListInfo` objects.
*/

import Foundation
import WatchConnectivity
import ListerWatchKit

/**
    The `ConnectivityListsControllerDelegate` protocol enables an `ConnectivityListsController`
    object to notify other objects of changes to available `ListInfo` objects. This includes
    "will change content" events, "did change content" events, inserts, removes, updates, and errors. Note
    that the `ListsController` can call these methods on an aribitrary queue. If the implementation in
    these methods require UI manipulations, you should respond to the changes on the main queue.
*/
@objc public protocol ConnectivityListsControllerDelegate {
    /**
        Notifies the receiver of this method that the lists controller will change it's contents in some
        form. This method is *always* called before any insert, remove, or update is received. In this method,
        you should prepare your UI for making any changes related to the changes that you will need to reflect
        once they are received. Once all of the updates are performed, your `-listsControllerDidChangeContent:`
        method will be called.
        
        - parameter listsController:The `ConnectivityListsController` instance that will change its content.
    */
    optional func listsControllerWillChangeContent(listsController: ConnectivityListsController)
    
    /**
        Notifies the receiver of this method that the lists controller is tracking a new `ListInfo`
        object. Receivers of this method should update their UI accordingly.
        
        - parameter listsController: The `ConnectivityListsController` instance that inserted the new `ListInfo`.
        - parameter listInfo:The new `ListInfo` object that has been inserted at `index`.
        - parameter index:The index that `listInfo` was inserted at.
    */
    optional func listsController(listsController: ConnectivityListsController, didInsertListInfo listInfo: ListInfo, atIndex index: Int)
    
    /**
        Notifies the receiver of this method that the lists controller is no longer tracking `listInfo`.
        Receivers of this method should update their UI accordingly.
        
        - parameter listsController:The `ConnectivityListsController` instance that removed `listInfo`.
        - parameter listInfo:The removed `ListInfo` object.
        - parameter index:The index that `listInfo` was removed at.
    */
    optional func listsController(listsController: ConnectivityListsController, didRemoveListInfo listInfo: ListInfo, atIndex index: Int)
    
    /**
        Notifies the receiver of this method that the lists controller received a message that `listInfo`
        has updated its content. Receivers of this method should update their UI accordingly.
        
        - parameter listsController:The `ConnectivityListsController` instance that was notified that `listInfo` has
        been updated.
        - parameter listInfo:The `ListInfo` object that has been updated.
        - parameter index:The index of `listInfo,` the updated `ListInfo`.
    */
    optional func listsController(listsController: ConnectivityListsController, didUpdateListInfo listInfo: ListInfo, atIndex index: Int)
    
    /**
        Notifies the receiver of this method that the lists controller did change it's contents in some form.
        This method is *always* called after any insert, remove, or update is received. In this method, you
        should finish off changes to your UI that were related to any insert, remove, or update.
        
        - parameter listsController:The `ConnectivityListsController` instance that did change its content.
    */
    optional func listsControllerDidChangeContent(listsController: ConnectivityListsController)
}

/**
    The `ConnectivityListsController` class is responsible for tracking `ListInfo` objects that are
    found through lists controller's `WCSession` object. `WCSession` is responsible for informing watchOS
    applications of changes occurring in their counterpart application. It also allows the rest of the
    application to deal with `ListInfo` objects rather than the various types that `WCSession` may directly
    vend instances of. In essence, the work of a lists controller is to "front" the device's default WCSession.
*/
public class ConnectivityListsController: NSObject, WCSessionDelegate {
    // MARK: Properties
    
    /**
        The `ConnectivityListsController` object's delegate who is responsible for responding to `ListsController`
        changes.
    */
    public weak var delegate: ConnectivityListsControllerDelegate?
    
    /**
        - returns: The number of tracked `ListInfo` objects.
    */
    public var count: Int {
        var listInfosCount: Int!
        
        dispatch_sync(listInfoQueue) {
            listInfosCount = self.listInfos.count
        }
        
        return listInfosCount
    }
    
    private var listInfos = [ListInfo]()
    
    private let listInfoQueue = dispatch_queue_create("com.example.apple-samplecode.lister.listscontroller", DISPATCH_QUEUE_SERIAL)
    
    private let predicate: ((ListInfo) -> Bool)?
    
    // MARK: Initializers
    
    /**
        Initializes an `ConnectivityListsController` instance and configures it to interact with the default
        `WCSession`.
    */
    override public init() {
        predicate = nil
        
        super.init()
    }
    
    /**
        Initializes an `ConnectivityListsController` instance and configures it to interact with the default
        `WCSession.` The list name is used to focus the controller on changes to a single list.
        
        - parameter listName:A `NSString` matching the name of the single list to be monitored.
    */
    public init(listName: String) {
        predicate = { return $0.name == listName }
        
        super.init()
    }
    
    /**
        Begin listening for changes to the tracked `ListInfo` objects. Be sure to balance each call to
        `-startSearching` with a call to `-stopSearching`.
    */
    public func startSearching() {
        if WCSession.isSupported() {
            WCSession.defaultSession().delegate = self
            WCSession.defaultSession().activateSession()
        }
    }
    
    /**
        Stop listening for changes to the tracked `ListInfo` objects. Each call to `-startSearching` should
        be balanced with a call to this method.
    */
    public func stopSearching() {
        delegate = nil
    }
    
    // MARK: Subscripts
    
    /**
        - returns: The `ListInfo` instance at a specific index. This method traps if the index is out
        of bounds.
    */
    public subscript(idx: Int) -> ListInfo {
        // Fetch the appropriate list info protected by `listInfoQueue`.
        var listInfo: ListInfo!
        
        dispatch_sync(listInfoQueue) {
            listInfo = self.listInfos[idx]
        }
        
        return listInfo
    }
    
    // MARK: WCSessionDelegate
    
    public func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
        
        // Do not proceed if `session` is not currently `.Activated`.
        guard session.activationState == .Activated else { return }
        
        if !session.receivedApplicationContext.isEmpty {
            processApplicationContext(WCSession.defaultSession().receivedApplicationContext)
        }
    }
    
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String: AnyObject]) {
        processApplicationContext(applicationContext)
    }
    
    private func processApplicationContext(applicationContext: [String: AnyObject]) {
        let lists: [[String: AnyObject]] = applicationContext[AppConfiguration.ApplicationActivityContext.currentListsKey] as! [[String: AnyObject]]
        
        var changedListInfos = lists.map {
            return ListInfo(name: $0[AppConfiguration.ApplicationActivityContext.listNameKey] as! String, color: List.Color(rawValue: $0[AppConfiguration.ApplicationActivityContext.listColorKey] as! Int)!)
        }
        
        if predicate != nil {
            changedListInfos = changedListInfos.filter(predicate!)
        }
        
        delegate?.listsControllerWillChangeContent?(self)
        
        let removed = removedListInfosToChangedListInfos(changedListInfos)
        let inserted = insertedListInfosToChangedListInfos(changedListInfos)
        let updated = updatedListInfosToChangedListInfos(changedListInfos)
        
        for listInfoToRemove in removed {
            let indexOfListInfoToRemove = listInfos.indexOf(listInfoToRemove)!
            
            listInfos.removeAtIndex(indexOfListInfoToRemove)
            delegate?.listsController?(self, didRemoveListInfo: listInfoToRemove, atIndex: indexOfListInfoToRemove)
        }
        
        for (indexOfListInfoToInsert, listInfoToInsert) in inserted.enumerate() {
            listInfos.insert(listInfoToInsert, atIndex: indexOfListInfoToInsert)
            
            delegate?.listsController?(self, didInsertListInfo: listInfoToInsert, atIndex: indexOfListInfoToInsert)
        }
        
        for listInfoToUpdate in updated {
            let indexOfListInfoToUpdate = listInfos.indexOf(listInfoToUpdate)!
            
            listInfos[indexOfListInfoToUpdate] = listInfoToUpdate
            delegate?.listsController?(self, didUpdateListInfo: listInfoToUpdate, atIndex: indexOfListInfoToUpdate)
        }
        
        delegate?.listsControllerDidChangeContent?(self)
    }
    
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        copyURLToDocumentsDirectory(file.fileURL)
    }
    
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        if error != nil {
            print("\(#function), file: \(fileTransfer.file.fileURL), error: \(error!.localizedDescription)")
        }
    }
    
    // MARK: Convenience
    
    private func copyURLToDocumentsDirectory(URL: NSURL) {
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let toURL = documentsURL.URLByAppendingPathComponent(URL.lastPathComponent!)
        
        ListUtilities.copyFromURL(URL, toURL: toURL)
    }
    
    // MARK: List Differencing
    
    private func removedListInfosToChangedListInfos(changedListInfos: [ListInfo]) -> [ListInfo] {
        return listInfos.filter { !changedListInfos.contains($0) }
    }
    
    private func insertedListInfosToChangedListInfos(changedListInfos: [ListInfo]) -> [ListInfo] {
        return changedListInfos.filter { !self.listInfos.contains($0) }
    }
    
    private func updatedListInfosToChangedListInfos(changedListInfos: [ListInfo]) -> [ListInfo] {
        return changedListInfos.filter { changedListInfo in
            if let indexOfChangedListInfoInInitialListInfo = self.listInfos.indexOf(changedListInfo) {
                let initialListInfo = self.listInfos[indexOfChangedListInfoInInitialListInfo]
                
                if initialListInfo.color != changedListInfo.color {
                    return true
                }
            }
            
            return false
        }
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListsController` and `ListsControllerDelegate` infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to `ListInfo` objects. In addition, it also provides a way for parts of the application to present errors that occured when creating or removing lists.
*/

import Foundation

/**
    The `ListsControllerDelegate` protocol enables a `ListsController` object to notify other objects of changes
    to available `ListInfo` objects. This includes "will change content" events, "did change content"
    events, inserts, removes, updates, and errors. Note that the `ListsController` can call these methods
    on an aribitrary queue. If the implementation in these methods require UI manipulations, you should
    respond to the changes on the main queue.
*/
@objc public protocol ListsControllerDelegate {
    /**
        Notifies the receiver of this method that the lists controller will change it's contents in
        some form. This method is *always* called before any insert, remove, or update is received.
        In this method, you should prepare your UI for making any changes related to the changes
        that you will need to reflect once they are received. For example, if you have a table view
        in your UI that needs to respond to changes to a newly inserted `ListInfo` object, you would
        want to call your table view's `beginUpdates()` method. Once all of the updates are performed,
        your `listsControllerDidChangeContent(_:)` method will be called. This is where you would to call
        your table view's `endUpdates()` method.
    
        - parameter listsController: The `ListsController` instance that will change its content.
    */
    optional func listsControllerWillChangeContent(listsController: ListsController)

    /**
        Notifies the receiver of this method that the lists controller is tracking a new `ListInfo`
        object. Receivers of this method should update their UI accordingly.
        
        - parameter listsController: The `ListsController` instance that inserted the new `ListInfo`.
        - parameter listInfo: The new `ListInfo` object that has been inserted at `index`.
        - parameter index: The index that `listInfo` was inserted at.
    */
    optional func listsController(listsController: ListsController, didInsertListInfo listInfo: ListInfo, atIndex index: Int)

    /**
        Notifies the receiver of this method that the lists controller received a message that `listInfo`
        has updated its content. Receivers of this method should update their UI accordingly.
        
        - parameter listsController: The `ListsController` instance that was notified that `listInfo` has been updated.
        - parameter listInfo: The `ListInfo` object that has been updated.
        - parameter index: The index of `listInfo`, the updated `ListInfo`.
    */
    optional func listsController(listsController: ListsController, didRemoveListInfo listInfo: ListInfo, atIndex index: Int)

    /**
        Notifies the receiver of this method that the lists controller is no longer tracking `listInfo`.
        Receivers of this method should update their UI accordingly.
        
        - parameter listsController: The `ListsController` instance that removed `listInfo`.
        - parameter listInfo: The removed `ListInfo` object.
        - parameter index: The index that `listInfo` was removed at.
    */
    optional func listsController(listsController: ListsController, didUpdateListInfo listInfo: ListInfo, atIndex index: Int)

    /**
        Notifies the receiver of this method that the lists controller did change it's contents in
        some form. This method is *always* called after any insert, remove, or update is received.
        In this method, you should finish off changes to your UI that were related to any insert, remove,
        or update. For an example of how you might handle a "did change" contents call, see
        the discussion for `listsControllerWillChangeContent(_:)`.

        - parameter listsController: The `ListsController` instance that did change its content.
    */
    optional func listsControllerDidChangeContent(listsController: ListsController)

    /**
        Notifies the receiver of this method that an error occured when creating a new `ListInfo` object.
        In implementing this method, you should present the error to the user. Do not rely on the
        `ListInfo` instance to be valid since an error occured in creating the object.

        - parameter listsController: The `ListsController` that is notifying that a failure occured.
        - parameter listInfo: The `ListInfo` that represents the list that couldn't be created.
        - parameter error: The error that occured.
    */
    optional func listsController(listsController: ListsController, didFailCreatingListInfo listInfo: ListInfo, withError error: NSError)

    /**
        Notifies the receiver of this method that an error occured when removing an existing `ListInfo`
        object. In implementing this method, you should present the error to the user.

        - parameter listsController: The `ListsController` that is notifying that a failure occured.
        - parameter listInfo: The `ListInfo` that represents the list that couldn't be removed.
        - parameter error: The error that occured.
    */
    optional func listsController(listsController: ListsController, didFailRemovingListInfo listInfo: ListInfo, withError error: NSError)
}

/**
    The `ListsController` class is responsible for tracking `ListInfo` objects that are found through
    lists controller's `ListCoordinator` object. `ListCoordinator` objects are responsible for notifying
    the lists controller of inserts, removes, updates, and errors when interacting with a list's URL.
    Since the work of searching, removing, inserting, and updating `ListInfo` objects is done by the list
    controller's coordinator, the lists controller serves as a way to avoid the need to interact with a single
    `ListCoordinator` directly throughout the application. It also allows the rest of the application
    to deal with `ListInfo` objects rather than dealing with their `NSURL` instances directly. In essence,
    the work of a lists controller is to "front" its current coordinator. All changes that the coordinator
    relays to the `ListsController` object will be relayed to the lists controller's delegate. This ability to
    front another object is particularly useful when the underlying coordinator changes. As an example,
    this could happen when the user changes their storage option from using local documents to using
    cloud documents. If the coordinator property of the lists controller changes, other objects throughout
    the application are unaffected since the lists controller will notify them of the appropriate
    changes (removes, inserts, etc.).
*/
final public class ListsController: NSObject, ListCoordinatorDelegate {
    // MARK: Properties

    /// The `ListsController`'s delegate who is responsible for responding to `ListsController` updates.
    public weak var delegate: ListsControllerDelegate?
    
    /// - returns:  The number of tracked `ListInfo` objects.
    public var count: Int {
        var listInfosCount: Int!

        dispatch_sync(listInfoQueue) {
            listInfosCount = self.listInfos.count
        }

        return listInfosCount
    }

    /// The current `ListCoordinator` that the lists controller manages.
    public var listCoordinator: ListCoordinator {
        didSet(oldListCoordinator) {
            oldListCoordinator.stopQuery()
            
            // Map the listInfo objects protected by listInfoQueue.
            var allURLs: [NSURL]!
            dispatch_sync(listInfoQueue) {
                allURLs = self.listInfos.map { $0.URL }
            }
            self.processContentChanges(insertedURLs: [], removedURLs: allURLs, updatedURLs: [])
            
            self.listCoordinator.delegate = self
            oldListCoordinator.delegate = nil
            
            self.listCoordinator.startQuery()
        }
    }
    
    /// A URL for the directory containing documents within the application's container.
    public var documentsDirectory: NSURL {
        return listCoordinator.documentsDirectory
    }

    /**
        The `ListInfo` objects that are cached by the `ListsController` to allow for users of the
        `ListsController` class to easily subscript the controller.
    */
    private var listInfos = [ListInfo]()
    
    /**
        - returns: A private, local queue to the `ListsController` that is used to perform updates on
                 `listInfos`.
    */
    private let listInfoQueue = dispatch_queue_create("com.example.apple-samplecode.lister.listscontroller", DISPATCH_QUEUE_SERIAL)
    
    /**
        The sort predicate that's set in initialization. The sort predicate ensures a strict sort ordering
        of the `listInfos` array. If `sortPredicate` is nil, the sort order is ignored.
    */
    private let sortPredicate: ((lhs: ListInfo, rhs: ListInfo) -> Bool)?
    
    /// The queue on which the `ListsController` object invokes delegate messages.
    private var delegateQueue: NSOperationQueue

    // MARK: Initializers
    
    /**
        Initializes a `ListsController` instance with an initial `ListCoordinator` object and a sort
        predicate (if any). If no sort predicate is provided, the controller ignores sort order.

        - parameter listCoordinator: The `ListsController`'s initial `ListCoordinator`.
        - parameter delegateQueue: The queue on which the `ListsController` object invokes delegate messages.
        - parameter sortPredicate: The predicate that determines the strict sort ordering of the `listInfos` array.
    */
    public init(listCoordinator: ListCoordinator, delegateQueue: NSOperationQueue, sortPredicate: ((lhs: ListInfo, rhs: ListInfo) -> Bool)? = nil) {
        self.listCoordinator = listCoordinator
        self.delegateQueue = delegateQueue
        self.sortPredicate = sortPredicate

        super.init()

        self.listCoordinator.delegate = self
    }
    
    // MARK: Subscripts
    
    /**
        - returns:  The `ListInfo` instance at a specific index. This method traps if the index is out
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
    
    // MARK: Convenience
    
    /**
        Begin listening for changes to the tracked `ListInfo` objects. This is managed by the `listCoordinator`
        object. Be sure to balance each call to `startSearching()` with a call to `stopSearching()`.
     */
    public func startSearching() {
        listCoordinator.startQuery()
    }
    
    /**
        Stop listening for changes to the tracked `ListInfo` objects. This is managed by the `listCoordinator`
        object. Each call to `startSearching()` should be balanced with a call to this method.
     */
    public func stopSearching() {
        listCoordinator.stopQuery()
    }
    
    // MARK: Inserting / Removing / Managing / Updating `ListInfo` Objects
    
    /**
        Removes `listInfo` from the tracked `ListInfo` instances. This method forwards the remove
        operation directly to the list coordinator. The operation can be performed asynchronously
        so long as the underlying `ListCoordinator` instance sends the `ListsController` the correct
        delegate messages: either a `listCoordinatorDidUpdateContents(insertedURLs:removedURLs:updatedURLs:)`
        call with the removed `ListInfo` object, or with an error callback.
    
        - parameter listInfo: The `ListInfo` to remove from the list of tracked `ListInfo` instances.
    */
    public func removeListInfo(listInfo: ListInfo) {
        listCoordinator.removeListAtURL(listInfo.URL)
    }
    
    /**
        Attempts to create `ListInfo` representing `list` with the given name. If the method is succesful,
        the lists controller adds it to the list of tracked `ListInfo` instances. This method forwards
        the create operation directly to the list coordinator. The operation can be performed asynchronously
        so long as the underlying `ListCoordinator` instance sends the `ListsController` the correct
        delegate messages: either a `listCoordinatorDidUpdateContents(insertedURLs:removedURLs:updatedURLs:)`
        call with the newly inserted `ListInfo`, or with an error callback.

        Note: it's important that before calling this method, a call to `canCreateListWithName(_:)`
        is performed to make sure that the name is a valid list name. Doing so will decrease the errors
        that you see when you actually create a list.

        - parameter list: The `List` object that should be used to save the initial list.
        - parameter name: The name of the new list.
    */
    public func createListInfoForList(list: List, withName name: String) {
        listCoordinator.createURLForList(list, withName: name)
    }
    
    /**
        Determines whether or not a list can be created with a given name. This method delegates to
        `listCoordinator` to actually check to see if the list can be created with the given name. This
        method should be called before `createListInfoForList(_:withName:)` is called to ensure to minimize
        the number of errors that can occur when creating a list.

        - parameter name: The name to check to see if it's valid or not.
        
        - returns:  `true` if the list can be created with the given name, `false` otherwise.
    */
    public func canCreateListInfoWithName(name: String) -> Bool {
        return listCoordinator.canCreateListWithName(name)
    }
    
    /**
        Attempts to copy a `list` at a given `URL` to the appropriate location in the documents directory.
        This method forwards to `listCoordinator` to actually perform the document copy.
        
        - parameter URL: The `NSURL` object representing the list to be copied.
        - parameter name: The name of the `list` to be overwritten.
    */
    public func copyListFromURL(URL: NSURL, toListWithName name: String) {
        listCoordinator.copyListFromURL(URL, toListWithName: name)
    }
    
    /**
        Lets the `ListsController` know that `listInfo` has been udpdated. Once the change is reflected
        in `listInfos` array, a didUpdateListInfo message is sent.
        
        - parameter listInfo: The `ListInfo` instance that has new content.
    */
    public func setListInfoHasNewContents(listInfo: ListInfo) {
        dispatch_async(listInfoQueue) {
            // Remove the old list info and replace it with the new one.
            let indexOfListInfo = self.listInfos.indexOf(listInfo)!

            self.listInfos[indexOfListInfo] = listInfo

            if let delegate = self.delegate {
                self.delegateQueue.addOperationWithBlock {
                    delegate.listsControllerWillChangeContent?(self)
                    delegate.listsController?(self, didUpdateListInfo: listInfo, atIndex: indexOfListInfo)
                    delegate.listsControllerDidChangeContent?(self)
                }
            }
        }
    }

    // MARK: ListCoordinatorDelegate
    
    /**
        Receives changes from `listCoordinator` about inserted, removed, and/or updated `ListInfo`
        objects. When any of these changes occurs, these changes are processed and forwarded along
        to the `ListsController` object's delegate. This implementation determines where each of these
        URLs were located so that the controller can forward the new / removed / updated indexes
        as well. For more information about this method, see the method description for this method
        in the `ListCoordinator` class.

        - parameter insertedURLs: The `NSURL` instances that should be tracekd.
        - parameter removedURLs: The `NSURL` instances that should be untracked.
        - parameter updatedURLs: The `NSURL` instances that have had their underlying model updated.
    */
    public func listCoordinatorDidUpdateContents(insertedURLs insertedURLs: [NSURL], removedURLs: [NSURL], updatedURLs: [NSURL]) {
        processContentChanges(insertedURLs: insertedURLs, removedURLs: removedURLs, updatedURLs: updatedURLs)
    }
    
    /**
        Forwards the "create" error from the `ListCoordinator` to the `ListsControllerDelegate`. For more
        information about when this method can be called, see the description for this method in the
        `ListCoordinatorDelegate` protocol description.
        
        - parameter URL: The `NSURL` instances that was failed to be created.
        - parameter error: The error the describes why the create failed.
    */
    public func listCoordinatorDidFailCreatingListAtURL(URL: NSURL, withError error: NSError) {
        let listInfo = ListInfo(URL: URL)
        
        delegateQueue.addOperationWithBlock {
            self.delegate?.listsController?(self, didFailCreatingListInfo: listInfo, withError: error)
            
            return
        }
    }
    
    /**
        Forwards the "remove" error from the `ListCoordinator` to the `ListsControllerDelegate`. For
        more information about when this method can be called, see the description for this method in
        the `ListCoordinatorDelegate` protocol description.
        
        - parameter URL: The `NSURL` instance that failed to be removed
        - parameter error: The error that describes why the remove failed.
    */
    public func listCoordinatorDidFailRemovingListAtURL(URL: NSURL, withError error: NSError) {
        let listInfo = ListInfo(URL: URL)
        
        delegateQueue.addOperationWithBlock {
            self.delegate?.listsController?(self, didFailRemovingListInfo: listInfo, withError: error)
            
            return
        }
    }
    
    // MARK: Change Processing
    
    /**
        Processes changes to the `ListsController` object's `ListInfo` collection. This implementation
        performs the updates and determines where each of these URLs were located so that the controller can 
        forward the new / removed / updated indexes as well.
    
        - parameter insertedURLs: The `NSURL` instances that are newly tracked.
        - parameter removedURLs: The `NSURL` instances that have just been untracked.
        - parameter updatedURLs: The `NSURL` instances that have had their underlying model updated.
    */
    private func processContentChanges(insertedURLs insertedURLs: [NSURL], removedURLs: [NSURL], updatedURLs: [NSURL]) {
        let insertedListInfos = insertedURLs.map { ListInfo(URL: $0) }
        let removedListInfos = removedURLs.map { ListInfo(URL: $0) }
        let updatedListInfos = updatedURLs.map { ListInfo(URL: $0) }
        
        delegateQueue.addOperationWithBlock {
            // Filter out all lists that are already included in the tracked lists.
            var trackedRemovedListInfos: [ListInfo]!
            var untrackedInsertedListInfos: [ListInfo]!
            
            dispatch_sync(self.listInfoQueue) {
                trackedRemovedListInfos = removedListInfos.filter { self.listInfos.contains($0) }
                untrackedInsertedListInfos = insertedListInfos.filter { !self.listInfos.contains($0) }
            }
            
            if untrackedInsertedListInfos.isEmpty && trackedRemovedListInfos.isEmpty && updatedListInfos.isEmpty {
                return
            }
            
            self.delegate?.listsControllerWillChangeContent?(self)
            
            // Remove
            for trackedRemovedListInfo in trackedRemovedListInfos {
                var trackedRemovedListInfoIndex: Int!
                
                dispatch_sync(self.listInfoQueue) {
                    trackedRemovedListInfoIndex = self.listInfos.indexOf(trackedRemovedListInfo)!
                    
                    self.listInfos.removeAtIndex(trackedRemovedListInfoIndex)
                }
                
                self.delegate?.listsController?(self, didRemoveListInfo: trackedRemovedListInfo, atIndex: trackedRemovedListInfoIndex)
            }

            // Sort the untracked inserted list infos
            if let sortPredicate = self.sortPredicate {
                untrackedInsertedListInfos.sortInPlace(sortPredicate)
            }
            
            // Insert
            for untrackedInsertedListInfo in untrackedInsertedListInfos {
                var untrackedInsertedListInfoIndex: Int!
                
                dispatch_sync(self.listInfoQueue) {
                    self.listInfos += [untrackedInsertedListInfo]
                    
                    if let sortPredicate = self.sortPredicate {
                        self.listInfos.sortInPlace(sortPredicate)
                    }
                    
                    untrackedInsertedListInfoIndex = self.listInfos.indexOf(untrackedInsertedListInfo)!
                }
                
                self.delegate?.listsController?(self, didInsertListInfo: untrackedInsertedListInfo, atIndex: untrackedInsertedListInfoIndex)
            }
            
            // Update
            for updatedListInfo in updatedListInfos {
                var updatedListInfoIndex: Int?
                
                dispatch_sync(self.listInfoQueue) {
                    updatedListInfoIndex = self.listInfos.indexOf(updatedListInfo)
                    
                    // Track the new list info instead of the old one.
                    if let updatedListInfoIndex = updatedListInfoIndex {
                        self.listInfos[updatedListInfoIndex] = updatedListInfo
                    }
                }
                
                if let updatedListInfoIndex = updatedListInfoIndex {
                    self.delegate?.listsController?(self, didUpdateListInfo: updatedListInfo, atIndex: updatedListInfoIndex)
                }
            }
            
            self.delegate?.listsControllerDidChangeContent?(self)
        }
    }
}

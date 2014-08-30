/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `ListController` and `ListControllerDelegate` infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to `ListInfo` objects. In addition, it also provides a way for parts of the application to present errors that occured when creating or removing lists.
            
*/

import Foundation

/**
    The `ListControllerDelegate` protocol enables a `ListController` object to notify other objects of changes
    to available `ListInfo` objects. This includes "will change content" events, "did change content"
    events, inserts, removes, updates, and errors. Note that the `ListController` can call these methods
    on an aribitrary queue. If the implementation in these methods require UI manipulations, you should
    respond to the changes on the main queue.
*/
@objc public protocol ListControllerDelegate {
    /**
        Notifies the receiver of this method that the list controller will change it's contents in
        some form. This method is *always* called before any insert, remove, or update is received.
        In this method, you should prepare your UI for making any changes related to the changes
        that you will need to reflect once they are received. For example, if you have a table view
        in your UI that needs to respond to changes to a newly inserted `ListInfo` object, you would
        want to call your table view's `beginUpdates()` method. Once all of the updates are performed,
        your `listControllerDidChangeContent(_:)` method will be called. This is where you would to call
        your table view's `endUpdates()` method.
    
        :param: listController The `ListController` instance that will change its content.
    */
    func listControllerWillChangeContent(listController: ListController)

    /**
        Notifies the receiver of this method that the list controller is tracking a new `ListInfo`
        object. Receivers of this method should update their UI accordingly.
        
        :param: listController The `ListController` instance that inserted the new `ListInfo`.
        :param: listInfo The new `ListInfo` object that has been inserted at `index`.
        :param: index The index that `listInfo` was inserted at.
    */
    func listController(listController: ListController, didInsertListInfo listInfo: ListInfo, atIndex index: Int)

    /**
        Notifies the receiver of this method that the list controller received a message that `listInfo`
        has updated its content. Receivers of this method should update their UI accordingly.
        
        :param: listController The `ListController` instance that was notified that `listInfo` has been updated.
        :param: listInfo The `ListInfo` object that has been updated.
        :param: index The index of `listInfo`, the updated `ListInfo`.
    */
    func listController(listController: ListController, didRemoveListInfo listInfo: ListInfo, atIndex index: Int)

    /**
        Notifies the receiver of this method that the list controller is no longer tracking `listInfo`.
        Receivers of this method should update their UI accordingly.
        
        :param: listController The `ListController` instance that removed `listInfo`.
        :param: listInfo The removed `ListInfo` object.
        :param: index The index that `listInfo` was removed at.
    */
    func listController(listController: ListController, didUpdateListInfo listInfo: ListInfo, atIndex index: Int)

    /**
        Notifies the receiver of this method that the list controller did change it's contents in
        some form. This method is *always* called after any insert, remove, or update is received.
        In this method, you should finish off changes to your UI that were related to any insert, remove,
        or update. For an example of how you might handle a "did change" contents call, see
        the discussion for `listControllerWillChangeContent(_:)`.

        :param: listController The `ListController` instance that did change its content.
    */
    func listControllerDidChangeContent(listController: ListController)

    /**
        Notifies the receiver of this method that an error occured when creating a new `ListInfo` object.
        In implementing this method, you should present the error to the user. Do not rely on the
        `ListInfo` instance to be valid since an error occured in creating the object.

        :param: listController The `ListController` that is notifying that a failure occured.
        :param: listInfo The `ListInfo` that represents the list that couldn't be created.
        :param: error The error that occured.
    */
    func listController(listController: ListController, didFailCreatingListInfo listInfo: ListInfo, withError error: NSError)

    /**
        Notifies the receiver of this method that an error occured when removing an existing `ListInfo`
        object. In implementing this method, you should present the error to the user.

        :param: listController The `ListController` that is notifying that a failure occured.
        :param: listInfo The `ListInfo` that represents the list that couldn't be removed.
        :param: error The error that occured.
    */
    func listController(listController: ListController, didFailRemovingListInfo listInfo: ListInfo, withError error: NSError)
}

/**
    The `ListController` class is responsible for tracking `ListInfo` objects that are found through
    list controller's `ListCoordinator` object. `ListCoordinator` objects are responsible for notifying
    the list controller of inserts, removes, updates, and errors when interacting with a list's URL.
    Since the work of searching, removing, inserting, and updating `ListInfo` objects is done by the list
    controller's coordinator, the list controller serves as a way to avoid the need to interact with a single
    `ListCoordinator` directly throughout the application. It also allows the rest of the application
    to deal with `ListInfo` objects rather than dealing with their `NSURL` instances directly. In essence,
    the work of a list controller is to "front" its current coordinator. All changes that the coordinator
    relays to the `ListController` object will be relayed to the list controller's delegate. This ability to
    front another object is particularly useful when the underlying coordinator changes. As an example,
    this could happen when the user changes their storage option from using local documents to using
    cloud documents. If the coordinator property of the list controller changes, other objects throughout
    the application are unaffected since the list controller will notify them of the appropriate
    changes (removes, inserts, etc.).
*/
final public class ListController: NSObject, ListCoordinatorDelegate {
    // MARK: Properties

    /// The `ListController`'s delegate who is responsible for responding to `ListController` updates.
    public weak var delegate: ListControllerDelegate?
    
    /// :returns: The number of tracked `ListInfo` objects.
    public var count: Int {
        var listInfosCount: Int!

        dispatch_sync(listInfoQueue) {
            listInfosCount = self.listInfos.count
        }

        return listInfosCount
    }

    /// The current `ListCoordinator` that the list controller manages.
    public var listCoordinator: ListCoordinator {
        didSet(oldListCoordinator) {
            oldListCoordinator.stopQuery()
            
            // Map the listInfo objects protected by listInfoQueue.
            var allURLs: [NSURL]!
            dispatch_sync(self.listInfoQueue) {
                allURLs = self.listInfos.map { $0.URL }
            }
            self.processContentChanges(insertedURLs: [], removedURLs: allURLs, updatedURLs: [])
            
            self.listCoordinator.delegate = self
            oldListCoordinator.delegate = nil
            
            self.listCoordinator.startQuery()
        }
    }

    /**
        The `ListInfo` objects that are cached by the `ListController` to allow for users of the
        `ListController` class to easily subscript the controller.
    */
    private var listInfos = [ListInfo]()
    
    /**
        :returns: A private, local queue to the `ListController` that is used to perform updates on
                 `listInfos`.
    */
    private let listInfoQueue = dispatch_queue_create("com.example.apple-samplecode.lister.listcontroller", DISPATCH_QUEUE_SERIAL)
    
    /**
        The sort predicate that's set in initialization. The sort predicate ensures a strict sort ordering
        of the `listInfos` array. If `sortPredicate` is nil, the sort order is ignored.
    */
    private let sortPredicate: ((lhs: ListInfo, rhs: ListInfo) -> Bool)?

    // MARK: Initializers
    
    /**
        Initializes a `ListController` instance with an initial `ListCoordinator` object and a sort
        predicate (if any). If no sort predicate is provided, the controller ignores sort order.

        :param: listCoordinator The `ListController`'s initial `ListCoordinator`.
        :param: sortPredicate The predicate that determines the strict sort ordering of the `listInfos` array.
    */
    public init(listCoordinator: ListCoordinator, sortPredicate: ((lhs: ListInfo, rhs: ListInfo) -> Bool)? = nil) {
        self.listCoordinator = listCoordinator
        self.sortPredicate = sortPredicate

        super.init()

        self.listCoordinator.delegate = self
        self.listCoordinator.startQuery()
    }
    
    // MARK: Subscripts
    
    /**
        :returns: The `ListInfo` instance at a specific index. This method traps if the index is out
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
    
    
    // MARK: Inserting / Removing / Managing / Updating `ListInfo` Objects
    
    /**
        Removes `listInfo` from the tracked `ListInfo` instances. This method forwards the remove
        operation directly to the list coordinator. The operation can be performed asynchronously
        so long as the underlying `ListCoordinator` instance sends the `ListController` the correct
        delegate messages: either a `listCoordinatorDidUpdateContents(insertedURLs:removedURLs:updatedURLs:)`
        call with the removed `ListInfo` object, or with an error callback.
    
        :param: listInfo The `ListInfo` to remove from the list of tracked `ListInfo` instances.
    */
    public func removeListInfo(listInfo: ListInfo) {
        listCoordinator.removeListAtURL(listInfo.URL)
    }
    
    /**
        Attempts to create `ListInfo` representing `list` with the given name. If the method is succesful,
        the list controller adds it to the list of tracked `ListInfo` instances. This method forwards
        the create operation directly to the list coordinator. The operation can be performed asynchronously
        so long as the underlying `ListCoordinator` instance sends the `ListController` the correct
        delegate messages: either a `listCoordinatorDidUpdateContents(insertedURLs:removedURLs:updatedURLs:)`
        call with the newly inserted `ListInfo`, or with an error callback.

        Note: it's important that before calling this method, a call to `canCreateListWithName(_:)`
        is performed to make sure that the name is a valid list name. Doing so will decrease the errors
        that you see when you actually create a list.

        :param: list The `List` object that should be used to save the initial list.
        :param: name The name of the new list.
    */
    public func createListInfoForList(list: List, withName name: String) {
        listCoordinator.createURLForList(list, withName: name)
    }
    
    /**
        Determines whether or not a list can be created with a given name. This method delegates to
        `listCoordinator` to actually check to see if the list can be created with the given name. This
        method should be called before `createListInfoForList(_:withName:)` is called to ensure to minimize
        the number of errors that can occur when creating a list.

        :param: name The name to check to see if it's valid or not.
        
        :returns: `true` if the list can be created with the given name, `false` otherwise.
    */
    public func canCreateListInfoWithName(name: String) -> Bool {
        return listCoordinator.canCreateListWithName(name)
    }
    
    /**
        Lets the `ListController` know that `listInfo` has been udpdated. Once the change is reflected
        in `listInfos` array, a didUpdateListInfo message is sent.
        
        :param: listInfo The `ListInfo` instance that has new content.
    */
    public func setListInfoHasNewContents(listInfo: ListInfo) {
        dispatch_async(listInfoQueue) {
            // Remove the old list info and replace it with the new one.
            let indexOfListInfo = find(self.listInfos, listInfo)!
            self.listInfos[indexOfListInfo] = listInfo

            if let delegate = self.delegate {
                delegate.listControllerWillChangeContent(self)
                delegate.listController(self, didUpdateListInfo: listInfo, atIndex: indexOfListInfo)
                delegate.listControllerDidChangeContent(self)
            }
        }
    }

    // MARK: ListCoordinatorDelegate
    
    /**
        Receives changes from `listCoordinator` about inserted, removed, and/or updated `ListInfo`
        objects. When any of these changes occurs, these changes are processed and forwarded along
        to the `ListController` object's delegate. This implementation determines where each of these
        URLs were located so that the controller can forward the new / removed / updated indexes
        as well. For more information about this method, see the method description for this method
        in the `ListCoordinator` class.

        :param: insertedURLs The `NSURL` instances that should be tracekd.
        :param: removedURLs The `NSURL` instances that should be untracked.
        :param: updatedURLs The `NSURL` instances that have had their underlying model updated.
    */
    public func listCoordinatorDidUpdateContents(#insertedURLs: [NSURL], removedURLs: [NSURL], updatedURLs: [NSURL]) {
        processContentChanges(insertedURLs: insertedURLs, removedURLs: removedURLs, updatedURLs: updatedURLs)
    }
    
    /**
        Forwards the "create" error from the `ListCoordinator` to the `ListControllerDelegate`. For more
        information about when this method can be called, see the description for this method in the
        `ListCoordinatorDelegate` protocol description.
        
        :param: URL The `NSURL` instances that was failed to be created.
        :param: error The error the describes why the create failed.
    */
    public func listCoordinatorDidFailCreatingListAtURL(URL: NSURL, withError error: NSError) {
        let listInfo = ListInfo(URL: URL)
        
        delegate?.listController(self, didFailCreatingListInfo: listInfo, withError: error)
    }
    
    /**
        Forwards the "remove" error from the `ListCoordinator` to the `ListControllerDelegate`. For
        more information about when this method can be called, see the description for this method in
        the `ListCoordinatorDelegate` protocol description.
        
        :param: URL The `NSURL` instance that failed to be removed
        :param: error The error that describes why the remove failed.
    */
    public func listCoordinatorDidFailRemovingListAtURL(URL: NSURL, withError error: NSError) {
        let listInfo = ListInfo(URL: URL)
        
        delegate?.listController(self, didFailRemovingListInfo: listInfo, withError: error)
    }
    
    // MARK: Change Processing
    
    /**
        Processes inteneded changes to the `ListController` object's `ListInfo` collection. This implementation 
        performs the updates and determines where each of these URLs were located so that the controller can 
        forward the new / removed / updated indexes as well.
    
        :param: insertedURLs The `NSURL` instances that are newly tracked.
        :param: removedURLs The `NSURL` instances that have just been untracked.
        :param: updatedURLs The `NSURL` instances that have had their underlying model updated.
    */
    private func processContentChanges(#insertedURLs: [NSURL], removedURLs: [NSURL], updatedURLs: [NSURL]) {
        let insertedListInfos = insertedURLs.map { ListInfo(URL: $0) }
        let removedListInfos = removedURLs.map { ListInfo(URL: $0) }
        let updatedListInfos = updatedURLs.map { ListInfo(URL: $0) }

        dispatch_async(listInfoQueue) {
            // Filter out all lists that are already included in the tracked lists.
            let trackedRemovedListInfos = removedListInfos.filter { find(self.listInfos, $0) != nil }
            let untrackedInsertedListInfos = insertedListInfos.filter { find(self.listInfos, $0) == nil }
            
            if untrackedInsertedListInfos.isEmpty && trackedRemovedListInfos.isEmpty && updatedListInfos.isEmpty {
                return
            }
            
            self.delegate?.listControllerWillChangeContent(self)

            // Remove all of the removed lists.
            let removedIndices = trackedRemovedListInfos.map { find(self.listInfos, $0)! }
            for (idx, removedListInfo) in enumerate(trackedRemovedListInfos) {
                let currentListInfoIndex = find(self.listInfos, removedListInfo)!

                self.listInfos.removeAtIndex(currentListInfoIndex)
                
                let removedIndexBeforeModifyingListInfos = removedIndices[idx]
                
                self.delegate?.listController(self, didRemoveListInfo: removedListInfo, atIndex: removedIndexBeforeModifyingListInfos)
            }
            
            // Add the new lists.
            self.listInfos += untrackedInsertedListInfos
            
            // Now sort the list after all the inserts.
            if let sortPredicate = self.sortPredicate {
                self.listInfos.sort(sortPredicate)
            }
            
            for untrackedInsertedListInfo in untrackedInsertedListInfos {
                let insertedIndex = find(self.listInfos, untrackedInsertedListInfo)!
                self.delegate?.listController(self, didInsertListInfo: untrackedInsertedListInfo, atIndex: insertedIndex)
            }
            
            // Update the old lists.
            for updatedListInfo in updatedListInfos {
                if let updatedIndex = find(self.listInfos, updatedListInfo) {
                    self.listInfos[updatedIndex] = updatedListInfo
                    self.delegate?.listController(self, didUpdateListInfo: updatedListInfo, atIndex: updatedIndex)
                }
                else {
                    fatalError("One of the updated list infos wasn't actually in the tracked listInfos.")
                }
            }

            self.delegate?.listControllerDidChangeContent(self)
        }
    }
}

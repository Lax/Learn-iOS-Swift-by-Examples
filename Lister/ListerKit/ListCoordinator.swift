/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListCoordinator` and `ListCoordinatorDelegate` protocols provide the infrastructure to send updates to a `ListsController` object, abstracting away the need to worry about the underlying storage mechanism.
*/

import Foundation

/**
    An instance that conforms to the `ListCoordinator` protocol is responsible for implementing
    entry points in order to communicate with a `ListCoordinatorDelegate`. In the case of Lister, this
    is the `ListsController` instance. The main responsibility of a `ListCoordinator` is to track
    different `NSURL` instances that are important. For example, in Lister there are two types of
    storage mechanisms: local and iCloud based storage. The iCloud coordinator is responsible for making
    sure that the `ListsController` knows about the current set of iCloud documents that are available.
    
    There are also other responsibilities that a `ListCoordinator` must have that are specific to the
    underlying storage mechanism of the coordinator. A `ListCoordinator` determines whether or not a
    new list can be created with a specific name, it removes URLs tied to a specific list, and it is
    also responsible for listening for updates to any changes that occur at a specific URL (e.g. a
    list document is updated on another device, etc.).

    Instances of `ListCoordinator` can search for URLs in an asynchronous way. When a new `NSURL`
    instance is found, removed, or updated, the `ListCoordinator` instance must make its delegate aware
    of the updates. If a failure occured in removing or creating an `NSURL` for a given list, it must
    make its delegate aware by calling one of the appropriate error methods defined in the
    `ListCoordinatorDelegate` protocol.
*/
public protocol ListCoordinator: class {
    // MARK: Properties
    
    /**
        The delegate responsible for handling inserts, removes, updates, and errors when the
        `ListCoordinator` instance determines such events occured.
    */
    weak var delegate: ListCoordinatorDelegate? { get set }
    
    /// A URL for the directory containing documents within the application's container.
    var documentsDirectory: NSURL { get }
    
    // MARK: Methods
    
    /**
        Starts observing changes to the important `NSURL` instances. For example, if a `ListCoordinator`
        conforming class has the responsibility to manage iCloud documents, the `startQuery()` method
        would start observing an `NSMetadataQuery`. This method is called on the `ListCoordinator` once
        the coordinator is set on the `ListsController`.
    */
    func startQuery()
    
    /**
        Stops observing changes to the important `NSURL` instances. For example, if a `ListCoordinator`
        conforming class has the responsibility to manage iCloud documents, the stopQuery() method
        would stop observing changes to the `NSMetadataQuery`. This method is called on the `ListCoordinator`
        once a new `ListCoordinator` has been set on the `ListsController`.
    */
    func stopQuery()
    
    /**
        Removes `URL` from the list of tracked `NSURL` instances. For example, an iCloud-specific
        `ListCoordinator` would implement this method by deleting the underlying document that `URL`
        represents. When `URL` is removed, the coordinator object is responsible for informing the
        delegate by calling `listCoordinatorDidUpdateContents(insertedURLs:removedURLs:updatedURLs:)`
        with the removed `NSURL`. If a failure occurs when removing `URL`, the coordinator object is
        responsible for informing the delegate by calling the `listCoordinatorDidFailRemovingListAtURL(_:withError:)`
        method. The `ListsController` is the only object that should be calling this method directly.
        The "remove" is intended to be called on the `ListsController` instance with a `ListInfo` object
        whose URL would be forwarded down to the coordinator through this method.
    
        - parameter URL: The `NSURL` instance to remove from the list of important instances.
    */
    func removeListAtURL(URL: NSURL)

    /**
        Creates an `NSURL` object representing `list` with the provided name. Callers of this method
        (which should only be the `ListsController` object) should first check to see if a list can be
        created with the provided name via the `canCreateListWithName(_:)` method. If the creation was
        successful, then this method should call the delegate's update method that passes the newly
        tracked `NSURL` as an inserted URL. If the creation was not successful, this method should 
        inform the delegate of the failure by calling its `listCoordinatorDidFailCreatingListAtURL(_:withError:)`
        method. The "create" is intended to be called on the `ListsController` instance with a `ListInfo`
        object whose URL would be forwarded down to the coordinator through this method.
    
        - parameter list: The list to create a backing `NSURL` for.
        - parameter name: The new name for the list.
    */
    func createURLForList(list: List, withName name: String)
    
    /**
        Checks to see if a list can be created with a given name. As an example, if a `ListCoordinator`
        instance was responsible for storing its lists locally as a document, the coordinator would
        check to see if there are any other documents on the file system that have the same name. If
        they do, the method would return `false`. Otherwise, it would return `true`. This method should only
        be called by the `ListsController` instance. Normally you would call the users will call the
        `canCreateListWithName(_:)` method on `ListsController`, which will forward down to the current
        `ListCoordinator` instance.
    
        - parameter name: The name to use when checking to see if a list can be created.
    
        - returns:  `true` if the list can be created with the given name, `false` otherwise.
    */
    func canCreateListWithName(name: String) -> Bool
    
    /**
        Attempts to copy a `list` at a given `URL` to the appropriate location in the documents directory.
        
        - parameter URL: The `NSURL` object representing the list to be copied.
        - parameter name: The name of the `list` to be overwritten.
    */
    func copyListFromURL(URL: NSURL, toListWithName name: String)
}


/**
    The `ListCoordinatorDelegate` protocol exists to allow `ListCoordinator` instances to forward
    events. These events include a `ListCoordinator` removing, inserting, and updating their important,
    tracked `NSURL` instances. The `ListCoordinatorDelegate` also allows a `ListCoordinator` to notify
    its delegate of any errors that occured when removing or creating a list for a given URL.
*/
public protocol ListCoordinatorDelegate: class {
    /**
        Notifies the `ListCoordinatorDelegate` instance of any changes to the tracked URLs of the
        `ListCoordinator`. For more information about when this method should be called, see the
        description for the other `ListCoordinator` methods mentioned above that manipulate the tracked
        `NSURL` instances.
    
        - parameter insertedURLs: The `NSURL` instances that are newly tracked.
        - parameter removedURLs: The `NSURL` instances that have just been untracked.
        - parameter updatedURLs: The `NSURL` instances that have had their underlying model updated.
    */
     func listCoordinatorDidUpdateContents(insertedURLs insertedURLs: [NSURL], removedURLs: [NSURL], updatedURLs: [NSURL])
    
    /**
        Notifies a `ListCoordinatorDelegate` instance of an error that occured when a coordinator
        tried to remove a specific URL from the tracked `NSURL` instances. For more information about
        when this method should be called, see the description for the `removeListAtURL(_:)` method
        on `ListCoordinator`.
    
        - parameter URL: The `NSURL` instance that failed to be removed.
        - parameter error: The error that describes why the remove failed.
    */
    func listCoordinatorDidFailRemovingListAtURL(URL: NSURL, withError error: NSError)

    /**
        Notifies a `ListCoordinatorDelegate` instance of an error that occured when a coordinator
        tried to create a list at a given URL. For more information about when this method should be
        called, see the description for the `createURLForList(_:withName:)` method on `ListCoordinator`.
    
        - parameter URL: The `NSURL` instance that couldn't be created for a list.
        - parameter error: The error the describes why the create failed.
    */
    func listCoordinatorDidFailCreatingListAtURL(URL: NSURL, withError error: NSError)
}

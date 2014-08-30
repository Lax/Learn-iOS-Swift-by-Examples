/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLListCoordinator and \c AAPLListCoordinatorDelegate protocols provide the infrastructure to send updates to an \c AAPLListController object, abstracting away the need to worry about the underlying storage mechanism.
            
*/

@import Foundation;

@class AAPLList;
@protocol AAPLListCoordinatorDelegate;

/*!
 * An instance that conforms to the \c AAPLListCoordinator protocol is responsible for implementing
 * entry points in order to communicate with an \c AAPLListCoordinatorDelegate. In the case of Lister,
 * this is the \c AAPLListController instance. The main responsibility of a \c AAPLListCoordinator is
 * to track different \c NSURL instances that are important. For example, in Lister there are two types
 * of storage mechanisms: local and iCloud based storage. The iCloud coordinator is responsible for
 * making sure that the \c AAPLListController knows about the current set of iCloud documents that are
 * available.
 *
 * There are also other responsibilities that an \c AAPLListCoordinator must have that are specific
 * to the underlying storage mechanism of the coordinator. An \c AAPLListCoordinator determines whether
 * or not a new list can be created with a specific name, it removes URLs tied to a specific list, and
 * it is also responsible for listening for updates to any changes that occur at a specific URL 
 * (e.g. a list document is updated on another device, etc.).
 *
 * Instances of \c AAPLListCoordinator can search for URLs in an asynchronous way. When a new \c NSURL
 * instance is found, removed, or updated, the \c AAPLListCoordinator instance must make its delegate
 * aware of the updates. If a failure occured in removing or creating an \c NSURL for a given list,
 * it must make its delegate aware by calling one of the appropriate error methods defined in the
 * \c AAPLListCoordinatorDelegate protocol.
 */
@protocol AAPLListCoordinator <NSObject>

/*!
 * The delegate responsible for handling inserts, removes, updates, and errors when the \c AAPLListCoordinator
 * instance determines such events occured.
 */
@property (nonatomic, weak) id<AAPLListCoordinatorDelegate> delegate;

/*!
 * Starts observing changes to the important \c NSURL instances. For example, if an \c AAPLListCoordinator
 * conforming class has the responsibility to manage iCloud documents, the \c -startQuery method
 * would start observing an \c NSMetadataQuery. This method is called on the \c AAPLListCoordinator
 * once the coordinator is set on the \c AAPLListController.
 */
- (void)startQuery;

/*!
 * Stops observing changes to the important \c NSURL instances. For example, if a \c AAPLListCoordinator
 * conforming class has the responsibility to manage iCloud documents, the \c -stopQuery method
 * would stop observing changes to the \c NSMetadataQuery. This method is called on the \c AAPLListCoordinator
 * once a new \c AAPLListCoordinator has been set on the \c AAPLListController.
 */
- (void)stopQuery;

/**
 * Removes \c URL from the list of tracked \c NSURL instances. For example, an iCloud-specific
 * \c AAPLListCoordinator would implement this method by deleting the underlying document that \c URL
 * represents. When \c URL is removed, the coordinator object is responsible for informing the delegate
 * by calling \c -listCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs: with the
 * removed \c NSURL. If a failure occurs when removing \c URL, the coordinator object is responsible
 * for informing the delegate by calling the \c -listCoordinatorDidFailRemovingListAtURL:withError:
 * method. The \c AAPLListController is the only object that should be calling this method directly.
 * The "remove" is intended to be called on the \c AAPLListController instance with an \c AAPLListInfo
 * object whose URL would be forwarded down to the coordinator through this method.
 *
 * @param URL The \c NSURL instance to remove from the list of important instances.
 */
- (void)removeListAtURL:(NSURL *)URL;

/*!
 * Creates an \c NSURL object representing \c list with the provided name. Callers of this method
 * (which should only be the \c APPLListController object) should first check to see if a list can be
 * created with the provided name via the \c -canCreateListWithName: method. If the creation was
 * successful, then this method should call the delegate's update method that passes the newly tracked
 * \c NSURL as an inserted URL. If the creation was not successful, this method should inform the delegate
 * of the failure by calling its \c -listCoordinatorDidFailCreatingListAtURL:withError: method. The
 * "create" is intended to be called on the \c AAPLListController instance with an \c AAPLListInfo
 * object whose URL would be forwarded down to the coordinator through this method.
 *
 * @param list The list to create a backing \c NSURL for.
 * @param name The new name for the list.
 */
- (void)createURLForList:(AAPLList *)list withName:(NSString *)name;

/*!
 * Checks to see if a list can be created with a given name. As an example, if an \c AAPLListCoordinator
 * instance was responsible for storing its lists locally as a document, the coordinator would check
 * to see if there are any other documents on the file system that have the same name. If they do, the
 * method would return false. Otherwise, it would return true. This method should only be called by
 * the \c AAPLListController instance. Normally you would call the users will call the \c -canCreateListWithName:
 * method on \c AAPLListController, which will forward down to the current \c AAPLListCoordinator
 * instance.
 *
 * @param name The name to use when checking to see if a list can be created.
 *
 * @return \c YES if the list can be created with the given name, \c NO otherwise.
 */
- (BOOL)canCreateListWithName:(NSString *)name;

@end


/*!
 * The \c AAPLListCoordinatorDelegate protocol exists to allow \c AAPLListCoordinator instances to forward
 * events. These events include a \c AAPLListCoordinator removing, inserting, and updating their important,
 * tracked \c NSURL instances. The \c AAPLListCoordinatorDelegate also allows a \c AAPLListCoordinator
 * to notify its delegate of any errors that occured when removing or creating a list for a given URL.
 */
@protocol AAPLListCoordinatorDelegate <NSObject>

/*!
 * Notifies the \c AAPLListCoordinatorDelegate instance of any changes to the tracked URLs of the
 * \c AAPLListCoordinator. For more information about when this method should be called, see the
 * description for the other \c AAPLListCoordinator methods mentioned above that manipulate the tracked
 * \c NSURL instances.
 *
 * @param insertedURLs The \c NSURL instances that are newly tracked.
 * @param removedURLs The \c NSURL instances that have just been untracked.
 * @param updatedURLs The \c NSURL instances that have had their underlying model updated.
 */
- (void)listCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs removedURLs:(NSArray *)removedURLs updatedURLs:(NSArray *)updatedURLs;

/*!
 * Notifies an \c AAPLListCoordinatorDelegate instance of an error that occured when a coordinator
 * tried to remove a specific URL from the tracked \c NSURL instances. For more information about when
 * this method should be called, see the description for \c <tt>-[AAPLListCoordinator removeListAtURL:]</tt>.
 *
 * @param URL The \c NSURL instance that failed to be removed.
 * @param error The error that describes why the remove failed.
 */
- (void)listCoordinatorDidFailRemovingListAtURL:(NSURL *)URL withError:(NSError *)error;

/*!
 * Notifies a \c AAPLListCoordinatorDelegate instance of an error that occured when a coordinator tried
 * to create a list at a given URL. For more information about when this method should be called, see
 * the description for \c <tt>-[AAPLListCoordinator createURLForList:withName:]</tt>.
 *
 * @param URL The \c NSURL instance that couldn't be created for a list.
 * @param error The error the describes why the create failed.
 */
- (void)listCoordinatorDidFailCreatingListAtURL:(NSURL *)URL withError:(NSError *)error;

@end
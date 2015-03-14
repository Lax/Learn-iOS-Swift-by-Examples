/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListsController and \c AAPLListsControllerDelegate infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to \c AAPLListInfo objects. In addition, it also provides a way for parts of the application to present errors that occured when creating or removing lists.
*/

@import Foundation;

@class AAPLListsController, AAPLListInfo, AAPLList;
@protocol AAPLListCoordinator;

/*!
 * The \c AAPLListsControllerDelegate protocol enables an \c AAPLListsController object to notify other
 * objects of changes to available \c AAPLListInfo objects. This includes "will change content" events,
 * "did change content" events, inserts, removes, updates, and errors. Note that the \c AAPLListsController
 * can call these methods on an aribitrary queue. If the implementation in these methods require UI
 * manipulations, you should respond to the changes on the main queue.
 */
@protocol AAPLListsControllerDelegate <NSObject>

@optional

/*!
 * Notifies the receiver of this method that the lists controller will change it's contents in some
 * form. This method is *always* called before any insert, remove, or update is received. In this method,
 * you should prepare your UI for making any changes related to the changes that you will need to reflect
 * once they are received. For example, if you have a table view in your UI that needs to respond to
 * changes to a newly inserted \c AAPLListInfo object, you would want to call your table view's
 * \c -beginUpdates method. Once all of the updates are performed, your \c -listsControllerDidChangeContent:
 * method will be called. This is where you would to call your table view's \c -endUpdates method.
 *
 * @param listsController The \c AAPLListsController instance that will change its content.
 */
- (void)listsControllerWillChangeContent:(AAPLListsController *)listsController;

/*!
 * Notifies the receiver of this method that the lists controller is tracking a new \c AAPLListInfo
 * object. Receivers of this method should update their UI accordingly.
 *
 * @param listsController The \c AAPLListsController instance that inserted the new \c AAPLListInfo.
 * @param listInfo The new \c AAPLListInfo object that has been inserted at \c index.
 * @param index The index that \c listInfo was inserted at.
 */
- (void)listsController:(AAPLListsController *)listsController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the lists controller is no longer tracking \c listInfo.
 * Receivers of this method should update their UI accordingly.
 *
 * @param listsController The \c AAPLListsController instance that removed \c listInfo.
 * @param listInfo The removed \c AAPLListInfo object.
 * @param index The index that \c listInfo was removed at.
 */
- (void)listsController:(AAPLListsController *)listsController didRemoveListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the lists controller received a message that \c listInfo
 * has updated its content. Receivers of this method should update their UI accordingly.
 *
 * @param listsController The \c AAPLListsController instance that was notified that \c listInfo has
 *                       been updated.
 * @param listInfo The \c AAPLListInfo object that has been updated.
 * @param index The index of \c listInfo, the updated \c AAPLListInfo.
 */
- (void)listsController:(AAPLListsController *)listsController didUpdateListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the lists controller did change it's contents in some form.
 * This method is *always* called after any insert, remove, or update is received. In this method, you
 * should finish off changes to your UI that were related to any insert, remove, or update. For an example
 * of how you might handle a "did change" contents call, see the discussion for \c -listsControllerWillChangeContent:.
 *
 * @param listsController The \c AAPLListsController instance that did change its content.
 */
- (void)listsControllerDidChangeContent:(AAPLListsController *)listsController;

/*!
 * Notifies the receiver of this method that an error occured when creating a new \c AAPLListInfo object.
 * In implementing this method, you should present the error to the user. Do not rely on the \c AAPLListInfo
 * instance to be valid since an error occured in creating the object.
 *
 * @param listsController The \c AAPLListsController that is notifying that a failure occured.
 * @param listInfo The \c AAPLListInfo that represents the list that couldn't be created.
 * @param error The error that occured.
 */
- (void)listsController:(AAPLListsController *)listsController didFailCreatingListInfo:(AAPLListInfo *)listInfo withError:(NSError *)error;

/*!
 * Notifies the receiver of this method that an error occured when removing an existing \c AAPLListInfo
 * object. In implementing this method, you should present the error to the user.
 *
 * @param listsController The \c AAPLListsController that is notifying that a failure occured.
 * @param listInfo The \c AAPLListInfo that represents the list that couldn't be removed.
 * @param error The error that occured.
 */
- (void)listsController:(AAPLListsController *)listsController didFailRemovingListInfo:(AAPLListInfo *)listInfo withError:(NSError *)error;

@end

/*!
 * The \c AAPLListsController class is responsible for tracking \c AAPLListInfo objects that are found through
 * lists controller's \c AAPLListCoordinator object. \c AAPLListCoordinator objects are responsible for
 * notifying the lists controller of inserts, removes, updates, and errors when interacting with a list's
 * URL. Since the work of searching, removing, inserting, and updating \c AAPLListInfo objects is done
 * by the lists controller's coordinator, the lists controller serves as a way to avoid the need to interact
 * with a single \c AAPLListCoordinator directly throughout the application. It also allows the rest
 * of the application to deal with \c AAPLListInfo objects rather than dealing with their \c NSURL
 * instances directly. In essence, the work of a lists controller is to "front" its current coordinator.
 * All changes that the coordinator relays to the \c AAPLListsController object will be relayed to the
 * lists controller's delegate. This ability to front another object is particularly useful when the
 * underlying coordinator changes. As an example, this could happen when the user changes their storage
 * option from using local documents to using cloud documents. If the coordinator property of the list
 * controller changes, other objects throughout the application are unaffected since the lists controller 
 * will notify them of the appropriate changes (removes, inserts, etc.).
 */
@interface AAPLListsController : NSObject

/*!
 * Initializes an \c AAPLListsController instance with an initial \c AAPLListCoordinator object and a
 * sort comparator (if any). If sort comparator is nil, the controller ignores sort order.
 *
 * @param listCoordinator The \c AAPLListsController object's initial \c AAPLListCoordinator.
 * @param delegateQueue The queue in which the \c AAPLListsController object invokes delegate messages. If
                       \c nil, the main operation queue is used.
 * @param sortComparator The predicate that determines the strict sort ordering of the \c AAPLlistInfos
 *                       array.
 */
- (instancetype)initWithListCoordinator:(id<AAPLListCoordinator>)listCoordinator delegateQueue:(NSOperationQueue *)delegateQueue sortComparator:(NSComparisonResult (^)(AAPLListInfo *lhs, AAPLListInfo *rhs))sortComparator;

/*!
 * The \c AAPLListsController object's delegate who is responsible for responding to \c AAPLListsController
 * changes.
 */
@property (nonatomic, weak) id<AAPLListsControllerDelegate> delegate;

/*!
 * @return The number of tracked \c AAPLListInfo objects.
 */
@property (nonatomic, readonly) NSInteger count;

/*!
 * The current \c AAPLListCoordinator that the lists controller manages.
 */
@property (nonatomic, strong) id<AAPLListCoordinator> listCoordinator;

/*!
 * Begin listening for changes to the tracked \c AAPLListInfo objects. This is managed by the \c listCoordinator
 * object. Be sure to balance each call to \c -startSearching with a call to \c -stopSearching.
 */
- (void)startSearching;

/*!
 * Stop listening for changes to the tracked \c AAPLListInfo objects. This is managed by the \c listCoordinator
 * object. Each call to \c -startSearching should be balanced with a call to this method.
 */
- (void)stopSearching;

/*!
 * @return The \c AAPLListInfo instance at a specific index. This method traps if the index is out
 *         of bounds.
 */
- (AAPLListInfo *)objectAtIndexedSubscript:(NSInteger)index;

/*!
 * Removes \c listInfo from the tracked \c ListInfo instances. This method forwards the remove operation
 * directly to the list coordinator. The operation can be performed asynchronously so long as the
 * underlying \c AAPLListCoordinator instance sends the \c AAPLListsController the correct delegate
 * messages: either a \c -listCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs:
 * call with the removed \c AAPLListInfo object, or with an error callback.
 *
 * @param listInfo The \c AAPLListInfo object to remove from the list of tracked \c AAPLListInfo
 *                 instances.
 */
- (void)removeListInfo:(AAPLListInfo *)listInfo;

/*!
 * Attempts to create \c AAPLListInfo representing \c list with the given name. If the method is succesful,
 * the lists controller adds it to the list of tracked \c AAPLListInfo instances. This method forwards
 * the create operation directly to the list coordinator. The operation can be performed asynchronously
 * so long as the underlying \c AAPLListCoordinator instance sends the \c AAPLListsController the correct
 * delegate messages: either a \c -listCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs:
 * call with the newly inserted \c AAPLListInfo, or with an error callback.
 *
 * Note: it's important that before calling this method, a call to \c -canCreateListWithName: is
 * performed to make sure that the name is a valid list name. Doing so will decrease the errors that
 * you see when you actually create a list.
 *
 * @param list The \c AAPLList object that should be used to save the initial list.
 * @param name The name of the new list.
 */
- (void)createListInfoForList:(AAPLList *)list withName:(NSString *)name;

/*!
 * Determines whether or not a list can be created with a given name. This method delegates to
 * \c listCoordinator to actually check to see if the list can be created with the given name. This
 * method should be called before \c -createListInfoForList:withName: is called to ensure to minimize
 * the number of errors that can occur when creating a list.
 *
 * @param name The name to check to see if it's valid or not.
 *
 * @return \c YES if the list can be created with the given name, \c NO otherwise.
 */
- (BOOL)canCreateListInfoWithName:(NSString *)name;

/*!
 * Lets the \c AAPLListsController know that \c listInfo has been udpdated. Once the change is reflected
 * in \c listInfos array, a didUpdateListInfo message is sent.
 *
 * @param listInfo The \c AAPLListInfo instance that has new content.
 */
- (void)setListInfoHasNewContents:(AAPLListInfo *)listInfo;

@end

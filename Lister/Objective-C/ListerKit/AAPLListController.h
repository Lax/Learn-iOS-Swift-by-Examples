/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLListController and \c AAPLListControllerDelegate infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to \c AAPLListInfo objects. In addition, it also provides a way for parts of the application to present errors that occured when creating or removing lists.
            
*/

@import Foundation;

@class AAPLListController, AAPLListInfo, AAPLList;
@protocol AAPLListCoordinator;

/*!
 * The \c AAPLListControllerDelegate protocol enables an \c AAPLListController object to notify other
 * objects of changes to available \c AAPLListInfo objects. This includes "will change content" events,
 * "did change content" events, inserts, removes, updates, and errors. Note that the \c AAPLListController
 * can call these methods on an aribitrary queue. If the implementation in these methods require UI
 * manipulations, you should respond to the changes on the main queue.
 */
@protocol AAPLListControllerDelegate <NSObject>

/*!
 * Notifies the receiver of this method that the list controller will change it's contents in some
 * form. This method is *always* called before any insert, remove, or update is received. In this method,
 * you should prepare your UI for making any changes related to the changes that you will need to reflect
 * once they are received. For example, if you have a table view in your UI that needs to respond to
 * changes to a newly inserted \c AAPLListInfo object, you would want to call your table view's
 * \c -beginUpdates method. Once all of the updates are performed, your \c -listControllerDidChangeContent:
 * method will be called. This is where you would to call your table view's \c -endUpdates method.
 *
 * @param listController The \c AAPLListController instance that will change its content.
 */
- (void)listControllerWillChangeContent:(AAPLListController *)listController;

/*!
 * Notifies the receiver of this method that the list controller is tracking a new \c AAPLListInfo
 * object. Receivers of this method should update their UI accordingly.
 *
 * @param listController The \c AAPLListController instance that inserted the new \c AAPLListInfo.
 * @param listInfo The new \c AAPLListInfo object that has been inserted at \c index.
 * @param index The index that \c listInfo was inserted at.
 */
- (void)listController:(AAPLListController *)listController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the list controller received a message that \c listInfo
 * has updated its content. Receivers of this method should update their UI accordingly.
 *
 * @param listController The \c AAPLListController instance that was notified that \c listInfo has
 *                       been updated.
 * @param listInfo The \c AAPLListInfo object that has been updated.
 * @param index The index of \c listInfo, the updated \c AAPLListInfo.
 */
- (void)listController:(AAPLListController *)listController didRemoveListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the list controller is no longer tracking \c listInfo.
 * Receivers of this method should update their UI accordingly.
 *
 * @param listController The \c AAPLListController instance that removed \c listInfo.
 * @param listInfo The removed \c AAPLListInfo object.
 * @param index The index that \c listInfo was removed at.
 */
- (void)listController:(AAPLListController *)listController didUpdateListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the list controller did change it's contents in some form.
 * This method is *always* called after any insert, remove, or update is received. In this method, you
 * should finish off changes to your UI that were related to any insert, remove, or update. For an example
 * of how you might handle a "did change" contents call, see the discussion for \c -listControllerWillChangeContent:.
 *
 * @param listController The \c AAPLListController instance that did change its content.
 */
- (void)listControllerDidChangeContent:(AAPLListController *)listController;

/*!
 * Notifies the receiver of this method that an error occured when creating a new \c AAPLListInfo object.
 * In implementing this method, you should present the error to the user. Do not rely on the \c AAPLListInfo
 * instance to be valid since an error occured in creating the object.
 *
 * @param listController The \c AAPLListController that is notifying that a failure occured.
 * @param listInfo The \c AAPLListInfo that represents the list that couldn't be created.
 * @param error The error that occured.
 */
- (void)listController:(AAPLListController *)listController didFailCreatingListInfo:(AAPLListInfo *)listInfo withError:(NSError *)error;

/*!
 * Notifies the receiver of this method that an error occured when removing an existing \c AAPLListInfo
 * object. In implementing this method, you should present the error to the user.
 *
 * @param listController The \c AAPLListController that is notifying that a failure occured.
 * @param listInfo The \c AAPLListInfo that represents the list that couldn't be removed.
 * @param error The error that occured.
 */
- (void)listController:(AAPLListController *)listController didFailRemovingListInfo:(AAPLListInfo *)listInfo withError:(NSError *)error;

@end

/*!
 * The \c AAPLListController class is responsible for tracking \c AAPLListInfo objects that are found through
 * list controller's \c AAPLListCoordinator object. \c AAPLListCoordinator objects are responsible for
 * notifying the list controller of inserts, removes, updates, and errors when interacting with a list's
 * URL. Since the work of searching, removing, inserting, and updating \c AAPLListInfo objects is done
 * by the list controller's coordinator, the list controller serves as a way to avoid the need to interact
 * with a single \c AAPLListCoordinator directly throughout the application. It also allows the rest
 * of the application to deal with \c AAPLListInfo objects rather than dealing with their \c NSURL
 * instances directly. In essence, the work of a list controller is to "front" its current coordinator.
 * All changes that the coordinator relays to the \c AAPLListController object will be relayed to the
 * list controller's delegate. This ability to front another object is particularly useful when the
 * underlying coordinator changes. As an example, this could happen when the user changes their storage
 * option from using local documents to using cloud documents. If the coordinator property of the list
 * controller changes, other objects throughout the application are unaffected since the list controller 
 * will notify them of the appropriate changes (removes, inserts, etc.).
 */
@interface AAPLListController : NSObject

/*!
 * Initializes an \c AAPLListController instance with an initial \c AAPLListCoordinator object and a
 * sort comparator (if any). If sort comparator is nil, the controller ignores sort order.
 *
 * @param listCoordinator The \c AAPLListController object's initial \c AAPLListCoordinator.
 * @param sortComparator The predicate that determines the strict sort ordering of the \c AAPLlistInfos
 *                       array.
 */
- (instancetype)initWithListCoordinator:(id<AAPLListCoordinator>)listCoordinator sortComparator:(NSComparisonResult (^)(AAPLListInfo *lhs, AAPLListInfo *rhs))sortComparator;

/*!
 * The \c AAPLListController object's delegate who is responsible for responding to \c AAPLListController
 * changes.
 */
@property (nonatomic, weak) id<AAPLListControllerDelegate> delegate;

/*!
 * @return The number of tracked \c AAPLListInfo objects.
 */
@property (nonatomic, readonly) NSInteger count;

/*!
 * The current \c AAPLListCoordinator that the list controller manages.
 */
@property (nonatomic, strong) id<AAPLListCoordinator> listCoordinator;

/*!
 * @return The \c AAPLListInfo instance at a specific index. This method traps if the index is out
 *         of bounds.
 */
- (AAPLListInfo *)objectAtIndexedSubscript:(NSInteger)index;

/*!
 * Removes \c listInfo from the tracked \c ListInfo instances. This method forwards the remove operation
 * directly to the list coordinator. The operation can be performed asynchronously so long as the
 * underlying \c AAPLListCoordinator instance sends the \c AAPLListController the correct delegate
 * messages: either a \c -listCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs:
 * call with the removed \c AAPLListInfo object, or with an error callback.
 *
 * @param listInfo The \c AAPLListInfo object to remove from the list of tracked \c AAPLListInfo
 *                 instances.
 */
- (void)removeListInfo:(AAPLListInfo *)listInfo;

/*!
 * Attempts to create \c AAPLListInfo representing \c list with the given name. If the method is succesful,
 * the list controller adds it to the list of tracked \c AAPLListInfo instances. This method forwards
 * the create operation directly to the list coordinator. The operation can be performed asynchronously
 * so long as the underlying \c AAPLListCoordinator instance sends the \c AAPLListController the correct
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
 * Lets the \c AAPLListController know that \c listInfo has been udpdated. Once the change is reflected
 * in \c listInfos array, a didUpdateListInfo message is sent.
 *
 * @param listInfo The \c AAPLListInfo instance that has new content.
 */
- (void)setListInfoHasNewContents:(AAPLListInfo *)listInfo;

@end

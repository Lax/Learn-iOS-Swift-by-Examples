/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLConnectivityListsController and \c AAPLConnectivityListsControllerDelegate infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to \c AAPLListInfo objects.
*/

@import Foundation;

@class AAPLListInfo, AAPLConnectivityListsController;

/*!
    The \c AAPLConnectivityListsControllerDelegate protocol enables an \c AAPLConnectivityListsController 
    object to notify other objects of changes to available \c AAPLListInfo objects. This includes 
    "will change content" events, "did change content" events, inserts, removes, updates, and errors. Note 
    that the \c AAPLListsController can call these methods on an aribitrary queue. If the implementation in 
    these methods require UI manipulations, you should respond to the changes on the main queue.
 */
@protocol AAPLConnectivityListsControllerDelegate <NSObject>

@optional

/*!
    Notifies the receiver of this method that the lists controller will change it's contents in some
    form. This method is *always* called before any insert, remove, or update is received. In this method,
    you should prepare your UI for making any changes related to the changes that you will need to reflect
    once they are received. Once all of the updates are performed, your \c -listsControllerDidChangeContent:
    method will be called.

    @param listsController The \c AAPLConnectivityListsController instance that will change its content.
 */
- (void)listsControllerWillChangeContent:(AAPLConnectivityListsController *)listsController;

/*!
    Notifies the receiver of this method that the lists controller is tracking a new \c AAPLListInfo
    object. Receivers of this method should update their UI accordingly.

    @param listsController The \c AAPLConnectivityListsController instance that inserted the new \c AAPLListInfo.
    @param listInfo The new \c AAPLListInfo object that has been inserted at \c index.
    @param index The index that \c listInfo was inserted at.
 */
- (void)listsController:(AAPLConnectivityListsController *)listsController didInsertListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index;

/*!
    Notifies the receiver of this method that the lists controller is no longer tracking \c listInfo.
    Receivers of this method should update their UI accordingly.

    @param listsController The \c AAPLConnectivityListsController instance that removed \c listInfo.
    @param listInfo The removed \c AAPLListInfo object.
    @param index The index that \c listInfo was removed at.
 */
- (void)listsController:(AAPLConnectivityListsController *)listsController didRemoveListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index;

/*!
    Notifies the receiver of this method that the lists controller received a message that \c listInfo
    has updated its content. Receivers of this method should update their UI accordingly.

    @param listsController The \c AAPLConnectivityListsController instance that was notified that \c listInfo has
                          been updated.
    @param listInfo The \c AAPLListInfo object that has been updated.
    @param index The index of \c listInfo, the updated \c AAPLListInfo.
 */
- (void)listsController:(AAPLConnectivityListsController *)listsController didUpdateListInfo:(AAPLListInfo *)listInfo atIndex:(NSInteger)index;

/*!
    Notifies the receiver of this method that the lists controller did change it's contents in some form.
    This method is *always* called after any insert, remove, or update is received. In this method, you
    should finish off changes to your UI that were related to any insert, remove, or update.

    @param listsController The \c AAPLConnectivityListsController instance that did change its content.
 */
- (void)listsControllerDidChangeContent:(AAPLConnectivityListsController *)listsController;

@end

/*!
    The \c AAPLConnectivityListsController class is responsible for tracking \c AAPLListInfo objects that are
    found through lists controller's \c WCSession object. \c WCSession is responsible for informing watchOS 
    applications of changes occurring in their counterpart application. It also allows the rest of the 
    application to deal with \c AAPLListInfo objects rather than the various types that \c WCSession may directly 
    vend instances of. In essence, the work of a lists controller is to "front" the device's default WCSession.
 */
@interface AAPLConnectivityListsController : NSObject

/*!
    The \c AAPLConnectivityListsController object's delegate who is responsible for responding to \c AAPLListsController
    changes.
 */
@property (nonatomic, weak) id<AAPLConnectivityListsControllerDelegate> delegate;

/*!
    @return The number of tracked \c AAPLListInfo objects.
 */
@property (nonatomic, readonly) NSInteger count;

/*!
    Initializes an \c AAPLConnectivityListsController instance and configures it to interact with the default
    \c WCSession.
 */
- (instancetype)init;

/*!
    Initializes an \c AAPLConnectivityListsController instance and configures it to interact with the default
    \c WCSession. The list name is used to focus the controller on changes to a single list.

    @param listName A \c NSString matching the name of the single list to be monitored.
 */
- (instancetype)initWithListName:(NSString *)listName;

/*!
    Begin listening for changes to the tracked \c AAPLListInfo objects. Be sure to balance each call to 
    \c -startSearching with a call to \c -stopSearching.
 */
- (void)startSearching;

/*!
    Stop listening for changes to the tracked \c AAPLListInfo objects. Each call to \c -startSearching should 
    be balanced with a call to this method.
 */
- (void)stopSearching;

/*!
    @return The \c AAPLListInfo instance at a specific index. This method traps if the index is out
            of bounds.
 */
- (AAPLListInfo *)objectAtIndexedSubscript:(NSInteger)index;

@end

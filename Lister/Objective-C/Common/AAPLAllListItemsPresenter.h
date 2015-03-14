/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The implementation for the \c AAPLAllListItemsPresenter type. This class is responsible for managing how a list is presented in the iOS and OS X apps.
*/

#import "AAPLListPresenting.h"

@class AAPLListItem;

/*!
 * The \c AAPLAllListItemsPresenter list presenter class is responsible for managing how a list is displayed
 * in both the iOS and OS X apps. The \c AAPLAllListItemsPresenter class conforms to \c AAPLListPresenting so
 * consumers of this class can work with the presenter with a common interface.
 *
 * When a list is presented with an \c AAPLAllListItemsPresenter, all of the list items with a list are
 * presented as the name suggests!). When the list items are displayed to a user, the incomplete list items
 * are ordered before the complete list items. This order is determined when \c -setList: is called on the \c
 * AAPLAllListItemsPresenter instance. The presenter then reorders the list items accordingly, calling the
 * delegate methods with any relevant changes.
 *
 * An \c AAPLAllListItemsPresenter can be interacted with in a few ways. It can insert, remove, toggle, move,
 * and update list items. It can also change the color of the presented list. All of these changes get
 * funnelled through callbacks to the delegate (an \c AAPLListPresenterDelegate). For more information about
 * how the delegate pattern for the \c AAPLListPresenting instance is architected, see the \c
 * AAPLListPresenting definition.  What's unique about the \c AAPLAllListItemsPresenter with respect to the
 * delegate methods is that the \c AAPLAllListItemsPresenter has an undo manager. Whenever the presentation of
 * the list is manipulated (as described above), the presenter pushes an undo operation that reverses the
 * manipulation onto the undo stack.  For example, if a list item is inserted, the \c
 * AAPLAllListItemsPresenter instance registers an undo operation to remove the list item. When a user
 * performs an undo in either the iOS or OS X app, the list item that was inserted is removed. The remove
 * operation gets funnelled into the same delegate that inserted the list item. By abstracting these
 * operations away into a presenter and delegate architecture, we're not only able to easily test the code
 * that manipulates the list, but we're also able to test the undo registration code.
 *
 * One thing to note is that when a list item is toggled in the \c AAPLAllListItemsPresenter, it is moved from
 * an index in its current completion state to an index opposite of the list items completion state. For
 * example, if a list item that is complete is toggled, it will move to an incomplete index (e.g. index 0).
 * For the \c AAPLAllListItemsPresenter, a toggle represents both the list item moving as well as the list
 * item being updated.
 */
@interface AAPLAllListItemsPresenter : NSObject <AAPLListPresenting>

/*!
 * The undo manager to register undo events with when the \c AAPLAllListItemsPresenter instance is manipulated.
 */
@property NSUndoManager *undoManager;

/*!
 * Inserts \c listItem into the list. If the list item is incomplete, \c listItem is inserted at index 0.
 * Otherwise, it is inserted at the end of the list. Inserting a list item calls the delegate's \c
 * -listPresenter:didInsertListItem:atIndex: method. Calling this method registers an undo event to remove the
 * list item.
 *
 * \param listItem
 * The \c AAPLListItem instance to insert.
 */
- (void)insertListItem:(AAPLListItem *)listItem;

/*!
 * Inserts \c listItems into the list. The net effect of this is calling \c -insertListItem: for each \c
 * AAPLListItem instance in \c listItems. Inserting list items calls the delegate's \c
 * -listPresenter:didInsertListItem:atIndex: method for each inserted list item after an individual list item
 * has been inserted. Calling this method registers an undo event to remove each list item.
 *
 * \param listItems
 * The \c AAPLListItem instances to insert.
 */
- (void)insertListItems:(NSArray *)listItems;

/*!
 * Removes \c listItem from the list. Removing the list item calls the delegate's \c
 * -listPresenter:didRemoveListItem:atIndex: method for the removed list item after it has been removed.
 * Calling this method registers an undo event to insert the list item at its previous index.
 *
 * \param listItem
 * The \c AAPLListItem instance to remove.
 */
- (void)removeListItem:(AAPLListItem *)listItem;

/*!
 * Removes \c listItems from the list. Removing list items calls the delegate's \c
 * -listPresenter:didRemoveListItem:atIndex: method for each of the removed list items after an individual
 * list item has been removed. Calling this method registers an undo event to insert the list items that were
 * removed at their previous indexes.
 *
 * \param listItems
 * The \c AAPLListItem instances to remove.
 */
- (void)removeListItems:(NSArray *)listItems;

/*!
 * Updates the \c text property of \c listItem with \c newText. Updating the text property of the list item
 * calls the delegate's \c -listPresenter:didUpdateListItem:atIndex: method for the list item that was
 * updated.  Calling this method registers an undo event to revert the text change back to the text before the
 * method was invoked.
 *
 * \param listItem
 * The \c AAPLListItem instance whose text needs to be updated.
 *
 * \param newText
 * The new text for \c listItem.
 */
- (void)updateListItem:(AAPLListItem *)listItem withText:(NSString *)newText;

/*!
 * Tests whether \c listItem is in the list and can be moved from its current index in the list (if it's
 * already in the list) to \c toIndex.
 *
 * \param listItem
 * The item to test for insertion.
 *
 * \param toIndex
 * The index to use to determine if \c listItem can be inserted into the list.
 *
 * \returns
 * Whether or not \c listItem and be moved to \c toIndex.
 */
- (BOOL)canMoveListItem:(AAPLListItem *)listItem toIndex:(NSInteger)toIndex;

/*!
 * Moves \c listItem to \c toIndex. Moving the \c listItem to a new index calls the delegate's \c
 * -listPresenter:didMoveListItem:fromIndex:toIndex method with the moved list item. Calling this method
 * registers an undo event that moves the list item from its new index back to its old index.
 *
 * \param listItem
 * The list item to move.
 *
 * \param toIndex 
 * The index to move \c listItem to.
 */
- (void)moveListItem:(AAPLListItem *)listItem toIndex:(NSInteger)toIndex;

/*!
 * Toggles \c listItem within the list. This method moves a complete list item to an incomplete index at the
 * beginning of the list, or it moves an incomplete list item to a complete index at the last index of the
 * list.  The list item is also updated in place since the completion state is flipped. Toggling a list item
 * calls the delegate's \c -listPresenter:didMoveListItem:fromIndex:toIndex: method followed by the delegate's
 * \c -listPresenter:didUpdateListItem:atIndex: method. Calling this method registers an undo event that
 * toggles the list item back to its original location and completion state.
 *
 \param listItem
 * The list item to toggle.
 */
- (void)toggleListItem:(AAPLListItem *)listItem;

/*!
 * Set all of the presented list item's completion states to \c completionState. This method does not move the
 * list items around whatsoever. Changing the completion state on all of the list items calls the delegate's
 * \c -listPresenter:didUpdateListItem:atIndex: method for each list item that has been updated. Calling this
 * method registers an undo event that sets the completion states for all of the list items back to the
 * original state before the method was invoked.
 *
 * \param completionState
 * The value that all presented list item instances should have as their \c isComplete property.
 */
- (void)updatePresentedListItemsToCompletionState:(BOOL)completionState;

@end

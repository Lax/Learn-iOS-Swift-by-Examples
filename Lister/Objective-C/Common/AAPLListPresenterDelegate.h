/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The definition for the \c AAPLListPresenterDelegate type. This protocol defines the contract between the \c AAPLListPresenting interactions and receivers of those events (the type that conforms to the \c AAPLListPresenterDelegate protocol).
*/

@protocol AAPLListPresenting;

/*!
 * The \c AAPLListPresenterDelegate type is used to receive events from an \c AAPLListPresenting instance
 * about updates to the presenter's layout. This happens, for example, if an \c AAPLListItem object is
 * inserted into the list or removed from the list. For any change that occurs to the list, a delegate message
 * can be called, but you may decide not to take any action if the method doesn’t apply to your use case. For
 * an implementation of \c AAPLListPresenterDelegate, see the \c AAPLAllListItemsPresenter or \c
 * AAPLIncompleteListItemsPresenter types.
 */
@protocol AAPLListPresenterDelegate

/*!
 * An \c AAPLListPresenting instance invokes this method on its delegate when a large change to the underlying
 * list changed, but the presenter couldn't resolve the granular changes. A full layout change includes
 * changing anything on the underlying list: list item toggling, text updates, color changes, etc. This is
 * invoked, for example, when the list is initially loaded, because there could be many changes that happened
 * relative to an empty list--the delegate should just reload everything immediately. This method is not
 * wrapped in \c -listPresenterWillChangeListLayout:isInitialLayout: and \c
 * -listPresenterDidChangeListLayout:isInitialLayout: method invocations.
 *
 * \param listPresenter
 * The list presenter whose full layout has changed.
 */
- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter;

/*!
 * An \c AAPLListPresenting instance invokes this method on its delegate before a set of layout changes
 * occur. This could involve list item insertions, removals, updates, toggles, etc. This can also include
 * changes to the color of the \c AAPLListPresenting instance. If \c isInitialLayout is \c YES, it means that
 * the new list is being presented for the first time--for example, if \c -setList: is called on the \c AAPLListPresenting
 * instance, the delegate will receive a \c -listPresenterWillChangeListLayout:isInitialLayout: call where
 * \c isInitialLayout is \c YES.
 *
 * \param listPresenter
 * The list presenter whose presentation will change.
 *
 * \param isInitialLayout
 * Whether or not the presenter is presenting the most recent list for the first time.
 */
- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout;

/*!
 * A \c AAPLListPresenting invokes this method on its delegate when an item was inserted into the list.  This
 * method is called only if the invocation is wrapped in a call to \c
 * -listPresenterWillChangeListLayout:isInitialLayout: and \c -listPresenterDidChangeListLayout:isInitialLayout:.
 *
 * \param listPresenter
 * The list presenter whose presentation has changed.
 *
 * \param listItem
 * The list item that has been inserted.
 *
 * \param index
 * The index that \c listItem was inserted into.
 */
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index;

/*!
 * An \c AAPLListPresenting invokes this method on its delegate when an item was removed from the list. This
 * method is called only if the invocation is wrapped in a call to \c
 * -listPresenterWillChangeListLayout:isInitialLayout: and \c -listPresenterDidChangeListLayout:isInitialLayout:.
 *
 * \param listPresenter
 * The list presenter whose presentation has changed.
 *
 * \param listItem
 * The list item that has been removed.
 *
 * \param index
 * The index that \c listItem was removed from.
 */
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index;

/*!
 * An \c AAPLListPresenting invokes this method on its delegate when an item is updated in place. This could
 * happen, for example, if the text of an \c AAPLListItem instance changes. This method is called only if the
 * invocation is wrapped in a call to \c -listPresenterWillChangeListLayout:isInitialLayout: and \c
 * -listPresenterDidChangeListLayout:isInitialLayout:.
 *
 * \param listPresenter
 * The list presenter whose presentation has changed.
 *
 * \param listItem
 * The list item that has been updated.
 *
 * \param index
 * The index that \c listItem was updated at in place.
 */
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index;

/*!
 * An \c AAPLListPresenting invokes this method on its delegate when an item moved \c fromIndex to \c toIndex.
 * This could happen, for example, if the list presenter toggles an \c AAPLListItem instance and it needs to
 * be moved from one index to another. This method is called only if the invocation is wrapped in a call to \c
 * -listPresenterWillChangeListLayout:isInitialLayout: and \c -listPresenterDidChangeListLayout:isInitialLayout:.
 *
 * \param listPresenter
 * The list presenter whose presentation has changed.
 *
 * \param listItem
 * The list item that has been moved.
 *
 * \param fromIndex
 * The original index that \c listItem was located at before the move.
 *
 * \param toIndex
 * The index that \c listItem was moved to.
 */
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

/*!
 * An \c AAPLListPresenting invokes this method on its delegate when the color of the \c AAPLListPresenting
 * instance's changes. This method is called only if the invocation is wrapped in a call to \c
 * -listPresenterWillChangeListLayout:isInitialLayout: and \c -listPresenterDidChangeListLayout:isInitialLayout:.
 *
 * \param listPresenter
 * The list presenter whose presentation has changed.
 *
 * \param color
 * The new color of the presented list.
 */
- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color;

/*!
 * An \c AAPLListPresenting invokes this method on its delegate after a set of layout changes occur. See \c
 * -listPresenterWillChangeListLayout:isInitialLayout: for examples of when this would be called.
 *
 * \param listPresenter
 * The list presenter whose presentation has changed.
 *
 \param isInitialLayout
 * Whether or not the presenter is presenting the most recent list for the first time.
 */
- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout;

@end

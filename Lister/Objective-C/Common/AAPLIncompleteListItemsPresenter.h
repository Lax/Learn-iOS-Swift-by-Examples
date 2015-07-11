/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The implementation for the \c AAPLIncompleteListItemsPresenter type. This class is responsible for managing how a list is presented in the iOS and OS X app Today widgets, as well as the Lister WatchKit application.
*/

#import "AAPLListPresenting.h"

@class AAPLListItem;

/*!
    The \c AAPLIncompleteListItemsPresenter list presenter is responsible for managing the how a list's
    incomplete list items are displayed in the iOS and OS X Today widgets as well as the Lister WatchKit app.
    The \c AAPLIncompleteListItemsPresenter class conforms to \c AAPLListPresenting so consumers of this class
    can work with the presenter using a common interface.

    When a list is initially presented with an \c AAPLIncompleteListItemsPresenter, only the incomplete list
    items are presented. That can change, however, if a user toggles list items (changing the list item's
    completion state). An \c AAPLIncompleteListItemsPresenter always shows the list items that are initially
    presented (unless they are removed from the list from another device). If an \c
    AAPLIncompleteListItemsPresenter stops presenting a list that has some presented list items that are complete
    (after toggling them) and another \c AAPLIncompleteListItemsPresenter presents the same list, the presenter
    displays *only* the incomplete list items.

    The \c AAPLIncompleteListItemsPresenter can be interacted with in a two ways. \c AAPLListItem instances can
    be toggled individually, or using a batch update, and the color of the list presenter can be changed. All
    of these methods trigger calls to the delegate to be notified about inserted list items, removed list
    items, updated list items, etc.
 */
@interface AAPLIncompleteListItemsPresenter : NSObject <AAPLListPresenting>

/*!
    Toggles \c listItem within the list. This method keeps the list item in the same place, but it toggles the
    completion state of the list item. Toggling a list item will call the delegate's \c
    -listPresenter:didUpdateListItem:atIndex: method.

    \param listItem
    The list item to toggle.
 */
- (void)toggleListItem:(AAPLListItem *)listItem;

/*!
    Sets all of the presented list item's completion states to \c completionState. This method does not move the
    list items around whatsoever. Changing the completion state on all of the list items will call the
    delegate's \c -listPresenter:didUpdateListItem:atIndex: method for each list item that has been updated.

    \param completionState
    The value that all presented list item instances should have as their \c isComplete property.
 */
- (void)updatePresentedListItemsToCompletionState:(BOOL)completionState;

@end

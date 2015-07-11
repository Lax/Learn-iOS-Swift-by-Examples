/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Helper functions to perform common operations in \c AAPLIncompleteListItemsPresenter and \c AAPLAllListItemsPresenter.
*/

@import Foundation;
#import "AAPLList.h"

@protocol AAPLListPresenting;

/*!
    Removes each list item found in \c listItemsToRemove from the \c initialListItems array. For each removal,
    the function notifies the \c listPresenter's delegate of the change.
 */
void AAPLRemoveListItemsFromListItemsWithListPresenter(id<AAPLListPresenting> listPresenter, NSMutableArray *initialListItems, NSArray *listItemsToRemove);

/*!
    Inserts each list item in \c listItemsToInsert into \c initialListItems. For each insertion, the function
    notifies the \c listPresenter's delegate of the change.
 */
void AAPLInsertListItemsIntoListItemsWithListPresenter(id<AAPLListPresenting> listPresenter, NSMutableArray *initialListItems, NSArray *listItemsToInsert);

/*!
    Replaces the stale list items in \c presentedListItems with the new ones found in \c newUpdatedListItems. For
    each update, the function notifies the \c listPresenter's delegate of the update.
 */
void AAPLUpdateListItemsWithListItemsForListPresenter(id<AAPLListPresenting> listPresenter, NSMutableArray *presentedListItems, NSArray *newUpdatedListItems);

/*!
    An enum to determine that determines how the \c AAPLUpdateListColorForListPresenterIfDifferent function handles
    calling list presenter delegate methods (and with what parameters).
 */
typedef NS_ENUM(NSInteger, AAPLListColorUpdateAction) {
    AAPLListColorUpdateActionDontSendDelegateChangeLayoutCalls,
    AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForInitialLayout,
    AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForNonInitialLayout
};

/*!
    Replaces the presented list's \c color with \c newColor if the colors are different. If the colors are different,
    the function notifies the delegate of the updated color change if the the \c listColorUpdateAction parameter
    is either \c AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForInitialLayout or
    \c AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForNonInitialLayout. Based on which one of those
    values are provided, the function will pass \c YES or \c NO to \c -listPresenterWillChangeListLayout:isInitialLayout:
    and \c -listPresenterDidChangeListLayout:isInitialLayout: for the \c isInitialLayout parameter. The function
    returns whether or not the list's color was updated.
 */
BOOL AAPLUpdateListColorForListPresenterIfDifferent(id<AAPLListPresenting> listPresenter, AAPLList *presentedList, AAPLListColor newColor, AAPLListColorUpdateAction listColorUpdateAction);

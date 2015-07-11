/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Simple internal helper functions to share across \c AAPLIncompleteListItemsPresenter and \c AAPLAllListItemsPresenter. These functions help diff two arrays of \c AAPLListItem objects.
*/

@import Foundation;

@class AAPLListItem;

/// An enum to keep track of the different kinds of changes that may take place within a list.
typedef NS_ENUM(NSInteger, AAPLListItemsBatchChangeKind) {
    AAPLListItemsBatchChangeKindNone,
    AAPLListItemsBatchChangeKindRemoved,
    AAPLListItemsBatchChangeKindInserted,
    AAPLListItemsBatchChangeKindToggled,
    AAPLListItemsBatchChangeKindUpdatedText,
    AAPLListItemsBatchChangeKindMultiple
};

/// Returns an array of \c AAPLListItem objects in \c initialListItems that don't exist in \c changedListItems.
NSArray *AAPLFindRemovedListItemsFromInitialListItemsToChangedListItems(NSArray *initialListItems, NSArray *changedListItems);

/// Returns an array of \c AAPLListItem objects in \c changedListItems that don't exist in \c initialListItems.
NSArray *AAPLFindInsertedListItemsFromInitialListItemsToChangedListItems(NSArray *initialListItems, NSArray *changedListItems, BOOL (^filterHandlerOrNil)(AAPLListItem *listItem));

/*!
    Returns an array of \c AAPLListItem objects in \c changedListItems whose completion state changed from \c initialListItems
    relative to `changedListItems`.
 */
NSArray *AAPLFindToggledListItemsFromInitialListItemsToChangedListItems(NSArray *initialListItems, NSArray *changedListItems);

/*!
    Returns an array of \c AAPLListItem objects in \c changedListItems whose text changed from \c initialListItems
    relative to \c changedListItems.
 */
NSArray *AAPLFindListItemsWithUpdatedTextFromInitialListItemsToChangedListItems(NSArray *initialListItems, NSArray *changedListItems);

/*!
    Update \c replaceableNewListItems in place with all of the list items that are equal in \c previousUnchangedListItems.
    For example, if \c replaceableNewListItems has list items of UUID "1", "2", and "3" and \c previousUnchangedListItems
    has list items of UUID "2" and "3", the \c replaceableNewListItems array will have it's list items with UUID
    "2" and "3" replaced with the list items whose UUID is "2" and "3" in \c previousUnchangedListItems. This is
    used to ensure that the list items in multiple arrays are referencing the same objects in memory as what the
    presented list items are presenting.
 */
void AAPLReplaceAnyEqualUnchangedNewListItemsWithPreviousUnchangedListItems(NSMutableArray *replaceableNewListItems, NSArray *previousUnchangedListItems);

/*!
    Returns the type of \c AAPLListItemsBatchChangeKind based on the different types of changes. The parameters
    for this function should be based on the result of the functions above. If there were no changes whatsoever,
    \c nil is returned.
 */
AAPLListItemsBatchChangeKind AAPLListItemsBatchChangeKindForChanges(NSArray *removedListItems, NSArray *insertedListItems, NSArray *toggledListItems, NSArray *listItemsWithUpdatedText);
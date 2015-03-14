/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Helper functions to perform common operations in \c AAPLIncompleteListItemsPresenter and \c AAPLAllListItemsPresenter.
*/

#import "AAPLListPresenterUtilities.h"
#import "AAPLListPresenterDelegate.h"
#import "AAPLListPresenting.h"
#import "AAPLList.h"

void AAPLRemoveListItemsFromListItemsWithListPresenter(id<AAPLListPresenting> listPresenter, NSMutableArray *initialListItems, NSArray *listItemsToRemove) {
    NSArray *sortedListItemsToRemove = [listItemsToRemove sortedArrayUsingComparator:^NSComparisonResult(AAPLListItem *lhs, AAPLListItem *rhs) {
        return [initialListItems indexOfObject:lhs] > [initialListItems indexOfObject:rhs];
    }];
    
    for (AAPLListItem *listItemToRemove in sortedListItemsToRemove) {
        // Use the index of the list item to remove in the current list's list items.
        NSInteger indexOfListItemToRemoveInOldList = [initialListItems indexOfObject:listItemToRemove];
        
        [initialListItems removeObjectAtIndex:indexOfListItemToRemoveInOldList];
        
        [listPresenter.delegate listPresenter:listPresenter didRemoveListItem:listItemToRemove atIndex:indexOfListItemToRemoveInOldList];
    }
}

void AAPLInsertListItemsIntoListItemsWithListPresenter(id<AAPLListPresenting> listPresenter, NSMutableArray *initialListItems, NSArray *listItemsToInsert) {
    [listItemsToInsert enumerateObjectsUsingBlock:^(AAPLListItem *insertedIncompleteListItem, NSUInteger idx, BOOL *stop) {
        [initialListItems insertObject:insertedIncompleteListItem atIndex:idx];
        
        [listPresenter.delegate listPresenter:listPresenter didInsertListItem:insertedIncompleteListItem atIndex:idx];
    }];
}

void AAPLUpdateListItemsWithListItemsForListPresenter(id<AAPLListPresenting> listPresenter, NSMutableArray *presentedListItems, NSArray *newUpdatedListItems) {
    for (AAPLListItem *newlyUpdatedListItem in newUpdatedListItems) {
        NSInteger indexOfListItem = [presentedListItems indexOfObject:newlyUpdatedListItem];
        
        presentedListItems[indexOfListItem] = newlyUpdatedListItem;
        
        [listPresenter.delegate listPresenter:listPresenter didUpdateListItem:newlyUpdatedListItem atIndex:indexOfListItem];
    }
}

BOOL AAPLUpdateListColorForListPresenterIfDifferent(id<AAPLListPresenting> listPresenter, AAPLList *presentedList, AAPLListColor newColor, AAPLListColorUpdateAction listColorUpdateAction) {
    // Don't trigger any updates if the new color is the same as the current color.
    if (presentedList.color == newColor) {
        return NO;
    }
    
    if (listColorUpdateAction == AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForInitialLayout) {
        [listPresenter.delegate listPresenterWillChangeListLayout:listPresenter isInitialLayout:YES];
    }
    else if (listColorUpdateAction == AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForNonInitialLayout) {
        [listPresenter.delegate listPresenterWillChangeListLayout:listPresenter isInitialLayout:NO];
    }
    
    presentedList.color = newColor;
    
    [listPresenter.delegate listPresenter:listPresenter didUpdateListColorWithColor:newColor];
    
    if (listColorUpdateAction == AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForInitialLayout) {
        [listPresenter.delegate listPresenterDidChangeListLayout:listPresenter isInitialLayout:YES];
    }
    else if (listColorUpdateAction == AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForNonInitialLayout) {
        [listPresenter.delegate listPresenterDidChangeListLayout:listPresenter isInitialLayout:NO];
    }
    
    return YES;
}
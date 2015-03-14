/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Simple internal helper functions to share across \c AAPLIncompleteListItemsPresenter and \c AAPLAllListItemsPresenter. These functions help diff two arrays of \c AAPLListItem objects.
*/

#import "AAPLListPresenterAlgorithms.h"
#import "AAPLListItem.h"

NSArray *AAPLFindRemovedListItemsFromInitialListItemsToChangedListItems(NSArray *initialListItems, NSArray *changedListItems) {
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"!(self in %@)", changedListItems];

    return [initialListItems filteredArrayUsingPredicate:filterPredicate];
}

NSArray *AAPLFindInsertedListItemsFromInitialListItemsToChangedListItems(NSArray *initialListItems, NSArray *changedListItems, BOOL (^filterHandlerOrNil)(AAPLListItem *listItem)) {
    NSPredicate *containmentPredicate = [NSPredicate predicateWithFormat:@"!(self in %@)", initialListItems];
    
    NSMutableArray *predicates = [NSMutableArray arrayWithObject:containmentPredicate];
    
    if (filterHandlerOrNil) {
        NSPredicate *filterHandlerPredicate = [NSPredicate predicateWithBlock:^BOOL(AAPLListItem *listItem, NSDictionary *bindings) {
            return filterHandlerOrNil(listItem);
        }];
        
        [predicates addObject:filterHandlerPredicate];
    }
    
    NSCompoundPredicate *filterPredicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:predicates];
    
    return [changedListItems filteredArrayUsingPredicate:filterPredicate];
}

NSArray *AAPLFindToggledListItemsFromInitialListItemsToChangedListItems(NSArray *initialListItems, NSArray *changedListItems) {
    NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(AAPLListItem *changedListItem, NSDictionary *bindings) {
        NSInteger indexOfChangedListItemInInitialListItems = [initialListItems indexOfObject:changedListItem];
        
        if (indexOfChangedListItemInInitialListItems == NSNotFound) {
            return NO;
        }
        
        AAPLListItem *initialListItem = initialListItems[indexOfChangedListItemInInitialListItems];
        
        return initialListItem.isComplete != changedListItem.isComplete;
    }];
    
    return [changedListItems filteredArrayUsingPredicate:filterPredicate];
}

NSArray *AAPLFindListItemsWithUpdatedTextFromInitialListItemsToChangedListItems(NSArray *initialListItems, NSArray *changedListItems) {
    NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(AAPLListItem *changedListItem, NSDictionary *bindings) {
        NSInteger indexOfChangedListItemInInitialListItems = [initialListItems indexOfObject:changedListItem];
        
        if (indexOfChangedListItemInInitialListItems == NSNotFound) {
            return NO;
        }
        
        AAPLListItem *initialListItem = initialListItems[indexOfChangedListItemInInitialListItems];
        
        return ![initialListItem.text isEqualToString:changedListItem.text];
    }];
    
    return [changedListItems filteredArrayUsingPredicate:filterPredicate];
}

void AAPLReplaceAnyEqualUnchangedNewListItemsWithPreviousUnchangedListItems(NSMutableArray *replaceableNewListItems, NSArray *previousUnchangedListItems) {
    NSArray *replaceableNewListItemsCopy = [replaceableNewListItems copy];
    
    [replaceableNewListItemsCopy enumerateObjectsUsingBlock:^(AAPLListItem *replaceableNewListItem, NSUInteger idx, BOOL *stop) {
        NSInteger indexOfUnchangedListItem = [previousUnchangedListItems indexOfObject:replaceableNewListItem];
        
        if (indexOfUnchangedListItem != NSNotFound) {
            replaceableNewListItems[idx] = previousUnchangedListItems[indexOfUnchangedListItem];
        }
    }];
}

AAPLListItemsBatchChangeKind AAPLListItemsBatchChangeKindForChanges(NSArray *removedListItems, NSArray *insertedListItems, NSArray *toggledListItems, NSArray *listItemsWithUpdatedText) {
    __block AAPLListItemsBatchChangeKind listItemsBatchChangeKind = AAPLListItemsBatchChangeKindNone;
    
    /*
        A simple helper block that takes in the new change kind. If there has already been a change kind set
        to a value other than AAPLListItemsBatchChangeKindMultiple, the block updates listItemsBatchChangeKind
        to be AAPLListItemsBatchChangeKindMultiple instead of newChangeKind.
    */
    void (^setListItemsBatchChangeKind)(AAPLListItemsBatchChangeKind) = ^(AAPLListItemsBatchChangeKind newChangeKind) {
        if (listItemsBatchChangeKind != AAPLListItemsBatchChangeKindNone) {
            listItemsBatchChangeKind = AAPLListItemsBatchChangeKindMultiple;
        }
        else {
            listItemsBatchChangeKind = newChangeKind;
        }
    };
    
    if (removedListItems.count > 0) {
        setListItemsBatchChangeKind(AAPLListItemsBatchChangeKindRemoved);
    }
    
    if (insertedListItems.count > 0) {
        setListItemsBatchChangeKind(AAPLListItemsBatchChangeKindInserted);
    }
    
    if (toggledListItems.count > 0) {
        setListItemsBatchChangeKind(AAPLListItemsBatchChangeKindToggled);
    }
    
    if (listItemsWithUpdatedText.count > 0) {
        setListItemsBatchChangeKind(AAPLListItemsBatchChangeKindUpdatedText);
    }
    
    return listItemsBatchChangeKind;
}
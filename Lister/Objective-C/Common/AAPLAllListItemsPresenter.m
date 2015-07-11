/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The implementation for the \c AAPLAllListItemsPresenter type. This class is responsible for managing how a list is presented in the iOS and OS X apps.
*/

#import "AAPLAllListItemsPresenter.h"
#import "AAPLListPresenterDelegate.h"
#import "AAPLList.h"
#import "AAPLListItem.h"
#import "AAPLListPresenterAlgorithms.h"
#import "AAPLListPresenterUtilities.h"

@interface AAPLAllListItemsPresenter ()

/// The internal storage for the list that we're presenting. By default, it's an empty list.
@property (readwrite, nonatomic) AAPLList *list;

/// Flag to see whether or not the first \c -setList: call should trigger a batch reload.
@property (getter=isInitialList) BOOL initialList;

/// The index of the first complete item within the list's items.
@property (readonly) NSInteger indexOfFirstCompleteItem;

@end

@implementation AAPLAllListItemsPresenter
@synthesize delegate = _delegate;
@dynamic color;

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];

    if (self) {
        // Use a default, empty list.
        _list = [[AAPLList alloc] initWithColor:AAPLListColorGray items:@[]];
        _initialList = YES;
    }
    
    return self;
}

#pragma mark - AAPLListItemPresenter

- (void)setColor:(AAPLListColor)color {
    AAPLListColor oldColor = self.color;
    
    BOOL different = AAPLUpdateListColorForListPresenterIfDifferent(self, self.list, color, AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForNonInitialLayout);
    
    // Register the undo color operation with the old color if the list's color was changed.
    if (different) {
        [[self.undoManager prepareWithInvocationTarget:self] setColor:oldColor];
        
        NSString *undoActionName = NSLocalizedString(@"Change Color", nil);
        [self.undoManager setActionName:undoActionName];
    }
}

- (AAPLListColor)color {
    return self.list.color;
}

- (AAPLList *)archiveableList {
    return self.list;
}

- (NSArray *)presentedListItems {
    return [self.list items];
}

/*!
    Sets the list that should be presented. Calling \c -setList: on an
    \c AAPLAllListItemsPresenter does not trigger any undo registrations. Calling
    \c -setList: also removes all of the undo actions from the undo manager.
 */
- (void)setList:(AAPLList *)newList {
    /*
        If this is the initial list that's being presented, just tell the delegate
        to reload all of the data.
     */
    if (self.isInitialList) {
        self.initialList = NO;
        
        _list = newList;
        newList.items = [self reorderedListItemsFromListItems:newList.items];
        
        [self.delegate listPresenterDidRefreshCompleteLayout:self];
        
        return;
    }
    
    /**
         Perform more granular changes (if we can). To do this, we'll group the changes into the different
         types of possible changes. If we know that a group of similar changes occured, we'll batch them
         together (e.g. four updates to list items). If multiple changes occur that we can't correctly resolve
         (an implementation detail), we'll refresh the complete layout. An example of this is if more than one
         list item is inserted or toggled. Since this algorithm doesn't track the indexes that list items
         are inserted at, we will just refresh the complete layout to make sure that the list items are presented
         correctly. This applies for multiple groups of changes (e.g. one insert and one toggle), and also for
         any unique group of toggles / inserts where there's more than a single update.
     */
    AAPLList *oldList = self.list;
    
    NSArray *newRemovedListItems = AAPLFindRemovedListItemsFromInitialListItemsToChangedListItems(oldList.items, newList.items);
    NSArray *newInsertedListItems = AAPLFindInsertedListItemsFromInitialListItemsToChangedListItems(oldList.items, newList.items, nil);
    NSArray *newToggledListItems = AAPLFindToggledListItemsFromInitialListItemsToChangedListItems(oldList.items, newList.items);
    NSArray *newListItemsWithUpdatedText = AAPLFindListItemsWithUpdatedTextFromInitialListItemsToChangedListItems(oldList.items, newList.items);
    
    /**
         Determine if there was a unique group of batch changes we can make. Otherwise, we'll
         refresh all the data in the list.
     */
    AAPLListItemsBatchChangeKind listItemsBatchChangeKind = AAPLListItemsBatchChangeKindForChanges(newRemovedListItems, newInsertedListItems, newToggledListItems, newListItemsWithUpdatedText);
    
    if (listItemsBatchChangeKind == AAPLListItemsBatchChangeKindNone) {
        if (oldList.color != newList.color) {
            [self.undoManager removeAllActionsWithTarget:self];
            
            AAPLUpdateListColorForListPresenterIfDifferent(self, self.list, newList.color, AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForInitialLayout);
        }
        
        return;
    }
    
    /**
         Check to see if there was more than one kind of unique group of changes, or if there were multiple toggled /
         inserted list items that we don't handle.
     */
    if (listItemsBatchChangeKind == AAPLListItemsBatchChangeKindMultiple || newToggledListItems.count > 1 || newInsertedListItems.count > 1) {
        [self.undoManager removeAllActionsWithTarget:self];
        
        _list = newList;
        newList.items = [self reorderedListItemsFromListItems:newList.items];
        
        [self.delegate listPresenterDidRefreshCompleteLayout:self];
        
        return;
    }
    
    /**
         At this point we know that we have changes that are uniquely identifiable: e.g. one inserted list item,
         one toggled list item, multiple removed list items, or multiple list items whose text has been updated.
     */
    [self.undoManager removeAllActionsWithTarget:self];
    
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:YES];
    
    // Make the changes based on the unique change kind.
    
    switch (listItemsBatchChangeKind) {
        case AAPLListItemsBatchChangeKindRemoved: {
            NSMutableArray *oldListItemsMutableProxy = [self.list mutableArrayValueForKey:@"items"];

            AAPLRemoveListItemsFromListItemsWithListPresenter(self, oldListItemsMutableProxy, newRemovedListItems);

            break;
        }
        case AAPLListItemsBatchChangeKindInserted: {
            [self unsafeInsertListItem:newInsertedListItems.firstObject];

            break;
        }
        case AAPLListItemsBatchChangeKindToggled: {
            // We want to toggle the *old* list item, not the one that's in newList.
            NSInteger indexOfToggledListItemInOldListItems = [oldList.items indexOfObject:newToggledListItems.firstObject];
            
            AAPLListItem *listItemToToggle = oldList.items[indexOfToggledListItemInOldListItems];
            
            [self unsafeToggleListItem:listItemToToggle];

            break;
        }
        case AAPLListItemsBatchChangeKindUpdatedText: {
            NSMutableArray *oldListItemsMutableProxy = [self.list mutableArrayValueForKey:@"items"];

            AAPLUpdateListItemsWithListItemsForListPresenter(self, oldListItemsMutableProxy, newListItemsWithUpdatedText);

            break;
        }

        default: abort();
    }
    
    AAPLUpdateListColorForListPresenterIfDifferent(self, self.list, newList.color, AAPLListColorUpdateActionDontSendDelegateChangeLayoutCalls);
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:YES];
}

- (NSInteger)count {
    return self.presentedListItems.count;
}

- (BOOL)isEmpty {
    return self.presentedListItems.count == 0;
}

#pragma mark - Public Methods

- (void)insertListItem:(AAPLListItem *)listItem {
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    [self unsafeInsertListItem:listItem];
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
    
    // Undo
    [[self.undoManager prepareWithInvocationTarget:self] removeListItem:listItem];
    
    NSString *undoActionName = NSLocalizedString(@"Remove", nil);
    [self.undoManager setActionName:undoActionName];
}

- (void)insertListItems:(NSArray *)listItems {
    if (listItems.count == 0) {
        return;
    }
    
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    for (AAPLListItem *listItem in listItems) {
        [self unsafeInsertListItem:listItem];
    }
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
    
    // Undo
    [[self.undoManager prepareWithInvocationTarget:self] removeListItems:listItems];
    
    NSString *undoActionName = NSLocalizedString(@"Remove", nil);
    [self.undoManager setActionName:undoActionName];
}

- (void)removeListItem:(AAPLListItem *)listItem {
    NSInteger listItemIndex = [self.presentedListItems indexOfObject:listItem];
    
    NSAssert(listItemIndex != NSNotFound, @"To remove a list item, it must already be in the list.");
    
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    [[self.list mutableArrayValueForKey:@"items"] removeObjectAtIndex:listItemIndex];
    
    [self.delegate listPresenter:self didRemoveListItem:listItem atIndex:listItemIndex];
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
    
    // Undo
    [[self.undoManager prepareWithInvocationTarget:self] insertListItemsForUndo:@[listItem] atIndexes:@[@(listItemIndex)]];
    
    NSString *undoActionName = NSLocalizedString(@"Remove", nil);
    [self.undoManager setActionName:undoActionName];
}

- (void)removeListItems:(NSArray *)listItemsToRemove {
    if (listItemsToRemove.count == 0) {
        return;
    }
    
    NSMutableArray *listItems = [self.list mutableArrayValueForKey:@"items"];

    /** 
        We're going to store the indexes of the list items that will be removed in an array.
        We do that so that when we insert the same list items back in for undo, we don't need
        to worry about insertion order (since it will just be the opposite of insertion order).
    */
    NSMutableArray *removedIndexes = [NSMutableArray array];

    for (AAPLListItem *listItem in listItemsToRemove) {
        NSInteger listItemIndex = [self.presentedListItems indexOfObject:listItem];
        
        NSAssert(listItemIndex != NSNotFound, @"List items to remove must already be in the list.");
        
        [listItems removeObjectAtIndex:listItemIndex];
        
        [self.delegate listPresenter:self didRemoveListItem:listItem atIndex:listItemIndex];
        
        [removedIndexes addObject:@(listItemIndex)];
    }
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];

    // Undo
    NSArray *reverseListItemsToRemove = [[listItemsToRemove reverseObjectEnumerator] allObjects];
    NSArray *reverseRemovedIndexes = [[removedIndexes reverseObjectEnumerator] allObjects];
    [[self.undoManager prepareWithInvocationTarget:self] insertListItemsForUndo:reverseListItemsToRemove atIndexes:reverseRemovedIndexes];
    
    NSString *undoActionName = NSLocalizedString(@"Remove", nil);
    [self.undoManager setActionName:undoActionName];
}

- (void)updateListItem:(AAPLListItem *)listItem withText:(NSString *)newText {
    NSInteger listItemIndex = [self.presentedListItems indexOfObject:listItem];
    
    NSAssert(listItemIndex != NSNotFound, @"A list item can only be updated if it already exists in the list.");
    
    // If the text is the same, it's a no op.
    if ([listItem.text isEqualToString:newText]) {
        return;
    }
    
    NSString *oldText = listItem.text;
    
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    listItem.text = newText;
    
    [self.delegate listPresenter:self didUpdateListItem:listItem atIndex:listItemIndex];
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
    
    // Undo
    [[self.undoManager prepareWithInvocationTarget:self] updateListItem:listItem withText:oldText];
    
    NSString *undoActionName = NSLocalizedString(@"Text Change", nil);
    [self.undoManager setActionName:undoActionName];
}

- (BOOL)canMoveListItem:(AAPLListItem *)listItem toIndex:(NSInteger)toIndex {
    if (![self.presentedListItems containsObject:listItem]) {
        return NO;
    }
    
    NSInteger indexOfFirstCompleteItem = self.indexOfFirstCompleteItem;
    
    if (indexOfFirstCompleteItem != NSNotFound) {
        if (listItem.isComplete) {
            return toIndex >= indexOfFirstCompleteItem && toIndex <= self.count;
        }
        else {
            return toIndex >= 0 && toIndex < indexOfFirstCompleteItem;
        }
    }
    
    return !listItem.isComplete && toIndex >= 0 && toIndex <= self.count;
}

- (void)moveListItem:(AAPLListItem *)listItem toIndex:(NSInteger)toIndex {
    NSAssert([self canMoveListItem:listItem toIndex:toIndex], @"An item can only be moved if it passed a \"can move\" test.");
    
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    NSInteger fromIndex = [self unsafeMoveListItem:listItem toIndex:toIndex];
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
    
    // Undo
    [[self.undoManager prepareWithInvocationTarget:self] moveListItem:listItem toIndex:fromIndex];
    
    NSString *undoActionName = NSLocalizedString(@"Move", nil);
    [self.undoManager setActionName:undoActionName];
}

- (void)toggleListItem:(AAPLListItem *)listItem {
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    NSInteger fromIndex = [self unsafeToggleListItem:listItem];
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
    
    // Undo
    [[self.undoManager prepareWithInvocationTarget:self] toggleListItemForUndo:listItem toPreviousIndex:fromIndex];
    
    NSString *undoActionName = NSLocalizedString(@"Toggle", nil);
    [self.undoManager setActionName:undoActionName];
}

- (void)updatePresentedListItemsToCompletionState:(BOOL)completionState {
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"isComplete != %@", @(completionState)];
    
    NSArray *presentedListItemsNotMatchingCompletionState = [self.presentedListItems filteredArrayUsingPredicate:filterPredicate];
    
    // If there are no list items that match the completion state, it's a no op.
    if (presentedListItemsNotMatchingCompletionState.count == 0) {
        return;
    }
    
    NSString *undoActionName = completionState ? NSLocalizedString(@"Complete All", nil) : NSLocalizedString(@"Incomplete All", nil);
    [self toggleListItemsWithoutMoving:presentedListItemsNotMatchingCompletionState undoActionName:undoActionName];
}

#pragma mark - Undo Helper Methods

- (void)toggleListItemForUndo:(AAPLListItem *)listItem toPreviousIndex:(NSInteger)previousIndex {
    NSAssert([self.presentedListItems containsObject:listItem], @"The list item should already be in the list if it's going to be toggled.");
    
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    // Move the list item.
    NSInteger fromIndex = [self unsafeMoveListItem:listItem toIndex:previousIndex];
    
    // Update the list item's state.
    listItem.complete = !listItem.isComplete;
    
    [self.delegate listPresenter:self didUpdateListItem:listItem atIndex:previousIndex];
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
    
    // Undo
    [[self.undoManager prepareWithInvocationTarget:self] toggleListItemForUndo:listItem toPreviousIndex:fromIndex];
    
    NSString *undoActionName = NSLocalizedString(@"Toggle", nil);
    [self.undoManager setActionName:undoActionName];
}

- (void)insertListItemsForUndo:(NSArray *)listItemsToInsert atIndexes:(NSArray *)indexes {
    NSAssert(listItemsToInsert.count == indexes.count, @"`listItems` must have as many elements as `indexes`.");
    
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    NSMutableArray *listItems = [self.list mutableArrayValueForKey:@"items"];
    
    [listItemsToInsert enumerateObjectsUsingBlock:^(AAPLListItem *listItemToInsert, NSUInteger idx, BOOL *stop) {
        // Get the index that we need to insert `listItem` into.
        NSInteger insertionIndex = [indexes[idx] integerValue];
        
        [listItems insertObject:listItemToInsert atIndex:insertionIndex];
        
        [self.delegate listPresenter:self didInsertListItem:listItemToInsert atIndex:insertionIndex];
    }];
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
    
    // Undo
    [[self.undoManager prepareWithInvocationTarget:self] removeListItems:listItemsToInsert];
    
    NSString *undoActionName = NSLocalizedString(@"Remove", nil);
    [self.undoManager setActionName:undoActionName];
}

- (void)toggleListItemsWithoutMoving:(NSArray *)listItems undoActionName:(NSString *)undoActionName {
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    for (AAPLListItem *listItem in listItems) {
        listItem.complete = !listItem.isComplete;
        
        NSInteger updatedIndex = [self.presentedListItems indexOfObject:listItem];
        
        [self.delegate listPresenter:self didUpdateListItem:listItem atIndex:updatedIndex];
    }
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
    
    // Undo
    [[self.undoManager prepareWithInvocationTarget:self] toggleListItemsWithoutMoving:listItems undoActionName:undoActionName];
    
    [self.undoManager setActionName:undoActionName];
}

#pragma mark - Unsafe Updating Methods

- (void)unsafeInsertListItem:(AAPLListItem *)listItem {
    NSAssert(![self.presentedListItems containsObject:listItem], @"A list item was requested to be added that is already in the list.");
    
    NSInteger indexToInsertListItem = listItem.isComplete ? self.count : 0;
    
    [[self.list mutableArrayValueForKey:@"items"] insertObject:listItem atIndex:indexToInsertListItem];
    
    [self.delegate listPresenter:self didInsertListItem:listItem atIndex:indexToInsertListItem];
}

- (NSInteger)unsafeMoveListItem:(AAPLListItem *)listItem toIndex:(NSInteger)toIndex {
    NSInteger fromIndex = [self.presentedListItems indexOfObject:listItem];
    
    NSAssert(fromIndex != NSNotFound, @"A list item can only be moved if it already exists in the presented list items.");
    
    NSMutableArray *listItems = [self.list mutableArrayValueForKey:@"items"];
    
    [listItems removeObjectAtIndex:fromIndex];
    [listItems insertObject:listItem atIndex:toIndex];
    
    [self.delegate listPresenter:self didMoveListItem:listItem fromIndex:fromIndex toIndex:toIndex];

    return fromIndex;
}

- (NSInteger)unsafeToggleListItem:(AAPLListItem *)listItem {
    NSAssert([self.presentedListItems containsObject:listItem], @"A list item can only be toggled if it already exists in the list.");
    
    // Move the list item.
    NSInteger targetIndex = listItem.isComplete ? 0 : self.count - 1;
    NSInteger fromIndex = [self unsafeMoveListItem:listItem toIndex:targetIndex];
    
    // Update the list item's state.
    listItem.complete = !listItem.isComplete;
    [self.delegate listPresenter:self didUpdateListItem:listItem atIndex:targetIndex];
    
    return fromIndex;
}

#pragma mark - Private Convenience Methods

- (NSInteger)indexOfFirstCompleteItem {
    return [self.presentedListItems indexOfObjectPassingTest:^BOOL(AAPLListItem *listItem, NSUInteger idx, BOOL *stop) {
        return listItem.isComplete;
    }];
}

- (NSArray *)reorderedListItemsFromListItems:(NSArray *)listItems {
    NSPredicate *incompleteListItemsPredicate = [NSPredicate predicateWithFormat:@"isComplete = NO"];
    NSPredicate *completeListItemsPredicate = [NSPredicate predicateWithFormat:@"isComplete = YES"];
    
    NSArray *incompleteListItems = [listItems filteredArrayUsingPredicate:incompleteListItemsPredicate];
    NSArray *completeListItems = [listItems filteredArrayUsingPredicate:completeListItemsPredicate];
    
    return [incompleteListItems arrayByAddingObjectsFromArray:completeListItems];
}

@end

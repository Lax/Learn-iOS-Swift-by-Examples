/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The implementation for the \c AAPLIncompleteListItemsPresenter type. This class is responsible for managing how a list is presented in the iOS and OS X app Today widgets, as well as the Lister WatchKit application.
*/

#import "AAPLIncompleteListItemsPresenter.h"
#import "AAPLListPresenterDelegate.h"
#import "AAPLListPresenterUtilities.h"
#import "AAPLListPresenterAlgorithms.h"
#import "AAPLListItem.h"

@interface AAPLIncompleteListItemsPresenter ()

/// The internal storage for the list that we're presenting. By default, it's an empty list.
@property (nonatomic, readwrite) AAPLList *list;

/// Flag to see whether or not the first \c -setList: call should trigger a batch reload.
@property (getter=isInitialList) BOOL initialList;

/*!
 * A cached array of the list items that should be presented. When the presenter initially has its underlying \c list
 * set, the \c presentedListItems is set to all of the incomplete list items. As list items are toggled, \c presentedListItems
 * may not only contain incomplete list items. Note that we've named the property \c presentedListItems since
 * there's already a readonly \c presentedListItems property (which returns the value of \c presentedListItems).
 */
@property (readwrite, copy) NSArray *presentedListItems;

@end

@implementation AAPLIncompleteListItemsPresenter
@synthesize delegate = _delegate;
@dynamic color;

#pragma mark - AAPLListItemPresenter

- (instancetype)init {
    self = [super init];

    if (self) {
        // Use a default, empty list.
        _list = [[AAPLList alloc] initWithColor:AAPLListColorGray items:@[]];
        _initialList = YES;
        
        _presentedListItems = [NSArray array];
    }
    
    return self;
}

- (void)setColor:(AAPLListColor)color {
    AAPLUpdateListColorForListPresenterIfDifferent(self, self.list, color, AAPLListColorUpdateActionSendDelegateChangeLayoutCallsForNonInitialLayout);
}

- (AAPLListColor)color {
    return self.list.color;
}

- (AAPLList *)archiveableList {
    return self.list;
}

/*!
 * This methods determines the diff betwen the current list and the new list provided and notifies the delegate
 * accordingly. The delegate will be notified of all changes except for reordering list items (an implementation
 * detail). If the list is the initial list to be presented, we just reload all of the data.
 */
- (void)setList:(AAPLList *)newList {
    // If this is the initial list that's being presented, just tell the delegate to reload all of the data.
    if (self.isInitialList) {
        self.initialList = NO;
        
        _list = newList;
        
        NSPredicate *incompleteListItemsFilterPredicate = [NSPredicate predicateWithFormat:@"isComplete == NO"];
        self.presentedListItems = [newList.items filteredArrayUsingPredicate:incompleteListItemsFilterPredicate];
        
        [self.delegate listPresenterDidRefreshCompleteLayout:self];
        
        return;
    }
    
    /**
        First find all the differences between the lists that we want to reflect in the presentation
        of the list: removed list items that were incomplete, inserted list items that are incomplete, presented list items
        that are toggled, and presented list items whose text has changed. Note that although we'll gradually
        update presentedListItems to reflect the changes we find, we also want to save the latest state of
        the list (i.e. the `newList` parameter) as the underlying storage of the list. Since we'll be presenting
        the same list either way, it's better not to change the underlying list representation unless we need
        to. Keep in mind, however, that all of the list items in presentedListItems should also be in `list.items`.
        In short, once we modify `presentedListItems` with all of the changes, we need to also update `list.items`
        to contain all of the list items that were unchanged (this can be done by replacing the new list item
        representation by the old representation of the list item). Once that happens, all of the presentation
        logic carries on as normal.
     */
    AAPLList *oldList = self.list;
    
    NSArray *newRemovedPresentedListItems = AAPLFindRemovedListItemsFromInitialListItemsToChangedListItems(self.presentedListItems, newList.items);
    NSArray *newInsertedIncompleteListItems = AAPLFindInsertedListItemsFromInitialListItemsToChangedListItems(self.presentedListItems, newList.items, ^BOOL(AAPLListItem *listItem) {
        return !listItem.isComplete;
    });
    NSArray *newPresentedToggledListItems = AAPLFindToggledListItemsFromInitialListItemsToChangedListItems(self.presentedListItems, newList.items);
    NSArray *newPresentedListItemsWithUpdatedText = AAPLFindListItemsWithUpdatedTextFromInitialListItemsToChangedListItems(self.presentedListItems, newList.items);
    
    AAPLListItemsBatchChangeKind listItemsBatchChangeKind = AAPLListItemsBatchChangeKindForChanges(newRemovedPresentedListItems, newInsertedIncompleteListItems, newPresentedToggledListItems, newPresentedListItemsWithUpdatedText);
    
    // If no changes occured we'll ignore the update.
    if (listItemsBatchChangeKind == AAPLListItemsBatchChangeKindNone && oldList.color == newList.color) {
        return;
    }
    
    // Start performing changes to the presentation of the list.
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:YES];
    
    NSMutableArray *presentedListItemsProxy = [self mutableArrayValueForKey:@"presentedListItems"];

    // Remove the list items from the presented list items that were removed somewhere else.
    if (newRemovedPresentedListItems.count > 0) {
        AAPLRemoveListItemsFromListItemsWithListPresenter(self, presentedListItemsProxy, newRemovedPresentedListItems);
    }
    
    // Insert the incomplete list items into the presented list items that were inserted elsewhere.
    if (newInsertedIncompleteListItems.count > 0) {
        AAPLInsertListItemsIntoListItemsWithListPresenter(self, presentedListItemsProxy, newInsertedIncompleteListItems);
    }
    
    /**
        For all of the list items whose content has changed elsewhere, we need to update the list items in place.
        Since the `AAPLIncompleteListItemsPresenter` keeps toggled list items in place, we only need to perform one
        update for list items that have a different completion state and text. We'll batch both of these changes
        into a single update.
     */
    if (newPresentedToggledListItems.count > 0 || newPresentedListItemsWithUpdatedText.count > 0) {
        // Find the unique list of list items that are updated.
        NSMutableSet *uniqueUpdatedListItemsSet = [NSMutableSet setWithArray:newPresentedToggledListItems];
        [uniqueUpdatedListItemsSet addObjectsFromArray:newPresentedListItemsWithUpdatedText];
        
        AAPLUpdateListItemsWithListItemsForListPresenter(self, presentedListItemsProxy, uniqueUpdatedListItemsSet.allObjects);
    }
    
    /**
        At this point the presented list items have been updated. As mentioned before, to ensure that we're
        consistent about how we persist the updated list, we'll just use new the new list as the underlying
        model. To do that we'll need to update the new list's unchanged list items with the list items that
        are stored in the visual list items. i.e. We need to make sure that any references to list items in 
        `presentedListItems` are reflected in the new list's items.
     */
    _list = newList;

    // Obtain the presented list items that were unchanged. We need to update the new list to reference the old list items.
    NSPredicate *unboundFindUnchangedPresentedListItemsPredicate = [NSPredicate predicateWithFormat:@"!(self in $newRemovedPresentedListItems) && !(self in $newInsertedIncompleteListItems) && !(self in $newPresentedToggledListItems) && !(self in $newPresentedListItemsWithUpdatedText)"];

    NSPredicate *findUnchangedPresentedListItemsPredicate = [unboundFindUnchangedPresentedListItemsPredicate predicateWithSubstitutionVariables:@{
        @"newRemovedPresentedListItems": newRemovedPresentedListItems,
        @"newInsertedIncompleteListItems": newInsertedIncompleteListItems,
        @"newPresentedToggledListItems": newPresentedToggledListItems,
        @"newPresentedListItemsWithUpdatedText": newPresentedListItemsWithUpdatedText
    }];
    
    NSArray *unchangedPresentedListItems = [self.presentedListItems filteredArrayUsingPredicate:findUnchangedPresentedListItemsPredicate];

    NSMutableArray *listItemsProxy = [self.list mutableArrayValueForKey:@"items"];
    
    AAPLReplaceAnyEqualUnchangedNewListItemsWithPreviousUnchangedListItems(listItemsProxy, unchangedPresentedListItems);
    
    /**
        Even though the old list's color will change if there's a difference between the old list's color and
        the new list's color, the delegate only cares about this change in reference to what it already knows.
        Because the delegate hasn't seen a color change yet, the update (if it happens) is ok.
    */
    AAPLUpdateListColorForListPresenterIfDifferent(self, oldList, newList.color, AAPLListColorUpdateActionDontSendDelegateChangeLayoutCalls);
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:YES];
}

- (NSInteger)count {
    return self.presentedListItems.count;
}

- (BOOL)isEmpty {
    return self.presentedListItems.count == 0;
}

#pragma mark - Public Methods

- (void)toggleListItem:(AAPLListItem *)listItem {
    NSAssert([self.presentedListItems containsObject:listItem], @"The list item must already be in the presented list items.");
    
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];
    
    listItem.complete = !listItem.isComplete;
    
    NSInteger currentIndex = [self.presentedListItems indexOfObject:listItem];
    
    [self.delegate listPresenter:self didUpdateListItem:listItem atIndex:currentIndex];
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
}

- (void)updatePresentedListItemsToCompletionState:(BOOL)completionState {
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"isComplete != %@", @(completionState)];
    NSArray *presentedListItemsNotMatchingCompletionState = [self.presentedListItems filteredArrayUsingPredicate:filterPredicate];

    // If there are no list items that match the completion state, it's a no op.
    if (presentedListItemsNotMatchingCompletionState.count == 0) {
        return;
    }
    
    [self.delegate listPresenterWillChangeListLayout:self isInitialLayout:NO];

    for (AAPLListItem *listItem in presentedListItemsNotMatchingCompletionState) {
        listItem.complete = !listItem.isComplete;
        
        NSInteger indexOfListItem = [self.presentedListItems indexOfObject:listItem];
        
        [self.delegate listPresenter:self didUpdateListItem:listItem atIndex:indexOfListItem];
    }
    
    [self.delegate listPresenterDidChangeListLayout:self isInitialLayout:NO];
}

@end

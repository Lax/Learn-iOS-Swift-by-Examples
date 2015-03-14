/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The test case class for the \c AAPLAllListItemsPresenter class.
*/

@import ListerKit;
@import XCTest;

#import "AAPLListPresenterTestHelper.h"

@interface AAPLAllListItemsPresenterTests : XCTestCase

@property AAPLAllListItemsPresenter *presenter;

@property AAPLList *list;

@property (copy) NSArray *initiallyIncompleteListItems;

@property (copy) NSArray *initiallyCompleteListItems;

@property (copy) NSArray *presentedListItems;

@property NSInteger initialListItemCount;

@property AAPLListPresenterTestHelper *testHelper;

@property (readonly) NSUndoManager *undoManager;

@end


@implementation AAPLAllListItemsPresenterTests

#pragma mark - XCTest Life Time

- (void)setUp {
    [super setUp];
    
    self.initiallyIncompleteListItems = @[
        [[AAPLListItem alloc] initWithText:@"1" complete: NO],
        [[AAPLListItem alloc] initWithText:@"3" complete: NO]
    ];
    
    self.initiallyCompleteListItems = @[
        [[AAPLListItem alloc] initWithText:@"0" complete:YES],
        [[AAPLListItem alloc] initWithText:@"2" complete:YES],
        [[AAPLListItem alloc] initWithText:@"4" complete:YES]
    ];
    
    self.presentedListItems = [self.initiallyIncompleteListItems arrayByAddingObjectsFromArray:self.initiallyCompleteListItems];
    
    NSArray *unorderedListItems = @[
        self.initiallyCompleteListItems[0],
        self.initiallyIncompleteListItems[0],
        self.initiallyCompleteListItems[1],
        self.initiallyIncompleteListItems[1],
        self.initiallyCompleteListItems[2]
    ];
    
    self.list = [[AAPLList alloc] initWithColor:AAPLListColorGreen items:unorderedListItems];
    
    // Create the presenter.
    self.presenter = [[AAPLAllListItemsPresenter alloc] init];
    
    [self.presenter setList:self.list];
    
    self.initialListItemCount = self.presenter.count;
    
    self.presenter.undoManager = [[NSUndoManager alloc] init];
    
    self.testHelper = [[AAPLListPresenterTestHelper alloc] init];
    
    self.presenter.delegate = self.testHelper;
}

#pragma mark - Property Accessors

- (NSUndoManager *)undoManager {
    return self.presenter.undoManager;
}

#pragma mark - Test Initializers

- (void)testItemInitializationReshufflingWithOutOfOrderItems {
    XCTAssertEqualObjects(self.presenter.presentedListItems, self.presentedListItems, @"Incomplete items should be followed by complete items once the presenter is instantiated.");
}

- (void)testItemInitializationNoReshufflingCaseWhenItemsAreAlreadyInOrder {
    NSMutableArray *incompleteListItems = [NSMutableArray array];
    NSMutableArray *completeListItems = [NSMutableArray array];
    
    for (NSInteger idx = 0; idx < 5; idx++) {
        NSString *text = [NSString stringWithFormat:@"%ld", idx];
        
        AAPLListItem *incompleteListItem = [[AAPLListItem alloc] initWithText:text complete:NO];
        [incompleteListItems addObject:incompleteListItem];
        
        AAPLListItem *completeListItem = [[AAPLListItem alloc] initWithText:text complete:YES];
        [completeListItems addObject:completeListItem];
    }
    
    AAPLList *incompleteList = [[AAPLList alloc] initWithColor:AAPLListColorGreen items:incompleteListItems];
    AAPLAllListItemsPresenter *incompletePresenter = [[AAPLAllListItemsPresenter alloc] init];
    [incompletePresenter setList:incompleteList];
    
    AAPLList *completeList = [[AAPLList alloc] initWithColor:AAPLListColorGreen items:completeListItems];
    AAPLAllListItemsPresenter *completePresenter = [[AAPLAllListItemsPresenter alloc] init];
    [completePresenter setList:completeList];
    
    NSArray *orderedCombinedListItems = [incompleteListItems arrayByAddingObjectsFromArray:completeListItems];
    AAPLList *orderedCombinedList = [[AAPLList alloc] initWithColor:AAPLListColorGreen items:orderedCombinedListItems];
    AAPLAllListItemsPresenter *orderedCombinedPresenter = [[AAPLAllListItemsPresenter alloc] init];
    [orderedCombinedPresenter setList:orderedCombinedList];
    
    XCTAssertEqualObjects(incompleteListItems, incompletePresenter.presentedListItems, @"Items that are all incomplete should not be reconfigured after the presenter is instantiated.");
    
    XCTAssertEqualObjects(completeListItems, completePresenter.presentedListItems, @"Items that are all complete should not be reconfigured after the presenter is instantiated.");
    
    XCTAssertEqualObjects(orderedCombinedListItems, orderedCombinedPresenter.presentedListItems, @"Incomplete items followed by complete items should not be reconfigured after the presenter is instantiated.");
}

#pragma mark - color

- (void)testSetColorWithDifferentColor {
    AAPLListColor newColor = AAPLListColorOrange;
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        XCTAssertEqual(self.presenter.color, newColor, @"The getter for the color should return the new color.");
        
        NSInteger didUpdateListColorCallbackCount = self.testHelper.didUpdateListColorCallbacks.count;
        
        XCTAssertEqual(didUpdateListColorCallbackCount, 1, @"There should be one \"list color update\" callback.");

        if (didUpdateListColorCallbackCount != 1) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *updateColorInfo = self.testHelper.didUpdateListColorCallbacks.firstObject;
        XCTAssertEqual(updateColorInfo.color, newColor, @"The delegate callback should provide the new color.");
    }];

    self.presenter.color = newColor;
}

- (void)testSetColorWithDifferentColorAfterUndo {
    AAPLListColor initialListColor = self.presenter.color;
    
    self.presenter.color = AAPLListColorOrange;
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        XCTAssertEqual(self.presenter.color, initialListColor, @"The getter for the color should return the initial color.");

        NSInteger didUpdateListColorCallbackCount = self.testHelper.didUpdateListColorCallbacks.count;
        XCTAssertEqual(didUpdateListColorCallbackCount, 1, @"There should be one \"list color update\" callback.");

        if (didUpdateListColorCallbackCount != 1) {
            return;
        }

        AAPLListPresenterCallbackInfo *newColorInfo = self.testHelper.didUpdateListColorCallbacks.firstObject;
        XCTAssertEqual(newColorInfo.color, initialListColor, @"The delegate callback should provide the initial color.");
    }];
    
    [self.undoManager undo];
}

#pragma mark - -insertListItem:

- (void)testInsertIncompleteListItem {
    AAPLListItem *incompleteListItem = [[AAPLListItem alloc] initWithText:@"foo" complete: NO];

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSInteger didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count;

        XCTAssertEqual(didInsertListItemCallbackCount, 1, @"Only one item should be inserted.");

        if (didInsertListItemCallbackCount != 1) {
            return;
        }

        AAPLListPresenterCallbackInfo *insertInfo = self.testHelper.didInsertListItemCallbacks.firstObject;

        XCTAssertEqualObjects(incompleteListItem, insertInfo.listItem, @"The inserted item should be the same as the item the delegate receives.");

        XCTAssertEqual(insertInfo.index, 0, @"The incomplete item should be inserted at the top of the list.");
    }];

    [self.presenter insertListItem:incompleteListItem];
}

- (void)testInsertCompleteListItem {
    AAPLListItem *completeListItem = [[AAPLListItem alloc] initWithText:@"foo" complete:YES];

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSInteger didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count;
        
        XCTAssertEqual(didInsertListItemCallbackCount, 1, "Only one item should be inserted.");
        
        if (didInsertListItemCallbackCount != 1) {
            return;
        }

        AAPLListPresenterCallbackInfo *insertInfo = self.testHelper.didInsertListItemCallbacks.firstObject;
        
        XCTAssertEqualObjects(completeListItem, insertInfo.listItem, @"The inserted item should be the same as the item the delegate receives.");
        
        XCTAssertEqual(insertInfo.index, self.initialListItemCount, @"The complete item should be inserted at the bottom of the list.");
    }];
    
    [self.presenter insertListItem:completeListItem];
}

- (void)testInsertListItemAfterUndo {
    AAPLListItem *listItemToInsert = [[AAPLListItem alloc] initWithText:@"foo" complete:NO];

    [self.presenter insertListItem:listItemToInsert];

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Make sure the underlying list is back to its initial state.
        XCTAssertEqualObjects(self.presentedListItems, self.presenter.presentedListItems, @"The list should be the same after a change + undo.");
        
        NSInteger didRemoveListItemCallbackCount = self.testHelper.didRemoveListItemCallbacks.count;
        
        XCTAssertEqual(didRemoveListItemCallbackCount, 1, @"Only one item should be removed.");
        
        if (didRemoveListItemCallbackCount != 1) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *removeInfo = self.testHelper.didRemoveListItemCallbacks.firstObject;
        
        XCTAssertEqualObjects(removeInfo.listItem, listItemToInsert, @"The removed item should be the item we initially inserted.");
    }];

    [self.undoManager undo];
}

#pragma mark - -insertListItems:

- (void)testInsertListItems {
    NSArray *listItemsToInsert = @[
        [[AAPLListItem alloc] initWithText:@"0" complete:NO],
        [[AAPLListItem alloc] initWithText:@"1" complete:YES],
        [[AAPLListItem alloc] initWithText:@"2" complete:NO]
    ];

    NSDictionary *listItemsToInsertWithExpectedInsertedIndexes = @{
        listItemsToInsert[0]: @0,
        listItemsToInsert[1]: @(self.initialListItemCount + 1),
        listItemsToInsert[2]: @0
    };

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSInteger didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count;
        
        XCTAssertEqual(didInsertListItemCallbackCount, listItemsToInsert.count, @"Only one item should be inserted.");
        
        if (didInsertListItemCallbackCount != listItemsToInsert.count) {
            return;
        }
        
        for (AAPLListPresenterCallbackInfo *insertInfo in self.testHelper.didInsertListItemCallbacks) {
            XCTAssertTrue([listItemsToInsert containsObject:insertInfo.listItem], @"The inserted item should be one of the items we wanted to insert.");
            
            NSNumber *expectedInsertedIndexNumber = listItemsToInsertWithExpectedInsertedIndexes[insertInfo.listItem];
            if (expectedInsertedIndexNumber != nil) {
                XCTAssertEqual(expectedInsertedIndexNumber.integerValue, insertInfo.index, @"The items should be inserted at the expected indexes.");
            }
        }
    }];

    [self.presenter insertListItems:listItemsToInsert];
}

- (void)testInsertListItemsAfterUndo {
    NSArray *listItemsToInsert = @[
        [[AAPLListItem alloc] initWithText:@"0" complete:NO],
        [[AAPLListItem alloc] initWithText:@"1" complete:YES],
        [[AAPLListItem alloc] initWithText:@"2" complete:NO]
    ];

    [self.presenter insertListItems:listItemsToInsert];
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Make sure the underlying list is back to its initial state.
        XCTAssertEqualObjects(self.presentedListItems, self.presenter.presentedListItems, @"The list should be the same after a change + undo.");
        
        NSInteger didRemoveListItemCallbackCount = self.testHelper.didRemoveListItemCallbacks.count;
        
        XCTAssertEqual(didRemoveListItemCallbackCount, listItemsToInsert.count, @"Only one item should be removed.");
        
        if (didRemoveListItemCallbackCount != listItemsToInsert.count) {
            return;
        }

        for (AAPLListPresenterCallbackInfo *removeInfo in self.testHelper.didRemoveListItemCallbacks) {
            XCTAssertTrue([listItemsToInsert containsObject:removeInfo.listItem], @"The removed item should one of the items we initially inserted.");
        }
    }];
    
    [self.undoManager undo];
}

#pragma mark - -removeListItem:

- (void)testRemoveListItem {
    AAPLListItem *listItemToRemove = self.presentedListItems[2];
    NSInteger indexOfItemToRemove = [self.presenter.presentedListItems indexOfObject:listItemToRemove];
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSInteger didRemoveListItemCallbackCount = self.testHelper.didRemoveListItemCallbacks.count;
        XCTAssertEqual(didRemoveListItemCallbackCount, 1, @"Only one item should be removed.");

        if (didRemoveListItemCallbackCount != 1) {
            return;
        }

        AAPLListPresenterCallbackInfo *removeInfo = self.testHelper.didRemoveListItemCallbacks.firstObject;

        XCTAssertEqualObjects(listItemToRemove, removeInfo.listItem, @"The removed item should be the same as the item the delegate receives.");

        XCTAssertEqual(removeInfo.index, indexOfItemToRemove, @"The incomplete item should be removed at the index it was before removal.");
    }];

    [self.presenter removeListItem:listItemToRemove];
}

- (void)testRemoveListItemAfterUndo {
    AAPLListItem *listItemToRemove = self.presentedListItems[2];
    
    NSInteger indexOfItemToRemove = [self.presenter.presentedListItems indexOfObject:listItemToRemove];
    
    [self.presenter removeListItem:listItemToRemove];
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Make sure the underlying list is back to its initial state.
        XCTAssertEqualObjects(self.presentedListItems, self.presenter.presentedListItems, @"The list should be the same after a change + undo.");
        
        NSInteger didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count;
        
        XCTAssertEqual(didInsertListItemCallbackCount, 1, @"Only one item should be inserted.");
        
        if (didInsertListItemCallbackCount != 1) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *insertInfo = self.testHelper.didInsertListItemCallbacks.firstObject;
        
        XCTAssertEqualObjects(insertInfo.listItem, listItemToRemove, @"The inserted item should be the item we initially removed.");
        
        XCTAssertEqual(insertInfo.index, indexOfItemToRemove, "The inserted index should be the same as the list item's initial index.");
    }];
    
    [self.undoManager undo];
}

#pragma mark - -removeListItems:

- (void)testRemoveListItems {
    NSArray *listItemsToRemove = @[
        self.presentedListItems[0],
        self.presentedListItems[3],
        self.presentedListItems[2]
    ];
    
    NSDictionary *listItemsToRemoveWithExpectedRemovedIndex = @{
        listItemsToRemove[0]: @0,
        listItemsToRemove[1]: @2,
        listItemsToRemove[2]: @1
    };
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSInteger didRemoveListItemsCallbackCount = self.testHelper.didRemoveListItemCallbacks.count;

        XCTAssertEqual(didRemoveListItemsCallbackCount, listItemsToRemove.count, @"There should be \(listItemsToRemove.count) elements removed.");

        if (didRemoveListItemsCallbackCount != listItemsToRemove.count) {
            return;
        }
        
        for (AAPLListPresenterCallbackInfo *removeInfo in self.testHelper.didRemoveListItemCallbacks) {
            XCTAssertTrue([listItemsToRemove containsObject:removeInfo.listItem], @"The removed item should be one of the items we wanted to remove.");
            
            NSNumber *expectedRemovedIndexNumber = listItemsToRemoveWithExpectedRemovedIndex[removeInfo.listItem];
            if (expectedRemovedIndexNumber != nil) {
                XCTAssertEqual(removeInfo.index, expectedRemovedIndexNumber.integerValue, @"The items should be removed at the expected indexes.");
            }
        }
    }];

    [self.presenter removeListItems:listItemsToRemove];
}

#pragma mark - -removeListItems:

- (void)testRemoveListItemsAfterUndo {
    NSArray *listItemsToRemove = @[
        self.presentedListItems[0],
        self.presentedListItems[3],
        self.presentedListItems[2]
    ];

    [self.presenter removeListItems:listItemsToRemove];
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Make sure the underlying list is back to its initial state.
        XCTAssertEqualObjects(self.presentedListItems, self.presenter.presentedListItems, @"The list should be the same after a change + undo.");
        
        NSInteger didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count;
        
        XCTAssertEqual(didInsertListItemCallbackCount, listItemsToRemove.count, @"Only one item should be inserted.");
        
        if (didInsertListItemCallbackCount != listItemsToRemove.count) {
            return;
        }
        
        for (AAPLListPresenterCallbackInfo *removeInfo in self.testHelper.didRemoveListItemCallbacks) {
            XCTAssertTrue([listItemsToRemove containsObject:removeInfo.listItem], @"The inserted item should one of the items we initially removed.");
        }
    }];

    [self.undoManager undo];
}

#pragma mark - -canMoveListItem:toIndex:

- (void)testCanMoveIncompleteListItem {
    AAPLListItem *incompleteListItem = self.presentedListItems[1];

    BOOL canMoveWithinIncomplete = [self.presenter canMoveListItem:incompleteListItem toIndex:0];
    BOOL canMoveToComplete = [self.presenter canMoveListItem:incompleteListItem toIndex:4];
    BOOL canMoveToBoundary = [self.presenter canMoveListItem:incompleteListItem toIndex:2];

    XCTAssertTrue(canMoveWithinIncomplete, @"An incomplete item can move within the incomplete items.");
    XCTAssertFalse(canMoveToComplete, @"An incomplete item cannot move to the complete items.");
    XCTAssertFalse(canMoveToBoundary, "An incomplete item cannot move to the complete side of the boundary between complete and incomplete.");
}

- (void)testCanMoveCompleteListItem {
    AAPLListItem *completeListItem = self.presentedListItems[4];

    BOOL canMoveWithinComplete = [self.presenter canMoveListItem:completeListItem toIndex:3];
    BOOL canMoveToIncomplete = [self.presenter canMoveListItem:completeListItem toIndex:0];
    BOOL canMoveToBoundary = [self.presenter canMoveListItem:completeListItem toIndex:1];

    XCTAssertTrue(canMoveWithinComplete, @"A complete item can move within the complete items.");
    XCTAssertFalse(canMoveToIncomplete, @"A complete item cannot move to the incomplete items.");
    XCTAssertFalse(canMoveToBoundary, "A complete item cannot move to the incomplete side of the boundary between complete and incomplete.");
}

#pragma mark - -moveListItem:toIndex:

- (void)testMoveListItemAboveListItem {
    NSInteger listItemToRemoveIndex = 1;
    NSInteger listItemDestinationIndex = 0;
    AAPLListItem *listItemToRemove = self.presentedListItems[listItemToRemoveIndex];

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSInteger didMoveListItemsCallbackCount = self.testHelper.didMoveListItemCallbacks.count;
        
        XCTAssertEqual(didMoveListItemsCallbackCount, 1, @"There should one elements moved.");
        
        AAPLListPresenterCallbackInfo *moveInfo = self.testHelper.didMoveListItemCallbacks.firstObject;
        
        XCTAssertEqualObjects(moveInfo.listItem, listItemToRemove, @"The moved item should be the item we wanted to move.");
        
        XCTAssertEqual(moveInfo.fromIndex, listItemToRemoveIndex, @"The item should be moved at the item's initial index.");
        
        XCTAssertEqual(moveInfo.toIndex, listItemDestinationIndex, @"The item should be moved to the destination index.");
    }];

    [self.presenter moveListItem:listItemToRemove toIndex:listItemDestinationIndex];
}

- (void)testMoveListItemAboveListItemAfterUndo {
    NSInteger listItemToRemoveIndex = 1;
    NSInteger listItemDestinationIndex = 0;
    AAPLListItem *listItemToRemove = self.presentedListItems[listItemToRemoveIndex];

    [self.presenter moveListItem:listItemToRemove toIndex:listItemDestinationIndex];

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Make sure the underlying list is back to its initial state.
        XCTAssertEqualObjects(self.presentedListItems, self.presenter.presentedListItems, @"The list should be the same after a change + undo.");
        
        NSInteger didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count;
        
        XCTAssertEqual(didMoveListItemCallbackCount, 1, @"One move should occur the undo.");
        
        if (didMoveListItemCallbackCount != 2) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *moveInfo = self.testHelper.didMoveListItemCallbacks[1];
        
        XCTAssertEqualObjects(moveInfo.listItem, listItemToRemove, @"The moved item should be the item we initially moved.");
        
        XCTAssertEqual(moveInfo.fromIndex, listItemDestinationIndex, @"`fromIndex` should be the same as the list item's initial destination index.");

        XCTAssertEqual(moveInfo.toIndex, listItemToRemoveIndex + 1, @"`toIndex` should be the same as the list item's initial index.");
    }];
    
    [self.undoManager undo];
}

- (void)testMoveListItemBelowListItem {
    NSInteger listItemToMoveIndex = 3;
    NSInteger listItemDestinationIndex = 4;
    AAPLListItem *listItemToMove = self.presentedListItems[listItemToMoveIndex];

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSInteger didMoveListItemsCallbackCount = self.testHelper.didMoveListItemCallbacks.count;
        
        XCTAssertEqual(didMoveListItemsCallbackCount, 1, @"There should one elements moved.");
        
        AAPLListPresenterCallbackInfo *moveInfo = self.testHelper.didMoveListItemCallbacks.firstObject;
        
        XCTAssertEqual(moveInfo.listItem, listItemToMove, @"The moved item should be the item we wanted to move.");
        
        XCTAssertEqual(moveInfo.fromIndex, listItemToMoveIndex, @"The item should be moved at the item's initial index.");
        
        XCTAssertEqual(moveInfo.toIndex, listItemDestinationIndex, @"The item should be moved to the destination index.");
    }];

    [self.presenter moveListItem:listItemToMove toIndex:listItemDestinationIndex];
}

- (void)testMoveListItemBelowListItemAfterUndo {
    NSInteger listItemToRemoveIndex = 3;
    NSInteger listItemDestinationIndex = 4;
    AAPLListItem *listItemToRemove = self.presentedListItems[listItemToRemoveIndex];

    [self.presenter moveListItem:listItemToRemove toIndex:listItemDestinationIndex];
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Make sure the underlying list is back to its initial state.
        XCTAssertEqualObjects(self.presentedListItems, self.presenter.presentedListItems, @"The list should be the same after a change + undo.");

        NSInteger didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count;

        XCTAssertEqual(didMoveListItemCallbackCount, 1, @"One move should occur after the undo.");

        if (didMoveListItemCallbackCount != 1) {
            return;
        }

        AAPLListPresenterCallbackInfo *moveInfo = self.testHelper.didMoveListItemCallbacks.firstObject;

        XCTAssertEqualObjects(moveInfo.listItem, listItemToRemove, @"The moved item should be the item we initially moved.");
        XCTAssertEqual(moveInfo.fromIndex, listItemDestinationIndex, @"`fromIndex` should be the same as the list item's initial destination index.");
        XCTAssertEqual(moveInfo.toIndex, listItemToRemoveIndex, @"`toIndex` should be the same as the list item's initial index.");
    }];

    [self.undoManager undo];
}

#pragma mark - -toggleListItem:

- (void)testToggleIncompleteListItem {
    AAPLListItem *incompleteListItem = self.initiallyIncompleteListItems[1];
    NSInteger expectedFromIndex = 1;
    NSInteger expectedToIndex = self.initialListItemCount - 1;
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Test for item toggling.
        NSInteger didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count;
        XCTAssertEqual(didMoveListItemCallbackCount, 1, @"There should be one \"move\" callback.");

        if (didMoveListItemCallbackCount != 1) {
            return;
        }

        AAPLListPresenterCallbackInfo *moveInfo = self.testHelper.didMoveListItemCallbacks.firstObject;

        XCTAssertEqualObjects(moveInfo.listItem, incompleteListItem, @"The delegate should receive the \"move\" callback with the toggled list item.");
        XCTAssertEqual(moveInfo.fromIndex, expectedFromIndex, @"The delegate should move the item from the right start index.");
        XCTAssertEqual(moveInfo.toIndex, expectedToIndex, @"The delegate should move the item to the right end index.");

        // Test for item updating.
        NSInteger didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count;
        XCTAssertEqual(didUpdateListItemCallbackCount, 1, @"There should be one \"update\" callback.");

        if (didUpdateListItemCallbackCount != 1) {
            return;
        }

        AAPLListPresenterCallbackInfo *updateInfo = self.testHelper.didUpdateListItemCallbacks.firstObject;

        XCTAssertEqualObjects(updateInfo.listItem, incompleteListItem, @"The delegate should receive the \"update\" callback with the toggled list item.");

        XCTAssertTrue(incompleteListItem.isComplete, @"The item should be complete after the toggle.");
        XCTAssertEqual(updateInfo.index, expectedToIndex, @"The item should be updated in place.");
    }];

    [self.presenter toggleListItem:incompleteListItem];
}

- (void)testToggleCompleteListItem {
    AAPLListItem *completeListItem = self.initiallyCompleteListItems[2];

    NSInteger expectedFromIndex = [self.presentedListItems indexOfObject:completeListItem];
    NSInteger expectedToIndex = 0;
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Test for item moving.
        NSInteger didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count;
        XCTAssertEqual(didMoveListItemCallbackCount, 1, @"There should be one \"move\" callback.");
        
        if (didMoveListItemCallbackCount != 1) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *moveInfo = self.testHelper.didMoveListItemCallbacks.firstObject;
        
        XCTAssertEqualObjects(moveInfo.listItem, completeListItem, @"The delegate should receive the \"move\" callback with the toggled list item.");
        XCTAssertEqual(moveInfo.fromIndex, expectedFromIndex, @"The delegate should move the item from the right start index.");
        XCTAssertEqual(moveInfo.toIndex, expectedToIndex, @"The delegate should move the item to the right end index.");
        
        // Test for item updating.
        NSInteger didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count;
        XCTAssertEqual(didUpdateListItemCallbackCount, 1, @"There should be one \"update\" callback.");
        
        if (didUpdateListItemCallbackCount != 1) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *updateInfo = self.testHelper.didUpdateListItemCallbacks.firstObject;
        
        XCTAssertEqual(updateInfo.listItem, completeListItem, @"The delegate should receive the \"update\" callback with the toggled list item.");
        XCTAssertFalse(completeListItem.isComplete, @"The item should be incomplete after the toggle.");
        XCTAssertEqual(updateInfo.index, expectedToIndex, "@The item should be updated in place.");
    }];

    [self.presenter toggleListItem:completeListItem];
}

- (void)testToggleListItemAfterUndo {
    AAPLListItem *listItem = self.presentedListItems[2];
    
    NSInteger expectedFromIndex = [self.presentedListItems indexOfObject:listItem];
    NSInteger expectedToIndex = 0;
    
    [self.presenter toggleListItem:listItem];
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Test for item moving.
        NSInteger didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count;
        XCTAssertEqual(didMoveListItemCallbackCount, 1, @"There should be one \"move\" callback.");

        if (didMoveListItemCallbackCount != 1) {
            return;
        }

        AAPLListPresenterCallbackInfo *moveInfo = self.testHelper.didMoveListItemCallbacks.firstObject;

        XCTAssertEqualObjects(moveInfo.listItem, listItem, @"The delegate should receive the \"move\" callback with the toggled list item.");
        XCTAssertEqual(moveInfo.fromIndex, expectedToIndex, @"The delegate should move the item from the right start index.");
        XCTAssertEqual(moveInfo.toIndex, expectedFromIndex, @"The delegate should move the item to the right end index.");

        // Test for item updating.
        NSInteger didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count;
        XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.");

        if (didUpdateListItemCallbackCount != 1) {
            return;
        }

        AAPLListPresenterCallbackInfo *updateInfo = self.testHelper.didUpdateListItemCallbacks.firstObject;

        XCTAssertEqualObjects(updateInfo.listItem, listItem, @"The delegate should receive the \"update\" callback with the toggled list item.");
        XCTAssertTrue(listItem.isComplete, @"The item should be complete after the toggle.");
        XCTAssertEqual(updateInfo.index, expectedFromIndex, @"The item should be updated in place.");
    }];
    
    [self.undoManager undo];
}

#pragma mark - -updateListItem:withText:

- (void)testUpdateListItemWithText {
    NSInteger listItemIndex = 2;
    AAPLListItem *listItem = self.presentedListItems[listItemIndex];
    
    NSString *newText = @"foo bar baz qux";
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSInteger didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count;
        XCTAssertEqual(didUpdateListItemCallbackCount, 1, @"There should be one \"update\" callback.");
        
        if (didUpdateListItemCallbackCount != 1) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *updateInfo = self.testHelper.didUpdateListItemCallbacks.firstObject;
        
        XCTAssertEqualObjects(updateInfo.listItem, listItem, @"The update list item should be the same as our provided list item.");
        XCTAssertEqual(updateInfo.index, listItemIndex, @"The update should be an in-place update.");
        XCTAssertEqual(listItem.text, newText, @"The text should be updated.");
    }];
    
    [self.presenter updateListItem:listItem withText:newText];
}

- (void)testUpdateListItemWithTextAfterUndo {
    NSInteger listItemIndex = 2;
    AAPLListItem *listItem = self.presentedListItems[listItemIndex];
    NSString *initialListItemText = listItem.text;

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSInteger didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count;
        XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.");
        
        if (didUpdateListItemCallbackCount != 2) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *updateInfo = self.testHelper.didUpdateListItemCallbacks[1];
        
        XCTAssertEqualObjects(updateInfo.listItem, listItem, @"The update list item should be the same as our provided list item.");
        XCTAssertEqual(updateInfo.index, listItemIndex, @"The update should be an in-place update.");
        XCTAssertEqual(listItem.text, initialListItemText, @"The text should be updated to its initial value.");
    }];
    
    [self.undoManager undo];
}

#pragma mark - -updatePresentedListItemsToCompletionState:

- (void)testUpdatePresentedListItemsToCompletionState {
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        XCTAssertEqual(self.testHelper.didUpdateListItemCallbacks.count, self.initiallyIncompleteListItems.count, @"There should be one \"event\" per incomplete, presented item.");
        
        for (AAPLListPresenterCallbackInfo *updateInfo in self.testHelper.didUpdateListItemCallbacks) {
            NSInteger indexOfUpdatedListItem = [self.presentedListItems indexOfObject:updateInfo.listItem];
            
            if (indexOfUpdatedListItem == NSNotFound) {
                XCTFail(@"One of the updated list items was never supposed to be in the list.");
            }
            else {
                XCTAssertEqual(updateInfo.index, indexOfUpdatedListItem, @"The updated index should be the same as the initial index.");
                
                XCTAssertTrue(updateInfo.listItem.isComplete, @"The item should be complete after the update.");
            }
        }
    }];

    [self.presenter updatePresentedListItemsToCompletionState:YES];
}

- (void)testUpdatePresentedListItemsToCompletionStateAfterUndo {
    [self.presenter updatePresentedListItemsToCompletionState:YES];

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        NSArray *presentedListItemsCopy = [[NSArray alloc] initWithArray:self.presentedListItems copyItems:YES];
        
        XCTAssertEqual(self.testHelper.didUpdateListItemCallbacks.count, self.initiallyIncompleteListItems.count, @"The undo should perform \(self.presentedListItems.count) updates to revert the previous update for each modified item.");
        
        for (AAPLListPresenterCallbackInfo *updateInfo in self.testHelper.didUpdateListItemCallbacks) {
            NSInteger indexOfUpdatedListItem = [presentedListItemsCopy indexOfObject:updateInfo.listItem];
            
            if (indexOfUpdatedListItem == NSNotFound) {
                XCTFail(@"One of the updated list items was never supposed to be in the list.");
            }
            else {
                AAPLListItem *listItemCopy = presentedListItemsCopy[indexOfUpdatedListItem];
                
                XCTAssertEqual(updateInfo.index, indexOfUpdatedListItem, @"The updated index should be the same as the initial index.");
                
                XCTAssertEqualObjects(updateInfo.listItem, listItemCopy, @"The item should be the same as the initial item after the update.");
            }
        }
    }];
    
    [self.undoManager undo];
}

@end

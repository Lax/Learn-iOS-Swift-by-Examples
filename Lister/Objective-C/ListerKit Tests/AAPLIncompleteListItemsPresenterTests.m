/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The test case class for the \c AAPLIncompleteListItemsPresenter class.
*/

@import ListerKit;
@import XCTest;

#import "AAPLListPresenterTestHelper.h"

@interface AAPLIncompleteListItemsPresenterTests : XCTestCase

@property AAPLIncompleteListItemsPresenter *presenter;

@property AAPLList *list;

@property (copy) NSArray *initiallyIncompleteListItems;

@property (copy) NSArray *initiallyCompleteListItems;

@property (readonly, copy) NSArray *presentedListItems;

@property AAPLListPresenterTestHelper *testHelper;

@end


@implementation AAPLIncompleteListItemsPresenterTests

#pragma mark - Property Accessors

- (NSArray *)presentedListItems {
    NSArray *allListItems = [self.initiallyIncompleteListItems arrayByAddingObjectsFromArray:self.initiallyCompleteListItems];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"isComplete == NO"];
    
    return [allListItems filteredArrayUsingPredicate:filterPredicate];
}

#pragma mark - XCTest Life Time

- (void)setUp {
    self.initiallyIncompleteListItems = @[
        [[AAPLListItem alloc] initWithText:@"0" complete:NO],
        [[AAPLListItem alloc] initWithText:@"1" complete:NO],
        [[AAPLListItem alloc] initWithText:@"2" complete:NO],
        [[AAPLListItem alloc] initWithText:@"3" complete:NO]
    ];
    
    self.initiallyCompleteListItems = @[
        [[AAPLListItem alloc] initWithText:@"4" complete:YES],
        [[AAPLListItem alloc] initWithText:@"5" complete:YES],
        [[AAPLListItem alloc] initWithText:@"6" complete:YES],
    ];
    
    self.list = [[AAPLList alloc] initWithColor:AAPLListColorGreen items:self.presentedListItems];
    
    self.presenter = [[AAPLIncompleteListItemsPresenter alloc] init];
    
    [self.presenter setList:self.list];
    
    self.testHelper = [[AAPLListPresenterTestHelper alloc] init];
    
    self.presenter.delegate = self.testHelper;
}

#pragma mark - Test Initializers

- (void)testItemInitializationWithIncompleteAndCompleteListItems {
    XCTAssertEqualObjects(self.presenter.presentedListItems, self.initiallyIncompleteListItems, @"Only the incomplete items should be presented.");
}

#pragma mark - archiveableList

- (void)testArchiveableListWithIncompleteAndCompleteItemsAfterToggle {
    NSInteger indexOfListItemToToggle = 2;
    AAPLListItem *listItemToToggle = self.presenter.presentedListItems[indexOfListItemToToggle];
    
    /**
        Create a list that represents what should be the final archiveable list. We will compare this list
        against the presenter's `archiveableList`.
     */
    AAPLList *expectedList = [self.list copy];
    AAPLListItem *expectedChangeListItem = expectedList.items[indexOfListItemToToggle];
    expectedChangeListItem.complete = !expectedChangeListItem.isComplete;
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Check the archiveable list against the expected list we created.
        XCTAssertEqualObjects(self.presenter.archiveableList, expectedList, @"The `archiveableList` from the presenter should match our expected list.");
    }];
    
    // Perform the toggle. No need to worry about the side affects of the toggle.
    [self.presenter toggleListItem:listItemToToggle];
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
        
        AAPLListPresenterCallbackInfo *updatedColorInfo = self.testHelper.didUpdateListColorCallbacks.firstObject;
        XCTAssertEqual(updatedColorInfo.color, newColor, @"The delegate callback should provide the new color.");
    }];
    
    self.presenter.color = newColor;
}

#pragma mark - -toggleListItem:

- (void)testToggleIncompleteListItem {
    AAPLListItem *incompleteListItem = self.initiallyIncompleteListItems[1];
    
    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Test for item updating.
        NSInteger didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count;
        XCTAssertEqual(didUpdateListItemCallbackCount, 1, @"There should be one \"update\" callback.");
        
        if (didUpdateListItemCallbackCount != 1) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *updateInfo = self.testHelper.didUpdateListItemCallbacks.firstObject;
        
        XCTAssertEqualObjects(updateInfo.listItem, incompleteListItem, @"The delegate should receive the \"update\" callback with the toggled list item.");
        
        XCTAssertTrue(incompleteListItem.isComplete, @"The item should be complete after the toggle.");
        XCTAssertEqual(updateInfo.index, 1, @"The item should be updated in place.");
    }];
    
    [self.presenter toggleListItem:incompleteListItem];
}

- (void)testToggleCompleteListItem {
    [self.presenter updatePresentedListItemsToCompletionState:NO];
    
    NSInteger completeListItemIndex = 1;
    AAPLListItem *completeListItem = self.presenter.presentedListItems[completeListItemIndex];

    [self.testHelper whenNextChangeOccursPerformAssertions:^{
        // Test for item updating.
        NSInteger didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count;
        XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.");
        
        if (didUpdateListItemCallbackCount != 1) {
            return;
        }
        
        AAPLListPresenterCallbackInfo *updateInfo = self.testHelper.didUpdateListItemCallbacks.firstObject;
        
        XCTAssertEqualObjects(updateInfo.listItem, completeListItem, @"The delegate should receive the \"update\" callback with the toggled list item.");
        XCTAssertTrue(completeListItem.isComplete, "The item should be complete after the toggle.");
        XCTAssertEqual(updateInfo.index, completeListItemIndex, "The item should be updated in place.");
    }];

    [self.presenter toggleListItem:completeListItem];
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

@end

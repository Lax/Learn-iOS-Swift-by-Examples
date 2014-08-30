/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The test case class for the \c AAPLList class.
            
*/

/*!
 * Since we'd like to test the framework for both iOS and Mac, we need to have
 * the target conditionals (e.g. TARGET_OS_IPHONE) to check against.
 */
#import <TargetConditionals.h>

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
@import ListerKit;
#elif TARGET_OS_MAC
@import ListerKitOSX;
#endif

@import XCTest;

@interface AAPLListTests : XCTestCase

/// \c items is initialized in \c -setUp.
@property (nonatomic, copy) NSArray *items;

/// \c color is initialized in \c -setUp.
@property AAPLListColor color;

/// \c nonEmptyList is initialized in \c  -setUp.
@property (nonatomic, strong) AAPLList *nonEmptyList;

/// \c emptyList is initialized in \c -setUp.
@property (nonatomic, strong) AAPLList *emptyList;

@end

@implementation AAPLListTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];
    
    self.color = AAPLListColorGreen;

    self.items = @[
        [[AAPLListItem alloc] initWithText:@"zero" complete:NO],
        [[AAPLListItem alloc] initWithText:@"one" complete:NO],
        [[AAPLListItem alloc] initWithText:@"two" complete:NO],
        [[AAPLListItem alloc] initWithText:@"three" complete:YES],
        [[AAPLListItem alloc] initWithText:@"four" complete:YES],
        [[AAPLListItem alloc] initWithText:@"five" complete:YES]
    ];
    
    self.nonEmptyList = [[AAPLList alloc] initWithColor:self.color items:self.items];
    self.emptyList = [[AAPLList alloc] initWithColor:AAPLListColorGray items:@[]];
}

#pragma mark - Initializers

- (void)testDefautInitializer {
    AAPLList *list = [[AAPLList alloc] init];
    
    XCTAssertEqual(list.color, AAPLListColorGray);
    XCTAssertTrue(list.isEmpty);
}

- (void)testColorAndItemsDesignatedInitializer {
    XCTAssertEqual(self.nonEmptyList.color, self.color);
    XCTAssertTrue([self.nonEmptyList.allItems isEqualToArray:self.items]);
}

- (void)testColorAndItemsDesignatedInitializerCopiesItems {
    [self.nonEmptyList.allItems enumerateObjectsUsingBlock:^(AAPLListItem *item, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(item, self.items[idx]);
    }];
}

#pragma mark - NSCopying

- (void)testCopyingLists {
    AAPLList *listCopy = [self.nonEmptyList copy];
    
    XCTAssertNotNil(listCopy);
    XCTAssertEqualObjects(self.nonEmptyList, listCopy);
}

#pragma mark - NSCoding

- (void)testEncodingLists {
    NSData *archivedListData = [NSKeyedArchiver archivedDataWithRootObject:self.nonEmptyList];

    XCTAssertTrue(archivedListData.length > 0);
}

- (void)testDecodingLists {
    NSData *archivedListData = [NSKeyedArchiver archivedDataWithRootObject:self.nonEmptyList];
    
    AAPLList *unarchivedList = [NSKeyedUnarchiver unarchiveObjectWithData:archivedListData];
    
    XCTAssertNotNil(unarchivedList);
    XCTAssertEqualObjects(self.nonEmptyList, unarchivedList);
}

#pragma mark - count

- (void)testCountAfterInitialization {
    XCTAssertEqual(self.nonEmptyList.count, self.items.count);
}

- (void)testCountAfterInsertion {
    AAPLListItem *anotherItem = [[AAPLListItem alloc] initWithText:@"foo"];
    
    [self.emptyList insertItem:anotherItem];

    XCTAssertEqual(self.emptyList.count, 1);
}

#pragma mark - indexOfFirstCompletedItem

- (void)testIndexOfFirstCompletedItem {
    NSInteger expectedIndexOfFirstCompletedItem = 3;
    
    XCTAssertEqual(self.nonEmptyList.indexOfFirstCompletedItem, expectedIndexOfFirstCompletedItem);
}

- (void)testIndexOfFirstCompletedItemIsNotFoundWithNoCompletedItems {
    for (AAPLListItem *item in self.items) {
        item.complete = NO;
    }
    
    AAPLList *list = [[AAPLList alloc] initWithColor:AAPLListColorGray items:self.items];
    
    XCTAssertEqual(list.indexOfFirstCompletedItem, NSNotFound);
}

#pragma mark - isEmpty

- (void)testIsEmpty {
    XCTAssertTrue(self.emptyList.isEmpty);
    XCTAssertFalse(self.nonEmptyList.isEmpty);
}

#pragma mark - Subscripting

- (void)testSingleSubscript {
    [self.items enumerateObjectsUsingBlock:^(AAPLListItem *item, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(self.nonEmptyList[idx], item);
    }];
}

- (void)testIndexSetSubscript {
    // Create an index set to index into the List.
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    [indexSet addIndex:0];
    [indexSet addIndex:2];
    [indexSet addIndex:3];

    // Fetch the items from the indexes.
    NSArray *indexedItems = self.nonEmptyList[indexSet];
    
    // Test to make sure that the index set fetches all the list items we expect.
    __block NSInteger indexedItemCount = 0;
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        AAPLListItem *expectedItem = self.items[idx];
        AAPLListItem *indexedItem = indexedItems[indexedItemCount];
        
        XCTAssertEqualObjects(expectedItem, indexedItem);
        
        indexedItemCount++;
    }];
    
    XCTAssertEqual(indexedItems.count, indexSet.count);
}

- (void)testEmptyIndexSetSubscript {
    // Fetch the items from the _empty_ indexes.
    NSIndexSet *emptyIndexSet = [NSIndexSet indexSet];
    NSArray *indexedItems = self.nonEmptyList[emptyIndexSet];
    
    XCTAssertTrue(indexedItems.count == 0);
}

#pragma mark - Index Querying

- (void)testIndexOfItem {
    [self.items enumerateObjectsUsingBlock:^(AAPLListItem *expectedItem, NSUInteger expectedIndex, BOOL *stop) {
        NSInteger foundIndex = [self.nonEmptyList indexOfItem:expectedItem];
        
        XCTAssertEqual(foundIndex, expectedIndex);
    }];
}

- (void)testIndexOfItemThatDoesntExistInTheList {
    AAPLListItem *randomItem = [[AAPLListItem alloc] initWithText:@"foo"];
    
    NSInteger foundIndex = [self.nonEmptyList indexOfItem:randomItem];
    
    XCTAssertEqual(foundIndex, NSNotFound);
}

#pragma mark - Removing Items

- (void)testRemoveItems {
    for (AAPLListItem *item in self.items) {
        item.complete = NO;
    }
    
    NSArray *subsetOfItemsToRemove = @[self.items[0], self.items[2], self.items[4]];
    NSArray *subsetOfItemsToRemain = @[self.items[1], self.items[3], self.items[5]];
    
    [self.nonEmptyList removeItems:subsetOfItemsToRemove];

    for (AAPLListItem *removedItem in subsetOfItemsToRemove) {
        NSInteger indexOfRemovedItem = [self.nonEmptyList indexOfItem:removedItem];
        
        XCTAssertEqual(indexOfRemovedItem, NSNotFound);
    }

    for (AAPLListItem *remainingItem in subsetOfItemsToRemain) {
        NSInteger indexOfRemainingItem = [self.nonEmptyList indexOfItem:remainingItem];
        
        XCTAssertNotEqual(indexOfRemainingItem, NSNotFound);
    }
}

#pragma mark - -canInsertIncompleteItems:atIndex:

- (void)testInsertionWithAtLeastOneCompleteItemAndAnInvalidIndex {
    NSArray *itemsToInsert = @[
        [[AAPLListItem alloc] initWithText:@"foo" complete:NO],
        [[AAPLListItem alloc] initWithText:@"bar" complete:YES],
        [[AAPLListItem alloc] initWithText:@"baz" complete:NO],
        [[AAPLListItem alloc] initWithText:@"qux" complete:NO]
    ];
    
    NSInteger invalidIndex = 10;
    
    BOOL canInsertItems = [self.nonEmptyList canInsertIncompleteItems:itemsToInsert atIndex:invalidIndex];
    
    XCTAssertFalse(canInsertItems);
}

- (void)testInsertionWithAtLeaseOneIncompleteItemWithAValidIndex {
    NSArray *itemsToInsert = @[
        [[AAPLListItem alloc] initWithText:@"foo" complete:NO],
        [[AAPLListItem alloc] initWithText:@"bar" complete:YES],
        [[AAPLListItem alloc] initWithText:@"baz" complete:NO],
        [[AAPLListItem alloc] initWithText:@"qux" complete:NO]
    ];
    
    NSInteger validIndex = 0;
    
    BOOL canInsertItems = [self.nonEmptyList canInsertIncompleteItems:itemsToInsert atIndex:validIndex];
    
    XCTAssertFalse(canInsertItems);
}

- (void)testInsertionWithIncompleteItemsButWithAnInvalidIndex {
    NSArray *itemsToInsert = @[
        [[AAPLListItem alloc] initWithText:@"foo" complete:NO],
        [[AAPLListItem alloc] initWithText:@"bar" complete:NO],
        [[AAPLListItem alloc] initWithText:@"baz" complete:NO],
        [[AAPLListItem alloc] initWithText:@"qux" complete:NO]
    ];
    
    NSInteger invalidIndex = 10;
    
    BOOL canInsertItems = [self.nonEmptyList canInsertIncompleteItems:itemsToInsert atIndex:invalidIndex];
    
    XCTAssertFalse(canInsertItems);
}

- (void)testInsertionWithIncompleteItemsButWithAValidIndex {
    NSArray *itemsToInsert = @[
        [[AAPLListItem alloc] initWithText:@"foo" complete:NO],
        [[AAPLListItem alloc] initWithText:@"bar" complete:NO],
        [[AAPLListItem alloc] initWithText:@"baz" complete:NO],
        [[AAPLListItem alloc] initWithText:@"qux" complete:NO]
    ];
    
    NSInteger validIndex = 2;

    BOOL canInsertItems = [self.nonEmptyList canInsertIncompleteItems:itemsToInsert atIndex:validIndex];
    
    XCTAssertTrue(canInsertItems);
}

#pragma mark - -insertItem:atIndex:

- (void)testCompletedItemInsertionWithValidIndex {
    AAPLListItem *completeItem = [[AAPLListItem alloc] initWithText:@"foo" complete:YES];
    
    NSInteger completeItemTargetIndex = self.nonEmptyList.count - 1;
    
    [self.nonEmptyList insertItem:completeItem atIndex:completeItemTargetIndex];
    
    NSInteger completeItemIndexAfterInsertion = [self.nonEmptyList indexOfItem:completeItem];
    
    XCTAssertEqual(completeItemTargetIndex, completeItemIndexAfterInsertion);
}

- (void)testIncompleteItemInsertionWithValidIndex {
    AAPLListItem *incompleteItem = [[AAPLListItem alloc] initWithText:@"foo" complete:NO];
    
    NSInteger incompleteItemTargetIndex = 0;
    
    [self.nonEmptyList insertItem:incompleteItem atIndex:incompleteItemTargetIndex];

    NSInteger incompleteItemIndexAfterInsertion = [self.nonEmptyList indexOfItem:incompleteItem];

    XCTAssertEqual(incompleteItemTargetIndex, incompleteItemIndexAfterInsertion);
}

#pragma mark - -insertItem:

- (void)testInsertCompleteItem {
    AAPLListItem *completeItem = [[AAPLListItem alloc] initWithText:@"foo" complete:YES];
    
    NSInteger itemCountBeforeInsertion = self.nonEmptyList.count;
    
    NSInteger insertedIndex = [self.nonEmptyList insertItem:completeItem];

    XCTAssertEqual(itemCountBeforeInsertion, insertedIndex);
}

- (void)testInsertIncompleteItem {
    AAPLListItem *incompleteItem = [[AAPLListItem alloc] initWithText:@"foo" complete:NO];

    NSInteger insertedIndex = [self.nonEmptyList insertItem:incompleteItem];
    
    XCTAssertEqual(0, insertedIndex);
}

#pragma mark - -insertItems:

- (void)testInsertAllCompleteItems {
    NSArray *completeItems = @[
        [[AAPLListItem alloc] initWithText:@"0" complete:YES],
        [[AAPLListItem alloc] initWithText:@"1" complete:YES],
        [[AAPLListItem alloc] initWithText:@"2" complete:YES],
        [[AAPLListItem alloc] initWithText:@"3" complete:YES]
    ];
    
    NSRange expectedInsertedIndexesRange = NSMakeRange(self.nonEmptyList.count, completeItems.count);
    NSIndexSet *expectedInsertedIndexes = [NSIndexSet indexSetWithIndexesInRange:expectedInsertedIndexesRange];

    NSIndexSet *insertedIndexes = [self.nonEmptyList insertItems:completeItems];

    XCTAssertEqualObjects(insertedIndexes, expectedInsertedIndexes);

    __block NSInteger completeItemsIndex = 0;
    [insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger insertedIndex, BOOL *stop) {
        AAPLListItem *insertedItem = completeItems[completeItemsIndex];
        AAPLListItem *itemAtInsertedIndex = self.nonEmptyList[insertedIndex];

        XCTAssertEqualObjects(insertedItem, itemAtInsertedIndex);
        
        completeItemsIndex++;
    }];
}

- (void)testInsertAllIncompleteItems {
    NSArray *incompleteItems = @[
        [[AAPLListItem alloc] initWithText:@"0" complete:NO],
        [[AAPLListItem alloc] initWithText:@"1" complete:NO],
        [[AAPLListItem alloc] initWithText:@"2" complete:NO],
        [[AAPLListItem alloc] initWithText:@"3" complete:NO]
    ];
    
    NSRange expectedInsertedIndexesRange = NSMakeRange(0, incompleteItems.count);
    NSIndexSet *expectedInsertedIndexes = [NSIndexSet indexSetWithIndexesInRange:expectedInsertedIndexesRange];
    
    NSIndexSet *insertedIndexes = [self.nonEmptyList insertItems:incompleteItems];

    XCTAssertEqualObjects(insertedIndexes, expectedInsertedIndexes);

    __block NSInteger incompleteItemsIndex = 0;
    [insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger insertedIndex, BOOL *stop) {
        AAPLListItem *insertedItem = incompleteItems[incompleteItemsIndex];
        AAPLListItem *itemAtInsertedIndex = self.nonEmptyList[insertedIndex];
        
        XCTAssertEqualObjects(insertedItem, itemAtInsertedIndex);
        
        incompleteItemsIndex++;
    }];
}

- (void)testInsertMixMatchOfCompleteAndIncompleteItems {
    AAPLListItem *incompleteItem = [[AAPLListItem alloc] initWithText:@"foo" complete:NO];
    AAPLListItem *completeItem = [[AAPLListItem alloc] initWithText:@"bar" complete:YES];

    NSInteger expectedIncompleteItemIndex = 0;
    
    NSInteger expectedCompleteItemIndex = self.nonEmptyList.count + 1;
    
    NSIndexSet *insertedIndexes = [self.nonEmptyList insertItems:@[completeItem, incompleteItem]];
    
    NSInteger insertedIncompleteItemIndex = insertedIndexes.firstIndex;
    NSInteger insertedCompleteItemIndex = insertedIndexes.lastIndex;
    
    XCTAssertEqual(insertedIncompleteItemIndex, expectedIncompleteItemIndex);
    XCTAssertEqual(insertedCompleteItemIndex, expectedCompleteItemIndex);
    
    XCTAssertEqual(insertedIndexes.count, 2);

    AAPLListItem *incompleteItemAtInsertedIndex = self.nonEmptyList[expectedIncompleteItemIndex];
    AAPLListItem *completeItemAtInsertedIndex = self.nonEmptyList[expectedCompleteItemIndex];
    
    XCTAssertEqualObjects(incompleteItemAtInsertedIndex, incompleteItem);
    XCTAssertEqualObjects(completeItemAtInsertedIndex, completeItem);
}

#pragma mark - -updateAllItemsToCompletionState:

- (void)testUpdateAllItemsToCompletionState {
    for (AAPLListItem *item in self.items) {
        item.complete = NO;
    }
    
    [self.nonEmptyList updateAllItemsToCompletionState:YES];

    for (AAPLListItem *item in self.nonEmptyList.allItems) {
        XCTAssertTrue(item.isComplete);
    }
}

#pragma mark - -toggleItem:

- (void)testToggleIncompleteItem {
    NSInteger startItemIndex = 2;
    AAPLListItem *item = self.nonEmptyList[startItemIndex];
    
    NSInteger preferredTargetIndex = 4;
    
    AAPLListOperationInfo info = [self.nonEmptyList toggleItem:item withPreferredDestinationIndex:preferredTargetIndex];

    XCTAssertEqual(startItemIndex, info.fromIndex);
    XCTAssertEqual(preferredTargetIndex, info.toIndex);
}

- (void)testToggleIncompleteItemWithNilPreferredTargetIndex {
    NSInteger startItemIndex = 2;
    AAPLListItem *item = self.nonEmptyList[startItemIndex];
    
    AAPLListOperationInfo info = [self.nonEmptyList toggleItem:item withPreferredDestinationIndex:NSNotFound];
    
    XCTAssertEqual(startItemIndex, info.fromIndex);
    XCTAssertEqual(self.nonEmptyList.count - 1, info.toIndex);
}

- (void)testToggleCompleteItem {
    NSInteger startItemIndex = 4;
    AAPLListItem *item = self.nonEmptyList[startItemIndex];
    
    NSInteger preferredTargetIndex = 2;
    
    AAPLListOperationInfo info = [self.nonEmptyList toggleItem:item withPreferredDestinationIndex:preferredTargetIndex];

    XCTAssertEqual(startItemIndex, info.fromIndex);
    XCTAssertEqual(preferredTargetIndex, info.toIndex);
}

- (void)testToggleCompleteItemWithNilPreferredTargetIndex {
    NSInteger startItemIndex = 4;
    AAPLListItem *item = self.nonEmptyList[startItemIndex];
    
    NSInteger indexOfFirstCompletedItemBeforeToggle = self.nonEmptyList.indexOfFirstCompletedItem;
    
    AAPLListOperationInfo info = [self.nonEmptyList toggleItem:item withPreferredDestinationIndex:NSNotFound];
    
    XCTAssertEqual(startItemIndex, info.fromIndex);
    
    XCTAssertEqual(indexOfFirstCompletedItemBeforeToggle, info.toIndex);
}

- (void)testToggleOnlyCompleteItemWithNilPreferredTargetIndex {
    self.nonEmptyList[3].complete = NO;
    self.nonEmptyList[4].complete = NO;
    
    NSInteger startItemIndex = 5;
    AAPLListItem *item = self.nonEmptyList[startItemIndex];
    
    NSInteger indexOfFirstCompletedItemBeforeToggle = self.nonEmptyList.indexOfFirstCompletedItem;
    
    AAPLListOperationInfo info = [self.nonEmptyList toggleItem:item withPreferredDestinationIndex:NSNotFound];
    
    XCTAssertEqual(startItemIndex, info.fromIndex);

    XCTAssertEqual(indexOfFirstCompletedItemBeforeToggle, info.fromIndex);
}

#pragma mark - -canMoveItem:toIndex:inclusive:

- (void)testCanMoveCompleteItemToInvalidIndexInclusive {
    AAPLListItem *completeItem = self.nonEmptyList.allItems.lastObject;
    NSInteger invalidMoveIndex = 0;
    
    BOOL canMove = [self.nonEmptyList canMoveItem:completeItem toIndex:invalidMoveIndex inclusive:YES];
    
    XCTAssertFalse(canMove);
}

- (void)testCanMoveCompleteItemToInvalidIndexNotInclusive {
    AAPLListItem *completeItem = self.nonEmptyList.allItems.lastObject;
    NSInteger invalidMoveIndex = 1;
    
    BOOL canMove = [self.nonEmptyList canMoveItem:completeItem toIndex:invalidMoveIndex inclusive:NO];
    
    XCTAssertFalse(canMove);
}

- (void)testCanMoveCompleteItemToValidIndexInclusive {
    AAPLListItem *completeItem = self.nonEmptyList.allItems.lastObject;
    NSInteger validMoveIndex = self.nonEmptyList.indexOfFirstCompletedItem;
    
    BOOL canMove = [self.nonEmptyList canMoveItem:completeItem toIndex:validMoveIndex inclusive:YES];

    XCTAssertTrue(canMove);
}

- (void)testCanMoveCompleteItemToValidIndexNotInclusive {
    AAPLListItem *completeItem = self.nonEmptyList.allItems.lastObject;
    NSInteger validMoveIndex = self.nonEmptyList.indexOfFirstCompletedItem;
    
    BOOL canMove = [self.nonEmptyList canMoveItem:completeItem toIndex:validMoveIndex inclusive:NO];
    
    XCTAssertTrue(canMove);
}

- (void)testCanMoveIncompleteItemToInvalidIndexInclusive {
    AAPLListItem *incompleteItem = self.nonEmptyList.allItems.firstObject;
    NSInteger invalidMoveIndex = self.nonEmptyList.count - 1;
    
    BOOL canMove = [self.nonEmptyList canMoveItem:incompleteItem toIndex:invalidMoveIndex inclusive:YES];
    
    XCTAssertFalse(canMove);
}

- (void)testCanMoveIncompleteItemToInvalidIndexNotInclusive {
    AAPLListItem *incompleteItem = self.nonEmptyList.allItems.firstObject;
    NSInteger invalidMoveIndex = self.nonEmptyList.count - 1;
    
    BOOL canMove = [self.nonEmptyList canMoveItem:incompleteItem toIndex:invalidMoveIndex inclusive:NO];
    
    XCTAssertFalse(canMove);
}

- (void)testCanMoveIncompleteItemToValidIndexInclusive {
    AAPLListItem *incompleteItem = self.nonEmptyList.allItems.firstObject;
    NSInteger validMoveIndex = self.nonEmptyList.indexOfFirstCompletedItem;
    
    BOOL canMove = [self.nonEmptyList canMoveItem:incompleteItem toIndex:validMoveIndex inclusive:YES];
    
    XCTAssertTrue(canMove);
}

- (void)testCanMoveIncompleteItemToValidIndexNotInclusive {
    AAPLListItem *incompleteItem = self.nonEmptyList.allItems.firstObject;
    NSInteger invalidMoveIndex = self.nonEmptyList.indexOfFirstCompletedItem;
    NSInteger validMoveIndex = self.nonEmptyList.indexOfFirstCompletedItem - 1;
    
    BOOL canMoveToInvalidIndex = [self.nonEmptyList canMoveItem:incompleteItem toIndex:invalidMoveIndex inclusive:NO];
    BOOL canMoveToValidIndex = [self.nonEmptyList canMoveItem:incompleteItem toIndex:validMoveIndex inclusive:NO];

    XCTAssertFalse(canMoveToInvalidIndex);
    XCTAssertTrue(canMoveToValidIndex);
}

#pragma mark - -moveItem:toIndex:

- (void)testMoveCompleteItemToCompleteIndex {
    NSInteger initialCompleteItemIndex = self.nonEmptyList.indexOfFirstCompletedItem + 1;
    
    AAPLListItem *completeItem = self.nonEmptyList[initialCompleteItemIndex];
    
    NSInteger destinationIndex = self.nonEmptyList.indexOfFirstCompletedItem;
    
    AAPLListOperationInfo movedIndexes = [self.nonEmptyList moveItem:completeItem toIndex:destinationIndex];

    XCTAssertEqual(movedIndexes.fromIndex, initialCompleteItemIndex);
    XCTAssertEqual(movedIndexes.toIndex, destinationIndex);

    AAPLListItem *movedItem = self.nonEmptyList[destinationIndex];

    XCTAssertEqualObjects(movedItem, completeItem);
}

- (void)testMoveIncompleteItemToIncompleteIndex {
    NSInteger initialIncompleteItemIndex = 1;
    
    AAPLListItem *incompleteItem = self.nonEmptyList[initialIncompleteItemIndex];
    
    NSInteger destinationIndex = self.nonEmptyList.indexOfFirstCompletedItem - 1;
    
    AAPLListOperationInfo movedIndexes = [self.nonEmptyList moveItem:incompleteItem toIndex:destinationIndex];

    AAPLListItem *movedItem = self.nonEmptyList[movedIndexes.toIndex];
    
    XCTAssertEqualObjects(movedItem, incompleteItem);
}

#pragma mark - Equality

- (void)testIsEqual {
    AAPLList *listOne = [[AAPLList alloc] initWithColor:AAPLListColorGray items:self.items];
    AAPLList *listTwo = [[AAPLList alloc] initWithColor:AAPLListColorGray items:self.items];
    AAPLList *listThree = [[AAPLList alloc] initWithColor:AAPLListColorGreen items:self.items];
    AAPLList *listFour = [[AAPLList alloc] initWithColor:AAPLListColorGray items:@[]];
    
    XCTAssertEqualObjects(listOne, listTwo);
    XCTAssertNotEqualObjects(listTwo, listThree);
    XCTAssertNotEqualObjects(listTwo, listFour);
}

@end

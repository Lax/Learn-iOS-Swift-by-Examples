/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The test case class for the \c AAPLList class.
*/

@import ListerKit;
@import XCTest;

@interface AAPLListTests : XCTestCase

/// \c items is initialized in \c -setUp.
@property (nonatomic, copy) NSArray *items;

/// \c color is initialized in \c -setUp.
@property AAPLListColor color;

/// Initialized in \c  -setUp.
@property (nonatomic, strong) AAPLList *list;

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
    
    self.list = [[AAPLList alloc] initWithColor:self.color items:self.items];
}

#pragma mark - Initialization

- (void)testDefautInitializer {
    AAPLList *list = [[AAPLList alloc] initWithColor:AAPLListColorGray items:@[]];
    
    XCTAssertEqual(list.color, AAPLListColorGray);
    XCTAssertTrue(list.items.count == 0);
}

- (void)testColorAndItemsDesignatedInitializer {
    XCTAssertEqual(self.list.color, self.color);
    XCTAssertTrue([self.list.items isEqualToArray:self.items]);
}

- (void)testColorAndItemsDesignatedInitializerCopiesItems {
    [self.list.items enumerateObjectsUsingBlock:^(AAPLListItem *item, NSUInteger idx, BOOL *stop) {
        XCTAssertEqualObjects(item, self.items[idx]);
    }];
}

#pragma mark - NSCopying

- (void)testCopyingLists {
    AAPLList *listCopy = [self.list copy];
    
    XCTAssertNotNil(listCopy);
    XCTAssertEqualObjects(self.list, listCopy);
}

#pragma mark - NSCoding

- (void)testEncodingLists {
    NSData *archivedListData = [NSKeyedArchiver archivedDataWithRootObject:self.list];

    XCTAssertTrue(archivedListData.length > 0);
}

- (void)testDecodingLists {
    NSData *archivedListData = [NSKeyedArchiver archivedDataWithRootObject:self.list];
    
    AAPLList *unarchivedList = [NSKeyedUnarchiver unarchiveObjectWithData:archivedListData];
    
    XCTAssertNotNil(unarchivedList);
    XCTAssertEqualObjects(self.list, unarchivedList);
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

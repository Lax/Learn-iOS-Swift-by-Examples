/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The test case class for the `ListItem` class.
*/

import ListerKit
import XCTest

class ListItemTests: XCTestCase {
    // MARK: Properties

    // `item` is initialized again in setUp().
    var item: ListItem!
    
    // MARK: Setup
    
    override func setUp() {
        super.setUp()

        item = ListItem(text: "foo")
    }
    
    // MARK: Initializers
    
    func testConvenienceTextAndCompleteInit() {
        let text = "foo"
        let complete = true
        
        let item = ListItem(text: text, complete: complete)
        
        XCTAssertEqual(item.text, text)
        XCTAssertEqual(item.isComplete, complete)
    }
    
    func testConvenienceTextInit() {
        let text = "foo"
        
        let item = ListItem(text: text)
        
        XCTAssertEqual(item.text, text)
        
        // The default value for the complete state should be `false`.
        XCTAssertFalse(item.isComplete)
    }
    
    // MARK: NSCopying
    
    func testCopyingListItems() {
        let itemCopy = item.copy() as? ListItem
        
        XCTAssertNotNil(itemCopy)
        
        if itemCopy != nil {
            XCTAssertEqual(item, itemCopy!)
        }
    }

    // MARK: NSCoding
    
    func testEncodingListItems() {
        let archivedListItemData = NSKeyedArchiver.archivedDataWithRootObject(item)

        XCTAssertTrue(archivedListItemData.length > 0)
    }
    
    func testDecodingListItems() {
        let archivedListItemData = NSKeyedArchiver.archivedDataWithRootObject(item)

        let unarchivedListItem = NSKeyedUnarchiver.unarchiveObjectWithData(archivedListItemData) as? ListItem
        
        XCTAssertNotNil(unarchivedListItem)
        
        if unarchivedListItem != nil {
            XCTAssertEqual(item, unarchivedListItem!)
        }
    }
    
    // MARK: refreshIdentity()
    
    func testRefreshIdentity() {
        let itemCopy = item.copy() as ListItem

        XCTAssertEqual(item, itemCopy)
        
        item.refreshIdentity()

        XCTAssertNotEqual(itemCopy, item)
    }

    // MARK: isEqual(_:)
    
    func testIsEqual() {
        // isEqual(_:) should be strictly based of the underlying UUID of the list item.

        let itemTwo = ListItem(text: "foo")

        XCTAssertFalse(item.isEqual(nil))
        XCTAssertEqual(item!, item!)
        XCTAssertNotEqual(item, itemTwo)
    }
    
    // MARK: Archive Compatibility
    
    /**
        Ensure that the runtime name of the `ListItem` class is "AAPLListItem". This is to ensure
        compatibility with the Objective-C version of the app that archives its data with the
        `AAPLListItem` class.
    */
    func testClassRuntimeNameForArchiveCompatibility() {
        let classRuntimeName = NSStringFromClass(ListItem.self)!

        XCTAssertEqual(classRuntimeName, "AAPLListItem", "ListItem should be archivable with the Objective-C version of Lister.")
    }
}

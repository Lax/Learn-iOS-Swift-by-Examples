/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The test case class for the `List` class.
            
*/

#if os(iOS)
import UIKit
import ListerKit
#elseif os(OSX)
import Cocoa
import ListerKitOSX
#endif

import XCTest

class ListTests: XCTestCase {
    // MARK: Properties

    // `items` is initialized again in setUp().
    var items = [ListItem]()
    
    var color = List.Color.Green

    // Both of these lists are initialized in setUp().
    var nonEmptyList: List!
    var emptyList: List!

    // MARK: Setup
    
    override func setUp() {
        super.setUp()

        items = [
            ListItem(text: "zero", completed: false),
            ListItem(text: "one", completed: false),
            ListItem(text: "two", completed: false),
            ListItem(text: "three", completed: true),
            ListItem(text: "four", completed: true),
            ListItem(text: "five", completed: true)
        ]

        nonEmptyList = List(color: color, items: items)
        emptyList = List(color: .Gray, items: [])
    }
    
    // MARK: Initializers
    
    func testDefaultInitializer() {
        let list = List()

        XCTAssertEqual(list.color, List.Color.Gray, "The default list color is Gray.")
        XCTAssertTrue(list.isEmpty, "A default list has no list items.")
    }
    
    func testColorAndItemsDesignatedInitializer() {
        XCTAssertEqual(nonEmptyList.color, color)

        XCTAssertTrue(nonEmptyList.items == items)
    }

    func testColorAndItemsDesignatedInitializerCopiesItems() {
        for (index, item) in enumerate(nonEmptyList.items) {
            XCTAssertFalse(items[index] === item, "ListItems should be copied in List's init().")
        }
    }
    
    // MARK: NSCopying
    
    func testCopyingLists() {
        let listCopy = nonEmptyList.copy() as? List

        XCTAssertNotNil(listCopy)
        
        if listCopy != nil {
            XCTAssertEqual(nonEmptyList, listCopy!)
        }
    }
    
    // MARK: NSCoding

    func testEncodingLists() {
        let archivedListData = NSKeyedArchiver.archivedDataWithRootObject(nonEmptyList)

        XCTAssertTrue(archivedListData.length > 0)
    }
    
    func testDecodingLists() {
        let archivedListData = NSKeyedArchiver.archivedDataWithRootObject(nonEmptyList)
        
        let unarchivedList = NSKeyedUnarchiver.unarchiveObjectWithData(archivedListData) as? List

        XCTAssertNotNil(unarchivedList)

        if nonEmptyList != nil {
            XCTAssertEqual(nonEmptyList, unarchivedList!)
        }
    }
    
    // MARK: count
    
    func testCountAfterInitialization() {
        XCTAssertEqual(nonEmptyList.count, items.count)
    }
    
    func testCountAfterInsertion() {
        let anotherItem = ListItem(text: "foo")
        
        emptyList.insertItem(anotherItem)
        
        XCTAssertEqual(emptyList.count, 1)
    }
    
    // MARK: indexOfFirstCompletedItem
    
    func testIndexOfFirstCompletedItem() {
        let expectedIndexOfFirstCompletedItem = 3

        let indexOfFirstCompletedItem = nonEmptyList.indexOfFirstCompletedItem
        
        XCTAssertNotNil(indexOfFirstCompletedItem)

        if indexOfFirstCompletedItem != nil {
            XCTAssertEqual(indexOfFirstCompletedItem!, expectedIndexOfFirstCompletedItem)
        }
    }
    
    func testIndexOfFirstCompletedItemIsNilWithNoCompletedItems() {
        for item in items {
            item.isComplete = false
        }
        
        let list = List(color: .Gray, items: items)
        
        XCTAssertNil(list.indexOfFirstCompletedItem)
    }
    
    // MARK: isEmpty
    
    func testIsEmpty() {
        XCTAssertTrue(emptyList.isEmpty)
        XCTAssertFalse(nonEmptyList.isEmpty)
    }

    // MARK: Subscripting
    
    func testSingleSubscript() {
        for (index, item) in enumerate(items) {
            XCTAssertEqual(nonEmptyList[index], item)
        }
    }
    
    func testIndexSetSubscript() {
        // Create an index set to index into the List.
        let indexSet = NSMutableIndexSet()
        indexSet.addIndex(0)
        indexSet.addIndex(2)
        indexSet.addIndex(3)
        
        // Fetch the items from the indexes.
        let indexedItems = nonEmptyList[indexes: indexSet]
        
        // Test to make sure that the index set fetches all the list items we expect.
        var indexedItemCount = 0
        indexSet.enumerateIndexesUsingBlock { idx, _ in
            let expectedItem = self.items[idx]
            let indexedItem = indexedItems[indexedItemCount]
            
            XCTAssertEqual(expectedItem, indexedItem)

            indexedItemCount++
        }

        XCTAssertEqual(indexedItems.count, indexSet.count)
    }
    
    func testEmptyIndexSetSubscript() {
        let indexedItems = nonEmptyList[indexes: NSIndexSet()]

        XCTAssertTrue(indexedItems.isEmpty)
    }

    // MARK: Index Querying
    
    func testIndexOfItem() {
        for (expectedIndex, expectedItem) in enumerate(items) {
            let foundIndex = nonEmptyList.indexOfItem(expectedItem)

            XCTAssertNotNil(foundIndex)
            
            if foundIndex != nil {
                XCTAssertEqual(foundIndex!, expectedIndex)
            }
        }
    }
    
    func testIndexOfItemThatDoesntExistInTheList() {
        let randomItem = ListItem(text: "foo bar baz qux")
        
        let foundIndex = nonEmptyList.indexOfItem(randomItem)

        XCTAssertNil(foundIndex)
    }
    
    // MARK: Removing Items
    
    func testRemoveItems() {
        // Make sure all of the items are incomplete.
        for item in items {
            item.isComplete = false
        }

        let subsetOfItemsToRemove = [items[0], items[2], items[4]]
        let subsetOfItemsToRemain = [items[1], items[3], items[5]]

        nonEmptyList.removeItems(subsetOfItemsToRemove)
        
        // Make sure that all of the removed items no longer exist in the list.
        for removedItem in subsetOfItemsToRemove {
            let indexOfRemovedItem = nonEmptyList.indexOfItem(removedItem)

            XCTAssertNil(indexOfRemovedItem)
        }
        
        // Make sure that all of the remaining items still exist in the list.
        for remainingItem in subsetOfItemsToRemain {
            let indexOfRemainingItem = nonEmptyList.indexOfItem(remainingItem)

            XCTAssertNotNil(indexOfRemainingItem)
        }
    }
    
    // MARK: canInsertIncompleteItems(_:atIndex:)
    
    func testInsertionWithAtLeastOneCompleteItemAndAnInvalidIndex() {
        let itemsToInsert = [
            ListItem(text: "foo", completed: false),
            ListItem(text: "bar", completed: true),
            ListItem(text: "baz", completed: false),
            ListItem(text: "qux", completed: false)
        ]
        
        let invalidIndex = 10
        
        let canInsertItems = nonEmptyList.canInsertIncompleteItems(itemsToInsert, atIndex: invalidIndex)
        
        XCTAssertFalse(canInsertItems)
    }
    
    func testInsertionWithAtLeaseOneIncompleteItemWithAValidIndex() {
        let itemsToInsert = [
            ListItem(text: "foo", completed: false),
            ListItem(text: "bar", completed: true),
            ListItem(text: "baz", completed: false),
            ListItem(text: "qux", completed: false)
        ]
        
        let validIndex = 0
        
        let canInsertItems = nonEmptyList.canInsertIncompleteItems(itemsToInsert, atIndex: validIndex)

        XCTAssertFalse(canInsertItems)
    }
    
    func testInsertionWithIncompleteItemsButWithAnInvalidIndex() {
        let itemsToInsert = [
            ListItem(text: "foo", completed: false),
            ListItem(text: "bar", completed: false),
            ListItem(text: "baz", completed: false),
            ListItem(text: "qux", completed: false)
        ]
        
        let invalidIndex = 10
        
        let canInsertItems = nonEmptyList.canInsertIncompleteItems(itemsToInsert, atIndex: invalidIndex)
        
        XCTAssertFalse(canInsertItems)
    }
    
    func testInsertionWithIncompleteItemsButWithAValidIndex() {
        let itemsToInsert = [
            ListItem(text: "foo", completed: false),
            ListItem(text: "bar", completed: false),
            ListItem(text: "baz", completed: false),
            ListItem(text: "qux", completed: false)
        ]
        
        let validIndex = 2
        
        let canInsertItems = nonEmptyList.canInsertIncompleteItems(itemsToInsert, atIndex: validIndex)
        
        XCTAssertTrue(canInsertItems)
    }
    
    // MARK: insertItem(_:atIndex:)
    
    func testCompletedItemInsertionWithValidIndex() {
        let completedItem = ListItem(text: "foo", completed: true)

        let completedItemTargetIndex = nonEmptyList.count - 1
        
        nonEmptyList.insertItem(completedItem, atIndex: completedItemTargetIndex)
        
        let completedItemIndexAfterInsertion = nonEmptyList.indexOfItem(completedItem)

        XCTAssertNotNil(completedItemIndexAfterInsertion)
        
        if completedItemIndexAfterInsertion != nil {
            XCTAssertEqual(completedItemTargetIndex, completedItemIndexAfterInsertion!)
        }
    }
    
    func testIncompleteItemInsertionWithValidIndex() {
        let incompleteItem = ListItem(text: "foo", completed: false)
        
        let incompleteItemTargetIndex = 0
        
        nonEmptyList.insertItem(incompleteItem, atIndex: incompleteItemTargetIndex)
        
        let incompleteItemIndexAfterInsertion = nonEmptyList.indexOfItem(incompleteItem)

        XCTAssertNotNil(incompleteItemIndexAfterInsertion)
        
        if incompleteItemIndexAfterInsertion != nil {
            XCTAssertEqual(incompleteItemTargetIndex, incompleteItemIndexAfterInsertion!)
        }
    }

    // MARK: insertItem(_:)
    
    func testInsertCompleteItem() {
        let completeItem = ListItem(text: "foo", completed: true)
        
        let itemCountBeforeInsertion = nonEmptyList.count
        
        let insertedIndex = nonEmptyList.insertItem(completeItem)
        
        XCTAssertEqual(itemCountBeforeInsertion, insertedIndex)
    }
    
    func testInsertIncompleteItem() {
        let incompleteItem = ListItem(text: "foo", completed: false)
        
        let insertedIndex = nonEmptyList.insertItem(incompleteItem)
        
        XCTAssertEqual(0, insertedIndex)
    }
    
    // MARK: insertItems(_:)
    
    func testInsertAllCompleteItems() {
        let completeItems = (1...5).map { ListItem(text: "\($0)", completed: true) }
        
        let expectedInsertedIndexesRange = NSRange(location: nonEmptyList.count, length: completeItems.count)
        let expectedInsertedIndexes = NSIndexSet(indexesInRange: expectedInsertedIndexesRange)
        
        let insertedIndexes = nonEmptyList.insertItems(completeItems)

        XCTAssertEqual(insertedIndexes, expectedInsertedIndexes)
        
        var completeItemsIndex = 0
        insertedIndexes.enumerateIndexesUsingBlock { insertedIndex, _ in
            let insertedItem = completeItems[completeItemsIndex]
            let itemAtInsertedIndex = self.nonEmptyList[insertedIndex]
            
            XCTAssertEqual(insertedItem, itemAtInsertedIndex)
            
            completeItemsIndex++
        }
    }
    
    func testInsertAllIncompleteItems() {
        let incompleteItems = (1...5).map { ListItem(text: "\($0)", completed: false) }
        
        let expectedInsertedIndexesRange = NSRange(location: 0, length: incompleteItems.count)
        let expectedInsertedIndexes = NSIndexSet(indexesInRange: expectedInsertedIndexesRange)
        
        let insertedIndexes = nonEmptyList.insertItems(incompleteItems)
        
        XCTAssertEqual(insertedIndexes, expectedInsertedIndexes)
        
        var incompleteItemsIndex = 0
        insertedIndexes.enumerateIndexesUsingBlock { insertedIndex, _ in
            let insertedItem = incompleteItems[incompleteItemsIndex]
            let itemAtInsertedIndex = self.nonEmptyList[insertedIndex]
            
            XCTAssertEqual(insertedItem, itemAtInsertedIndex)
            
            incompleteItemsIndex++
        }
    }
    
    func testInsertMixMatchOfCompleteAndIncompleteItems() {
        let incompleteItem = ListItem(text: "foo", completed: false)
        let completeItem = ListItem(text: "bar", completed: true)

        let expectedIncompleteItemIndex = 0

        let expectedCompleteItemIndex = nonEmptyList.count + 1
        
        let insertedIndexes = nonEmptyList.insertItems([completeItem, incompleteItem])
        
        let insertedIncompleteItemIndex = insertedIndexes.firstIndex
        let insertedCompleteItemIndex = insertedIndexes.lastIndex
        
        XCTAssertEqual(insertedIncompleteItemIndex, expectedIncompleteItemIndex)
        XCTAssertEqual(insertedCompleteItemIndex, expectedCompleteItemIndex)

        XCTAssertEqual(insertedIndexes.count, 2)
        
        let incompleteItemAtInsertedIndex = nonEmptyList[expectedIncompleteItemIndex]
        let completeItemAtInsertedIndex = nonEmptyList[expectedCompleteItemIndex]
        
        XCTAssertEqual(incompleteItemAtInsertedIndex, incompleteItem)
        XCTAssertEqual(completeItemAtInsertedIndex, completeItem)
    }
    
    // MARK: updateAllItemsToCompletionState(_:)
    
    func testUpdateAllItemsToCompletionState() {
        for item in items {
            item.isComplete = false
        }

        nonEmptyList.updateAllItemsToCompletionState(true)
        
        for item in nonEmptyList.items {
            XCTAssertTrue(item.isComplete)
        }
    }
    
    // MARK: toggleItem(_:)
    
    func testToggleIncompleteItem() {
        let startItemIndex = 2
        let item = nonEmptyList[startItemIndex]
        
        let preferredTargetIndex = 4

        let (fromIndex, toIndex) = nonEmptyList.toggleItem(item, preferredTargetIndex: preferredTargetIndex)

        XCTAssertEqual(startItemIndex, fromIndex)
        XCTAssertEqual(preferredTargetIndex, toIndex)
    }
    
    func testToggleIncompleteItemWithNilPreferredTargetIndex() {
        let startItemIndex = 2
        let item = nonEmptyList[startItemIndex]
        
        let (fromIndex, toIndex) = nonEmptyList.toggleItem(item, preferredTargetIndex: nil)
        
        XCTAssertEqual(startItemIndex, fromIndex)
        XCTAssertEqual(nonEmptyList.count - 1, toIndex)
    }

    func testToggleIncompleteItemWithoutPreferredTargetIndex() {
        let startItemIndex = 2
        let item = nonEmptyList[startItemIndex]

        let (fromIndex, toIndex) = nonEmptyList.toggleItem(item)

        XCTAssertEqual(startItemIndex, fromIndex)
        XCTAssertEqual(nonEmptyList.count - 1, toIndex)
    }

    func testToggleCompleteItem() {
        let startItemIndex = 4
        let item = nonEmptyList[startItemIndex]
        
        let preferredTargetIndex = 2
        
        let (fromIndex, toIndex) = nonEmptyList.toggleItem(item, preferredTargetIndex: preferredTargetIndex)
        
        XCTAssertEqual(startItemIndex, fromIndex)
        XCTAssertEqual(preferredTargetIndex, toIndex)
    }

    func testToggleCompleteItemWithNilPreferredTargetIndex() {
        let startItemIndex = 4
        let item = nonEmptyList[startItemIndex]
        
        let indexOfFirstCompletedItemBeforeToggle = nonEmptyList.indexOfFirstCompletedItem!
        
        let (fromIndex, toIndex) = nonEmptyList.toggleItem(item, preferredTargetIndex: nil)
        
        XCTAssertEqual(startItemIndex, fromIndex)

        XCTAssertEqual(indexOfFirstCompletedItemBeforeToggle, toIndex)
    }
    
    func testToggleCompleteItemWithoutPreferredTargetIndex() {
        let startItemIndex = 4
        let item = nonEmptyList[startItemIndex]
        
        let indexOfFirstCompletedItemBeforeToggle = nonEmptyList.indexOfFirstCompletedItem!
        
        let (fromIndex, toIndex) = nonEmptyList.toggleItem(item)
        
        XCTAssertEqual(startItemIndex, fromIndex)

        XCTAssertEqual(indexOfFirstCompletedItemBeforeToggle, toIndex)
    }
    
    func testToggleOnlyCompleteItemWithNilPreferredTargetIndex() {
        nonEmptyList.toggleItem(nonEmptyList[3])
        nonEmptyList.toggleItem(nonEmptyList[4])
        
        let startItemIndex = 5
        let item = nonEmptyList[startItemIndex]
        
        let (fromIndex, toIndex) = nonEmptyList.toggleItem(item)
        
        XCTAssertEqual(startItemIndex, fromIndex)
        
        XCTAssertEqual(startItemIndex, fromIndex)
    }
    
    // MARK: canMoveItem(_:toIndex:inclusive:)
    
    func testCanMoveCompleteItemToInvalidIndexInclusive() {
        let completeItem = nonEmptyList.items.last!
        let invalidMoveIndex = 0
        
        let canMove = nonEmptyList.canMoveItem(completeItem, toIndex: invalidMoveIndex, inclusive: true)

        XCTAssertFalse(canMove)
    }
    
    func testCanMoveCompleteItemToInvalidIndexNotInclusive() {
        let completeItem = nonEmptyList.items.last!
        let invalidMoveIndex = 1

        let canMove = nonEmptyList.canMoveItem(completeItem, toIndex: invalidMoveIndex, inclusive: false)

        XCTAssertFalse(canMove)
    }
    
    func testCanMoveCompleteItemToValidIndexInclusive() {
        let completeItem = nonEmptyList.items.last!
        let validMoveIndex = nonEmptyList.indexOfFirstCompletedItem!
        
        let canMove = nonEmptyList.canMoveItem(completeItem, toIndex: validMoveIndex, inclusive: true)
        
        XCTAssertTrue(canMove)
    }
    
    func testCanMoveCompleteItemToValidIndexNotInclusive() {
        let completeItem = nonEmptyList.items.last!
        let validMoveIndex = nonEmptyList.indexOfFirstCompletedItem!
        
        let canMove = nonEmptyList.canMoveItem(completeItem, toIndex: validMoveIndex, inclusive: false)
        
        XCTAssertTrue(canMove)
    }

    func testCanMoveIncompleteItemToInvalidIndexInclusive() {
        let incompleteItem = nonEmptyList.items.first!
        let invalidMoveIndex = nonEmptyList.count - 1

        let canMove = nonEmptyList.canMoveItem(incompleteItem, toIndex: invalidMoveIndex, inclusive: true)

        XCTAssertFalse(canMove)
    }
    
    func testCanMoveIncompleteItemToInvalidIndexNotInclusive() {
        let incompleteItem = nonEmptyList.items.first!
        let invalidMoveIndex = nonEmptyList.count - 1
        
        let canMove = nonEmptyList.canMoveItem(incompleteItem, toIndex: invalidMoveIndex, inclusive: false)
        
        XCTAssertFalse(canMove)
    }
    
    func testCanMoveIncompleteItemToValidIndexInclusive() {
        let incompleteItem = nonEmptyList.items.first!
        let validMoveIndex = nonEmptyList.indexOfFirstCompletedItem!
        
        let canMove = nonEmptyList.canMoveItem(incompleteItem, toIndex: validMoveIndex, inclusive: true)
        
        XCTAssertTrue(canMove)
    }
    
    func testCanMoveIncompleteItemToValidIndexNotInclusive() {
        let incompleteItem = nonEmptyList.items.first!
        let invalidMoveIndex = nonEmptyList.indexOfFirstCompletedItem!
        let validMoveIndex = nonEmptyList.indexOfFirstCompletedItem! - 1
        
        let canMoveToInvalidIndex = nonEmptyList.canMoveItem(incompleteItem, toIndex: invalidMoveIndex, inclusive: false)
        let canMoveToValidIndex = nonEmptyList.canMoveItem(incompleteItem, toIndex: validMoveIndex, inclusive: false)
        
        XCTAssertFalse(canMoveToInvalidIndex)
        XCTAssertTrue(canMoveToValidIndex)
    }
    
    // MARK: moveItem(_:toIndex:)
    
    func testMoveCompleteItemToCompleteIndex() {
        let initialCompleteItemIndex = nonEmptyList.indexOfFirstCompletedItem! + 1

        let completeItem = nonEmptyList[initialCompleteItemIndex]
        
        let destinationIndex = nonEmptyList.indexOfFirstCompletedItem!
        
        let movedIndexes = nonEmptyList.moveItem(completeItem, toIndex: destinationIndex)
        
        XCTAssertEqual(movedIndexes.fromIndex, initialCompleteItemIndex)
        XCTAssertEqual(movedIndexes.toIndex, destinationIndex)
        
        let movedItem = nonEmptyList[destinationIndex]
        
        XCTAssertEqual(movedItem, completeItem)
    }

    func testMoveIncompleteItemToIncompleteIndex() {
        let initialIncompleteItemIndex = 1
        
        let incompleteItem = nonEmptyList[initialIncompleteItemIndex]
        
        let destinationIndex = nonEmptyList.indexOfFirstCompletedItem! - 1

        let movedIndexes = nonEmptyList.moveItem(incompleteItem, toIndex: destinationIndex)

        let movedItem = nonEmptyList[movedIndexes.toIndex]
        
        XCTAssertEqual(movedItem, incompleteItem)
    }

    // MARK: Equality
    
    func testIsEqual() {
        let listOne = List(color: .Gray, items: items)
        let listTwo = List(color: .Gray, items: items)
        let listThree = List(color: .Green, items: items)
        let listFour = List(color: .Gray, items: [])

        XCTAssertEqual(listOne, listTwo)
        XCTAssertNotEqual(listTwo, listThree)
        XCTAssertNotEqual(listTwo, listFour)
    }

    // MARK: Archive Compatibility
    
    /**
        Ensure that the runtime name of the `List` class is "AAPLList". This is to ensure compatibility
        with the Objective-C version of the app that archives its data with the `AAPLList` class.
    */
    func testClassRuntimeNameForArchiveCompatibility() {
        let classRuntimeName = NSStringFromClass(List.self)
        
        XCTAssertEqual(classRuntimeName!, "AAPLList", "List should be archivable with the ObjC version of Lister.")
    }
}

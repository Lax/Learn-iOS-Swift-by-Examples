/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The test case class for the `AllListItemsPresenter` class.
*/

import ListerKit
import XCTest

class AllListItemsPresenterTests: XCTestCase {
    // MARK: Properties
    
    var presenter: AllListItemsPresenter!
    
    let initiallyIncompleteListItems = [
        ListItem(text: "1", complete: false),
        ListItem(text: "3", complete: false)
    ]
    
    let initiallyCompleteListItems = [
        ListItem(text: "0", complete: true),
        ListItem(text: "2", complete: true),
        ListItem(text: "4", complete: true)
    ]

    var presentedListItems: [ListItem] {
        return initiallyIncompleteListItems + initiallyCompleteListItems
    }
    
    var initialListItemCount: Int!

    var list: List!
    
    var testHelper: ListPresenterTestHelper!

    var undoManager: NSUndoManager {
        return presenter.undoManager!
    }
    
    // MARK: XCTest Life Time

    override func setUp() {
        initialListItemCount = presentedListItems.count
        
        let unorderedListItems = [
            initiallyCompleteListItems[0],
            initiallyIncompleteListItems[0],
            initiallyCompleteListItems[1],
            initiallyIncompleteListItems[1],
            initiallyCompleteListItems[2]
        ]

        list = List(color: .Green, items: unorderedListItems)

        // Create the presenter.
        presenter = AllListItemsPresenter()
        
        presenter.setList(list)

        presenter.undoManager = NSUndoManager()

        testHelper = ListPresenterTestHelper()

        presenter.delegate = testHelper
    }
    
    // MARK: Test Initializers

    func testItemInitializationReshufflingWithOutOfOrderItems() {
        XCTAssertEqual(presenter.presentedListItems, presentedListItems, "Incomplete items should be followed by complete items once the presenter is instantiated.")
    }
    
    func testItemInitializationNoReshufflingCaseWhenItemsAreAlreadyInOrder() {
        let incompleteListItems = map(1...5) { ListItem(text: "\($0)", complete: false) }
        let incompleteList = List(color: .Green, items: incompleteListItems)
        let incompletePresenter = AllListItemsPresenter()
        incompletePresenter.setList(incompleteList)
        
        let completeListItems = map(1...5) { ListItem(text: "\($0)", complete: true) }
        let completeList = List(color: .Green, items: completeListItems)
        let completePresenter = AllListItemsPresenter()
        completePresenter.setList(completeList)
        
        let orderedCombinedListItems = incompleteListItems + completeListItems
        let orderedCombinedList = List(color: .Green, items: orderedCombinedListItems)
        let orderedCombinedPresenter = AllListItemsPresenter()
        orderedCombinedPresenter.setList(orderedCombinedList)
        
        XCTAssertEqual(incompleteListItems, incompletePresenter.presentedListItems, "Items that are all incomplete should not be reconfigured after the presenter is instantiated.")
        XCTAssertEqual(completeListItems, completePresenter.presentedListItems, "Items that are all complete should not be reconfigured after the presenter is instantiated.")
        XCTAssertEqual(orderedCombinedListItems, orderedCombinedPresenter.presentedListItems, "Incomplete items followed by complete items should not be reconfigured after the presenter is instantiated.")
    }
    
    // MARK: `color`
    
    func testSetColorWithDifferentColor() {
        let newColor = List.Color.Orange
        
        testHelper.whenNextChangesOccur(assert: {
            XCTAssertEqual(self.presenter.color, newColor, "The getter for the color should return the new color.")

            let didUpdateListColorCallbackCount = self.testHelper.didUpdateListColorCallbacks.count
            XCTAssertEqual(didUpdateListColorCallbackCount, 1, "There should be one \"list color update\" callback.")

            if didUpdateListColorCallbackCount != 1 { return }

            let updatedColor = self.testHelper.didUpdateListColorCallbacks.first!
            XCTAssertEqual(updatedColor, newColor, "The delegate callback should provide the new color.")
        })

        presenter.color = newColor
    }
    
    func testSetColorWithDifferentColorAfterUndo() {
        let initialListColor = presenter.color
        
        presenter.color = .Orange
        
        testHelper.whenNextChangesOccur(assert: {
            XCTAssertEqual(self.presenter.color, initialListColor, "The getter for the color should return the initial color.")
            
            let didUpdateListColorCallbackCount = self.testHelper.didUpdateListColorCallbacks.count
            XCTAssertEqual(didUpdateListColorCallbackCount, 1, "There should be one \"list color update\" callback.")
            
            if didUpdateListColorCallbackCount != 1 { return }
            
            let newColor = self.testHelper.didUpdateListColorCallbacks.first!
            XCTAssertEqual(newColor, initialListColor, "The delegate callback should provide the initial color.")
        })
        
        undoManager.undo()
    }
    
    // MARK: `insertListItem(_:)`
    
    func testInsertIncompleteListItem() {
        let incompleteListItem = ListItem(text: "foo", complete: false)
        
        testHelper.whenNextChangesOccur(assert: {
            let didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count
            
            XCTAssertEqual(didInsertListItemCallbackCount, 1, "Only one item should be inserted.")
            
            if didInsertListItemCallbackCount != 1 { return }
            
            let (listItem, insertedIndex) = self.testHelper.didInsertListItemCallbacks.first!
            
            XCTAssertEqual(incompleteListItem, listItem, "The inserted item should be the same as the item the delegate receives.")
            
            XCTAssertEqual(insertedIndex, 0, "The incomplete item should be inserted at the top of the list.")
        })
        
        presenter.insertListItem(incompleteListItem)
    }

    func testInsertCompleteListItem() {
        let completeListItem = ListItem(text: "foo", complete: true)
        
        testHelper.whenNextChangesOccur(assert: {
            let didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count
            
            XCTAssertEqual(didInsertListItemCallbackCount, 1, "Only one item should be inserted.")
            
            if didInsertListItemCallbackCount != 1 { return }
            
            let (listItem, insertedIndex) = self.testHelper.didInsertListItemCallbacks.first!
            
            XCTAssertEqual(completeListItem, listItem, "The inserted item should be the same as the item the delegate receives.")
            
            XCTAssertEqual(insertedIndex, self.initialListItemCount, "The complete item should be inserted at the bottom of the list.")
        })
        
        presenter.insertListItem(completeListItem)
    }

    func testInsertListItemAfterUndo() {
        let listItemToInsert = ListItem(text: "foo", complete: false)
        
        presenter.insertListItem(listItemToInsert)
        
        testHelper.whenNextChangesOccur(assert: {
            // Make sure the underlying list is back to its initial state.
            XCTAssertEqual(self.presentedListItems, self.presenter.presentedListItems, "The list should be the same after a change + undo.")
            
            let didRemoveListItemCallbackCount = self.testHelper.didRemoveListItemCallbacks.count
            
            XCTAssertEqual(didRemoveListItemCallbackCount, 1, "Only one item should be removed.")
            
            if didRemoveListItemCallbackCount != 1 { return }
            
            let (listItem, removedIndex) = self.testHelper.didRemoveListItemCallbacks.first!
            
            XCTAssertEqual(listItem, listItemToInsert, "The removed item should be the item we initially inserted.")
        })
        
        undoManager.undo()
    }
    
    // MARK: `insertListItems(_:)`
    
    func testInsertListItems() {
        let listItemsToInsert = [
            ListItem(text: "0", complete: false),
            ListItem(text: "1", complete: true),
            ListItem(text: "2", complete: false)
        ]
        
        let listItemsToInsertWithExpectedInsertedIndexes = [
            listItemsToInsert[0]: 0,
            listItemsToInsert[1]: initialListItemCount + 1,
            listItemsToInsert[2]: 0
        ]

        testHelper.whenNextChangesOccur(assert: {
            let didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count
            XCTAssertEqual(didInsertListItemCallbackCount, listItemsToInsert.count, "Only one item should be inserted.")
            
            if didInsertListItemCallbackCount != listItemsToInsert.count { return }
            
            for (listItem, insertedIndex) in self.testHelper.didInsertListItemCallbacks {
                XCTAssertTrue(contains(listItemsToInsert, listItem), "The inserted item should be one of the items we wanted to insert.")
                
                if let expectedInsertedIndex = listItemsToInsertWithExpectedInsertedIndexes[listItem] {
                    XCTAssertEqual(expectedInsertedIndex, insertedIndex, "The items should be inserted at the expected indexes.")
                }
            }
        })
        
        presenter.insertListItems(listItemsToInsert)
    }
    
    func testInsertListItemsAfterUndo() {
        let listItemsToInsert = [
            ListItem(text: "0", complete: false),
            ListItem(text: "1", complete: true),
            ListItem(text: "2", complete: false)
        ]
        
        presenter.insertListItems(listItemsToInsert)

        testHelper.whenNextChangesOccur(assert: {
            // Make sure the underlying list is back to its initial state.
            XCTAssertEqual(self.presentedListItems, self.presenter.presentedListItems, "The list should be the same after a change + undo.")
            
            let didRemoveListItemCallbackCount = self.testHelper.didRemoveListItemCallbacks.count
            
            XCTAssertEqual(didRemoveListItemCallbackCount, listItemsToInsert.count, "Only one item should be removed.")
            
            if didRemoveListItemCallbackCount != listItemsToInsert.count { return }
            
            for (listItem, removedIndex) in self.testHelper.didRemoveListItemCallbacks {
                XCTAssertTrue(contains(listItemsToInsert, listItem), "The removed item should one of the items we initially inserted.")
            }
        })
        
        undoManager.undo()
    }
    
    // MARK: `removeListItem(_:)`
    
    func testRemoveListItem() {
        let listItemToRemove = presentedListItems[2]
        let indexOfItemToRemove = find(presenter.presentedListItems, listItemToRemove)!

        testHelper.whenNextChangesOccur(assert: {
            let didRemoveListItemCallbackCount = self.testHelper.didRemoveListItemCallbacks.count
            XCTAssertEqual(didRemoveListItemCallbackCount, 1, "Only one item should be removed.")
            
            if didRemoveListItemCallbackCount != 1 { return }
            
            let (listItem, removedIndex) = self.testHelper.didRemoveListItemCallbacks.first!
            
            XCTAssertEqual(listItemToRemove, listItem, "The removed item should be the same as the item the delegate receives.")
            
            XCTAssertEqual(removedIndex, indexOfItemToRemove, "The incomplete item should be removed at the index it was before removal.")
        })

        presenter.removeListItem(listItemToRemove)
    }
    
    func testRemoveListItemAfterUndo() {
        let listItemToRemove = presentedListItems[2]
        
        let indexOfItemToRemove = find(presenter.presentedListItems, listItemToRemove)!
        
        presenter.removeListItem(listItemToRemove)
        
        testHelper.whenNextChangesOccur(assert: {
            // Make sure the underlying list is back to its initial state.
            XCTAssertEqual(self.presentedListItems, self.presenter.presentedListItems, "The list should be the same after a change + undo.")
            
            let didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count
            
            XCTAssertEqual(didInsertListItemCallbackCount, 1, "Only one item should be inserted.")
            
            if didInsertListItemCallbackCount != 1 { return }
            
            let (listItem, insertedIndex) = self.testHelper.didInsertListItemCallbacks.first!
            
            XCTAssertEqual(listItem, listItemToRemove, "The inserted item should be the item we initially removed.")
            
            XCTAssertEqual(insertedIndex, indexOfItemToRemove, "The inserted index should be the same as the list item's initial index.")
        })

        undoManager.undo()
    }
    
    // MARK: `removeListItems(_:)`
    
    func testRemoveListItems() {
        let listItemsToRemove = [
            presentedListItems[0],
            presentedListItems[3],
            presentedListItems[2]
        ]
        
        let listItemsToRemoveWithExpectedRemovedIndex = [
            listItemsToRemove[0]: 0,
            listItemsToRemove[1]: 2,
            listItemsToRemove[2]: 1
        ]
        
        testHelper.whenNextChangesOccur(assert: {
            let didRemoveListItemsCallbackCount = self.testHelper.didRemoveListItemCallbacks.count
            
            XCTAssertEqual(didRemoveListItemsCallbackCount, listItemsToRemove.count, "There should be \(listItemsToRemove.count) elements removed.")
            
            if didRemoveListItemsCallbackCount != listItemsToRemove.count { return }
            
            for (listItem, removedIndex) in self.testHelper.didRemoveListItemCallbacks {
                XCTAssertTrue(contains(listItemsToRemove, listItem), "The removed item should be one of the items we wanted to remove.")
                
                if let expectedRemovedIndex = listItemsToRemoveWithExpectedRemovedIndex[listItem] {
                    XCTAssertEqual(removedIndex, expectedRemovedIndex, "The items should be removed at the expected indexes.")
                }
            }
        })
        
        presenter.removeListItems(listItemsToRemove)
    }
    
    func testRemoveListItemsAfterUndo() {
        let listItemsToRemove = [
            presentedListItems[0],
            presentedListItems[3],
            presentedListItems[2]
        ]
        
        presenter.removeListItems(listItemsToRemove)
        
        testHelper.whenNextChangesOccur(assert: {
            // Make sure the underlying list is back to its initial state.
            XCTAssertEqual(self.presentedListItems, self.presenter.presentedListItems, "The list should be the same after a change + undo.")
            
            let didInsertListItemCallbackCount = self.testHelper.didInsertListItemCallbacks.count
            
            XCTAssertEqual(didInsertListItemCallbackCount, listItemsToRemove.count, "Only one item should be inserted.")
            
            if didInsertListItemCallbackCount != listItemsToRemove.count { return }
            
            for (listItem, insertedIndex) in self.testHelper.didRemoveListItemCallbacks {
                XCTAssertTrue(contains(listItemsToRemove, listItem), "The inserted item should one of the items we initially removed.")
            }
        })
        
        undoManager.undo()
    }
    
    // MARK: `canMoveListItem(_:toIndex:)`
    
    func testCanMoveIncompleteListItem() {
        let incompleteListItem = presentedListItems[1]
        
        let canMoveWithinIncomplete = presenter.canMoveListItem(incompleteListItem, toIndex: 0)
        let canMoveToComplete = presenter.canMoveListItem(incompleteListItem, toIndex: 4)
        let canMoveToBoundary = presenter.canMoveListItem(incompleteListItem, toIndex: 2)
        
        XCTAssertTrue(canMoveWithinIncomplete, "An incomplete item can move within the incomplete items.")
        XCTAssertFalse(canMoveToComplete, "An incomplete item cannot move to the complete items.")
        XCTAssertFalse(canMoveToBoundary, "An incomplete item cannot move to the complete side of the boundary between complete and incomplete.")
    }

    func testCanMoveCompleteListItem() {
        let completeListItem = presentedListItems[4]
        
        let canMoveWithinComplete = presenter.canMoveListItem(completeListItem, toIndex: 3)
        let canMoveToIncomplete = presenter.canMoveListItem(completeListItem, toIndex: 0)
        let canMoveToBoundary = presenter.canMoveListItem(completeListItem, toIndex: 1)
        
        XCTAssertTrue(canMoveWithinComplete, "A complete item can move within the complete items.")
        XCTAssertFalse(canMoveToIncomplete, "A complete item cannot move to the incomplete items.")
        XCTAssertFalse(canMoveToBoundary, "A complete item cannot move to the incomplete side of the boundary between complete and incomplete.")
    }
    
    // MARK: `moveListItem(_:toIndex:)`
    
    func testMoveListItemAboveListItem() {
        let listItemToRemoveIndex = 1
        let listItemDestinationIndex = 0
        let listItemToRemove = presentedListItems[listItemToRemoveIndex]
        
        testHelper.whenNextChangesOccur(assert: {
            let didMoveListItemsCallbackCount = self.testHelper.didMoveListItemCallbacks.count
            
            XCTAssertEqual(didMoveListItemsCallbackCount, 1, "There should one elements moved.")
            
            let (listItem, fromIndex, toIndex) = self.testHelper.didMoveListItemCallbacks.first!
            
            XCTAssertEqual(listItem, listItemToRemove, "The moved item should be the item we wanted to move.")
            
            XCTAssertEqual(fromIndex, listItemToRemoveIndex, "The item should be moved at the item's initial index.")
            
            XCTAssertEqual(toIndex, listItemDestinationIndex, "The item should be moved to the destination index.")
        })
        
        presenter.moveListItem(listItemToRemove, toIndex: listItemDestinationIndex)
    }
    
    func testMoveListItemAboveListItemAfterUndo() {
        let listItemToRemoveIndex = 1
        let listItemDestinationIndex = 0
        let listItemToRemove = presentedListItems[listItemToRemoveIndex]
        
        presenter.moveListItem(listItemToRemove, toIndex: listItemDestinationIndex)
        
        testHelper.whenNextChangesOccur(assert: {
            // Make sure the underlying list is back to its initial state.
            XCTAssertEqual(self.presentedListItems, self.presenter.presentedListItems, "The list should be the same after a change + undo.")
            
            let didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count
            
            XCTAssertEqual(didMoveListItemCallbackCount, 1, "One move should occur the undo.")
            
            if didMoveListItemCallbackCount != 2 { return }
            
            let (listItem, fromIndex, toIndex) = self.testHelper.didMoveListItemCallbacks[1]
            
            XCTAssertEqual(listItem, listItemToRemove, "The moved item should be the item we initially moved.")
            
            XCTAssertEqual(fromIndex, listItemDestinationIndex, "`fromIndex` should be the same as the list item's initial destination index.")

            XCTAssertEqual(toIndex, listItemToRemoveIndex + 1, "`toIndex` should be the same as the list item's initial index.")
        })
        
        undoManager.undo()
    }
    
    func testMoveListItemBelowListItem() {
        let listItemToMoveIndex = 3
        let listItemDestinationIndex = 4
        let listItemToMove = presentedListItems[listItemToMoveIndex]
        
        testHelper.whenNextChangesOccur(assert: {
            let didMoveListItemsCallbackCount = self.testHelper.didMoveListItemCallbacks.count
            
            XCTAssertEqual(didMoveListItemsCallbackCount, 1, "There should one elements moved.")
            
            let (listItem, fromIndex, toIndex) = self.testHelper.didMoveListItemCallbacks.first!
            
            XCTAssertEqual(listItem, listItemToMove, "The moved item should be the item we wanted to move.")
            
            XCTAssertEqual(fromIndex, listItemToMoveIndex, "The item should be moved at the item's initial index.")
            
            XCTAssertEqual(toIndex, listItemDestinationIndex, "The item should be moved to the destination index.")
        })
        
        presenter.moveListItem(listItemToMove, toIndex: listItemDestinationIndex)
    }
    
    func testMoveListItemBelowListItemAfterUndo() {
        let listItemToRemoveIndex = 3
        let listItemDestinationIndex = 4
        let listItemToRemove = presentedListItems[listItemToRemoveIndex]

        presenter.moveListItem(listItemToRemove, toIndex: listItemDestinationIndex)
        
        testHelper.whenNextChangesOccur(assert: {
            // Make sure the underlying list is back to its initial state.
            XCTAssertEqual(self.presentedListItems, self.presenter.presentedListItems, "The list should be the same after a change + undo.")
            
            let didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count
            
            XCTAssertEqual(didMoveListItemCallbackCount, 1, "One move should occur after the undo.")
            
            if didMoveListItemCallbackCount != 1 { return }
            
            let (listItem, fromIndex, toIndex) = self.testHelper.didMoveListItemCallbacks.first!
            
            XCTAssertEqual(listItem, listItemToRemove, "The moved item should be the item we initially moved.")
            XCTAssertEqual(fromIndex, listItemDestinationIndex, "`fromIndex` should be the same as the list item's initial destination index.")
            XCTAssertEqual(toIndex, listItemToRemoveIndex, "`toIndex` should be the same as the list item's initial index.")
        })
        
        undoManager.undo()
    }
    
    // MARK: `toggleListItem(_:)`
    
    func testToggleIncompleteListItem() {
        let incompleteListItem = initiallyIncompleteListItems[1]
        
        let expectedFromIndex = 1
        let expectedToIndex = initialListItemCount - 1
        
        testHelper.whenNextChangesOccur(assert: {
            // Test for item toggling.
            let didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count
            XCTAssertEqual(didMoveListItemCallbackCount, 1, "There should be one \"move\" callback.")
            
            if didMoveListItemCallbackCount != 1 { return }
            
            let (movedListItem, fromIndex, toIndex) = self.testHelper.didMoveListItemCallbacks.first!
            
            XCTAssertEqual(movedListItem, incompleteListItem, "The delegate should receive the \"move\" callback with the toggled list item.")
            XCTAssertEqual(fromIndex, expectedFromIndex, "The delegate should move the item from the right start index.")
            XCTAssertEqual(toIndex, expectedToIndex, "The delegate should move the item to the right end index.")
            
            // Test for item updating.
            let didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count
            XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.")
            
            if didUpdateListItemCallbackCount != 1 { return }
            
            let (updatedListItem, updatedIndex) = self.testHelper.didUpdateListItemCallbacks.first!
            
            XCTAssertEqual(updatedListItem, incompleteListItem, "The delegate should receive the \"update\" callback with the toggled list item.")
            
            XCTAssertTrue(incompleteListItem.isComplete, "The item should be complete after the toggle.")
            XCTAssertEqual(updatedIndex, expectedToIndex, "The item should be updated in place.")
        })
        
        presenter.toggleListItem(incompleteListItem)
    }
    
    func testToggleCompleteListItem() {
        let completeListItem = initiallyCompleteListItems[2]
        
        let expectedFromIndex = find(presentedListItems, completeListItem)!
        let expectedToIndex = 0
        
        testHelper.whenNextChangesOccur(assert: {
            // Test for item moving.
            let didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count
            XCTAssertEqual(didMoveListItemCallbackCount, 1, "There should be one \"move\" callback.")
            
            if didMoveListItemCallbackCount != 1 { return }
            
            let (listItem, fromIndex, toIndex) = self.testHelper.didMoveListItemCallbacks.first!
            
            XCTAssertEqual(listItem, completeListItem, "The delegate should receive the \"move\" callback with the toggled list item.")
            XCTAssertEqual(fromIndex, expectedFromIndex, "The delegate should move the item from the right start index.")
            XCTAssertEqual(toIndex, expectedToIndex, "The delegate should move the item to the right end index.")
            
            // Test for item updating.
            let didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count
            XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.")
            
            if didUpdateListItemCallbackCount != 1 { return }
            
            let (updatedListItem, updatedIndex) = self.testHelper.didUpdateListItemCallbacks.first!
            
            XCTAssertEqual(updatedListItem, completeListItem, "The delegate should receive the \"update\" callback with the toggled list item.")
            XCTAssertFalse(completeListItem.isComplete, "The item should be incomplete after the toggle.")
            XCTAssertEqual(updatedIndex, expectedToIndex, "The item should be updated in place.")
        })

        presenter.toggleListItem(completeListItem)
    }
    
    func testToggleListItemAfterUndo() {
        let listItem = presentedListItems[2]
        
        let expectedFromIndex = find(presentedListItems, listItem)!
        let expectedToIndex = 0
        
        presenter.toggleListItem(listItem)
        
        testHelper.whenNextChangesOccur(assert: {
            // Test for item moving.
            let didMoveListItemCallbackCount = self.testHelper.didMoveListItemCallbacks.count
            XCTAssertEqual(didMoveListItemCallbackCount, 1, "There should be one \"move\" callback.")
            
            if didMoveListItemCallbackCount != 1 { return }
            
            let (movedListItem, fromIndex, toIndex) = self.testHelper.didMoveListItemCallbacks.first!
            
            XCTAssertEqual(movedListItem, listItem, "The delegate should receive the \"move\" callback with the toggled list item.")
            XCTAssertEqual(fromIndex, expectedToIndex, "The delegate should move the item from the right start index.")
            XCTAssertEqual(toIndex, expectedFromIndex, "The delegate should move the item to the right end index.")
            
            // Test for item updating.
            let didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count
            XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.")
            
            if didUpdateListItemCallbackCount != 1 { return }
            
            let (updatedListItem, updatedIndex) = self.testHelper.didUpdateListItemCallbacks.first!
            
            XCTAssertEqual(updatedListItem, listItem, "The delegate should receive the \"update\" callback with the toggled list item.")
            XCTAssertTrue(listItem.isComplete, "The item should be complete after the toggle.")
            XCTAssertEqual(updatedIndex, expectedFromIndex, "The item should be updated in place.")
        })
        
        undoManager.undo()
    }

    // MARK: `updateListItem(_:withText:)`
    
    func testUpdateListItemWithText() {
        let listItemIndex = 2
        let listItem = presentedListItems[listItemIndex]
        
        let newText = "foo bar baz qux"
        
        testHelper.whenNextChangesOccur(assert: {
            let didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count
            XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.")
            
            if didUpdateListItemCallbackCount != 1 { return }
            
            let (updatedListItem, updatedListItemIndex) = self.testHelper.didUpdateListItemCallbacks.first!
            
            XCTAssertEqual(updatedListItem, listItem, "The update list item should be the same as our provided list item.")
            XCTAssertEqual(updatedListItemIndex, listItemIndex, "The update should be an in-place update.")
            XCTAssertEqual(updatedListItem.text, newText, "The text should be updated.")
        })

        presenter.updateListItem(listItem, withText: newText)
    }
    
    func testUpdateListItemWithTextAfterUndo() {
        let listItemIndex = 2
        let listItem = presentedListItems[listItemIndex]
        let initialListItemText = listItem.text
        
        testHelper.whenNextChangesOccur(assert: {
            let didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count
            XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.")
            
            if didUpdateListItemCallbackCount != 2 { return }
            
            let (updatedListItem, updatedListItemIndex) = self.testHelper.didUpdateListItemCallbacks[1]
            
            XCTAssertEqual(updatedListItem, listItem, "The update list item should be the same as our provided list item.")
            XCTAssertEqual(updatedListItemIndex, listItemIndex, "The update should be an in-place update.")
            XCTAssertEqual(updatedListItem.text, initialListItemText, "The text should be updated to its initial value.")
        })
        
        undoManager.undo()
    }

    // MARK: `updatePresentedListItemsToCompletionState(_:)`

    func testUpdatePresentedListItemsToCompletionState() {
        testHelper.whenNextChangesOccur(assert: {
            XCTAssertEqual(self.testHelper.didUpdateListItemCallbacks.count, self.initiallyIncompleteListItems.count, "There should be one \"event\" per incomplete, presented item.")

            for (listItem, updatedIndex) in self.testHelper.didUpdateListItemCallbacks {
                if let indexOfUpdatedListItem = find(self.presentedListItems, listItem) {
                    XCTAssertEqual(updatedIndex, indexOfUpdatedListItem, "The updated index should be the same as the initial index.")

                    XCTAssertTrue(listItem.isComplete, "The item should be complete after the update.")
                }
                else {
                    XCTFail("One of the updated list items was never supposed to be in the list.")
                }
            }
        })

        presenter.updatePresentedListItemsToCompletionState(true)
    }

    func testUpdatePresentedListItemsToCompletionStateAfterUndo() {
        presenter.updatePresentedListItemsToCompletionState(true)

        testHelper.whenNextChangesOccur(assert: {
            var presentedListItemsCopy = self.presentedListItems.map { $0.copy() as! ListItem }

            XCTAssertEqual(self.testHelper.didUpdateListItemCallbacks.count, self.initiallyIncompleteListItems.count, "The undo should perform \(self.presentedListItems.count) updates to revert the previous update for each modified item.")

            for (listItem, updatedIndex) in self.testHelper.didUpdateListItemCallbacks {
                if let indexOfUpdatedListItem = find(presentedListItemsCopy, listItem) {
                    let listItemCopy = presentedListItemsCopy[indexOfUpdatedListItem]

                    XCTAssertEqual(updatedIndex, indexOfUpdatedListItem, "The updated index should be the same as the initial index.")

                    XCTAssertEqual(listItem, listItemCopy, "The item should be the same as the initial item after the update.")
                }
                else {
                    XCTFail("One of the updated list items was never supposed to be in the list.")
                }
            }
        })

        undoManager.undo()
    }
}
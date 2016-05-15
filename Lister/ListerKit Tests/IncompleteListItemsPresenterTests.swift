/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The test case class for the `IncompleteListItemsPresenter` class.
*/

import ListerKit
import XCTest

class IncompleteListItemsPresenterTests: XCTestCase {
    // MARK: Properties
    
    let initiallyIncompleteListItems = [
        ListItem(text: "0", complete: false),
        ListItem(text: "1", complete: false),
        ListItem(text: "2", complete: false),
        ListItem(text: "3", complete: false)
    ]
    
    let initiallyCompleteListItems = [
        ListItem(text: "4", complete: true),
        ListItem(text: "5", complete: true),
        ListItem(text: "6", complete: true)
    ]
    
    var presentedListItems: [ListItem] {
        return (initiallyIncompleteListItems + initiallyCompleteListItems).filter { !$0.isComplete }
    }
    
    var list: List!

    var presenter: IncompleteListItemsPresenter!
    
    var testHelper: ListPresenterTestHelper!

    // MARK: XCTest Life Time

    override func setUp() {
        list = List(color: .Green, items: initiallyCompleteListItems + initiallyIncompleteListItems)

        presenter = IncompleteListItemsPresenter()
        
        presenter.setList(list)
        
        testHelper = ListPresenterTestHelper()
        
        presenter.delegate = testHelper
    }
    
    // MARK: Test Initializers
    
    func testItemInitializationWithIncompleteAndCompleteListItems() {
        XCTAssertEqual(presenter.presentedListItems, initiallyIncompleteListItems, "Only the incomplete items should be presented.")
    }
    
    // MARK: `archiveableList`
    
    func testArchiveableListWithIncompleteAndCompleteItemsAfterToggle() {
        let indexOfListItemToToggle = 2
        let listItemToToggle = presenter.presentedListItems[indexOfListItemToToggle]
        
        /**
            Create a list that represents what should be the final archiveable list. We will compare this list
            against the presenter's archiveableList.
        */
        let expectedList = list.copy() as! List
        let expectedChangeListItem = expectedList.items[indexOfListItemToToggle]
        expectedChangeListItem.isComplete = !expectedChangeListItem.isComplete
        
        testHelper.expectOnNextChange {
            // Check the archiveable list against the expected list we created.
            XCTAssertEqual(self.presenter.archiveableList, expectedList, "The `archiveableList` from the presenter should match our expected list.")
        }

        // Perform the toggle. No need to worry about the side affects of the toggle.
        presenter.toggleListItem(listItemToToggle)
    }
    
    // MARK: `color`
    
    func testSetColorWithDifferentColor() {
        let newColor = List.Color.Orange

        testHelper.expectOnNextChange {
            XCTAssertEqual(self.presenter.color, newColor, "The getter for the color should return the new color.")
            
            let didUpdateListColorCallbackCount = self.testHelper.didUpdateListColorCallbacks.count
            XCTAssertEqual(didUpdateListColorCallbackCount, 1, "There should be one \"list color update\" callback.")
            
            if didUpdateListColorCallbackCount != 1 { return }
            
            let updatedColor = self.testHelper.didUpdateListColorCallbacks.first!
            XCTAssertEqual(updatedColor, newColor, "The delegate callback should provide the new color.")
        }
        
        presenter.color = newColor
    }
    
    // MARK: `toggleListItem(_:)`

    func testToggleIncompleteListItem() {
        let incompleteListItem = initiallyIncompleteListItems[1]
        
        testHelper.expectOnNextChange {
            // Test for item updating.
            let didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count
            XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.")
            
            if didUpdateListItemCallbackCount != 1 { return }
            
            let (updatedListItem, updatedIndex) = self.testHelper.didUpdateListItemCallbacks.first!
            
            XCTAssertEqual(updatedListItem, incompleteListItem, "The delegate should receive the \"update\" callback with the toggled list item.")
            
            XCTAssertTrue(incompleteListItem.isComplete, "The item should be complete after the toggle.")
            XCTAssertEqual(updatedIndex, 1, "The item should be updated in place.")
        }
        
        presenter.toggleListItem(incompleteListItem)
    }
    
    func testToggleCompleteListItem() {
        presenter.updatePresentedListItemsToCompletionState(false)
        
        let completeListItemIndex = 1
        let completeListItem = presenter.presentedListItems[completeListItemIndex]
        
        testHelper.expectOnNextChange {
            // Test for item updating.
            let didUpdateListItemCallbackCount = self.testHelper.didUpdateListItemCallbacks.count
            XCTAssertEqual(didUpdateListItemCallbackCount, 1, "There should be one \"update\" callback.")
            
            if didUpdateListItemCallbackCount != 1 { return }
            
            let (updatedListItem, updatedIndex) = self.testHelper.didUpdateListItemCallbacks.first!
            
            XCTAssertEqual(updatedListItem, completeListItem, "The delegate should receive the \"update\" callback with the toggled list item.")
            XCTAssertTrue(completeListItem.isComplete, "The item should be complete after the toggle.")
            XCTAssertEqual(updatedIndex, completeListItemIndex, "The item should be updated in place.")
        }

        presenter.toggleListItem(completeListItem)
    }
    
    // MARK: `updatePresentedListItemsToCompletionState(_:)`

    func testUpdatePresentedListItemsToCompletionState() {
        testHelper.expectOnNextChange {
            XCTAssertEqual(self.testHelper.didUpdateListItemCallbacks.count, self.initiallyIncompleteListItems.count, "There should be one \"event\" per incomplete, presented item.")

            for (listItem, updatedIndex) in self.testHelper.didUpdateListItemCallbacks {
                if let indexOfUpdatedListItem = self.presentedListItems.indexOf(listItem) {
                    XCTAssertEqual(updatedIndex, indexOfUpdatedListItem, "The updated index should be the same as the initial index.")

                    XCTAssertTrue(listItem.isComplete, "The item should be complete after the update.")
                }
                else {
                    XCTFail("One of the updated list items was never supposed to be in the list.")
                }
            }
        }

        presenter.updatePresentedListItemsToCompletionState(true)
    }
}

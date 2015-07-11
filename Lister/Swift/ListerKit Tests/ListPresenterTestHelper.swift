/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class that makes it easier to test `ListPresenterType` implementations.
*/

import ListerKit
import XCTest

class ListPresenterTestHelper: ListPresenterDelegate {
    // MARK: Properties
    
    var remainingExpectedWillChanges: Int? = nil

    var willChangeCallbackCount = 0
    
    /// An array of tuples representing the inserted list items.
    var didInsertListItemCallbacks: [(listItem: ListItem, index: Int)] = []
    
    /// An array of tuples representing the removed list items.
    var didRemoveListItemCallbacks: [(listItem: ListItem, index: Int)] = []
    
    /// An array of tuples representing the updated list items.
    var didUpdateListItemCallbacks: [(listItem: ListItem, index: Int)] = []
    
    /// An array of tuples representing the moved list items.
    var didMoveListItemCallbacks: [(listItem: ListItem, fromIndex: Int, toIndex: Int)] = []
    
    /// An array of tuples representing the updates to the list presenter's color.
    var didUpdateListColorCallbacks: [List.Color] = []
    
    var remainingExpectedDidChanges: Int? = nil

    var didChangeCallbackCount = 0
    
    // Expectation specific variables.
    
    var assertions: (Void -> Void)! = nil
    
    var isTesting = false

    // MARK: ListPresenterDelegate
    
    func listPresenterDidRefreshCompleteLayout(_: ListPresenterType) {
        /*
            Lister's tests currently do not support testing and `listPresenterDidRefreshCompleteLayout(_:)`
            calls.
        */
    }
    
    func listPresenterWillChangeListLayout(_: ListPresenterType, isInitialLayout: Bool) {
        if !isTesting { return }
        
        remainingExpectedWillChanges?--
        
        willChangeCallbackCount++
    }
    
    func listPresenter(_: ListPresenterType, didInsertListItem listItem: ListItem, atIndex index: Int) {
        if !isTesting { return }
        
        didInsertListItemCallbacks += [(listItem: listItem, index: index)]
    }
    
    func listPresenter(_: ListPresenterType, didRemoveListItem listItem: ListItem, atIndex index: Int) {
        if !isTesting { return }
        
        didRemoveListItemCallbacks += [(listItem: listItem, index: index)]
    }
    
    func listPresenter(_: ListPresenterType, didUpdateListItem listItem: ListItem, atIndex index: Int) {
        if !isTesting { return }
        
        didUpdateListItemCallbacks += [(listItem: listItem, index: index)]
    }
    
    func listPresenter(_: ListPresenterType, didMoveListItem listItem: ListItem, fromIndex: Int, toIndex: Int) {
        if !isTesting { return }
        
        didMoveListItemCallbacks += [(listItem: listItem, fromIndex: fromIndex, toIndex: toIndex)]
    }
    
    func listPresenter(_: ListPresenterType, didUpdateListColorWithColor color: List.Color) {
        if !isTesting { return }

        didUpdateListColorCallbacks += [color]
    }
    
    func listPresenterDidChangeListLayout(_: ListPresenterType, isInitialLayout: Bool) {
        if !isTesting { return }
        
        remainingExpectedDidChanges?--
        
        didChangeCallbackCount++

        if remainingExpectedDidChanges == 0 {
            assertions()

            isTesting = false
        }
    }
    
    /// A helper method run `assertions` once a batch of changes has occured to the list presenter.
    func whenNextChangesOccur(assert assertions: Void -> Void) {
        isTesting = true
        
        self.assertions = assertions

        willChangeCallbackCount = 0
        remainingExpectedWillChanges = nil
        didInsertListItemCallbacks = []
        didRemoveListItemCallbacks = []
        didUpdateListItemCallbacks = []
        didMoveListItemCallbacks = []
        didUpdateListColorCallbacks = []
        didChangeCallbackCount = 0
        remainingExpectedDidChanges = nil
        
        remainingExpectedWillChanges = 1
        remainingExpectedDidChanges = 1
    }
}

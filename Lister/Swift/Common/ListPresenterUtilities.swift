/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Helper functions to perform common operations in `IncompleteListItemsPresenter` and `AllListItemsPresenter`.
*/

import Foundation

/**
    Removes each list item found in `listItemsToRemove` from the `initialListItems` array. For each removal,
    the function notifies the `listPresenter`'s delegate of the change.
*/
func removeListItemsFromListItemsWithListPresenter(listPresenter: ListPresenterType, inout initialListItems: [ListItem], listItemsToRemove: [ListItem]) {
    let sortedListItemsToRemove = listItemsToRemove.sort { initialListItems.indexOf($0)! > initialListItems.indexOf($1)! }
    
    for listItemToRemove in sortedListItemsToRemove {
        // Use the index of the list item to remove in the current list's list items.
        let indexOfListItemToRemoveInOldList = initialListItems.indexOf(listItemToRemove)!
        
        initialListItems.removeAtIndex(indexOfListItemToRemoveInOldList)
        
        listPresenter.delegate?.listPresenter(listPresenter, didRemoveListItem: listItemToRemove, atIndex: indexOfListItemToRemoveInOldList)
    }
}

/**
    Inserts each list item in `listItemsToInsert` into `initialListItems`. For each insertion, the function
    notifies the `listPresenter`'s delegate of the change.
*/
func insertListItemsIntoListItemsWithListPresenter(listPresenter: ListPresenterType, inout initialListItems: [ListItem], listItemsToInsert: [ListItem]) {
    for (idx, insertedIncompleteListItem) in listItemsToInsert.enumerate() {
        initialListItems.insert(insertedIncompleteListItem, atIndex: idx)
        
        listPresenter.delegate?.listPresenter(listPresenter, didInsertListItem: insertedIncompleteListItem, atIndex: idx)
    }
}

/**
    Replaces the stale list items in `presentedListItems` with the new ones found in `newUpdatedListItems`. For
    each update, the function notifies the `listPresenter`'s delegate of the update.
*/
func updateListItemsWithListItemsForListPresenter(listPresenter: ListPresenterType, inout presentedListItems: [ListItem], newUpdatedListItems: [ListItem]) {
    for newlyUpdatedListItem in newUpdatedListItems {
        let indexOfListItem = presentedListItems.indexOf(newlyUpdatedListItem)!
        
        presentedListItems[indexOfListItem] = newlyUpdatedListItem
        
        listPresenter.delegate?.listPresenter(listPresenter, didUpdateListItem: newlyUpdatedListItem, atIndex: indexOfListItem)
    }
}

/**
    Replaces `color` with `newColor` if the colors are different. If the colors are different, the function
    notifies the delegate of the updated color change. If `isForInitialLayout` is not `nil`, the function wraps
    the changes in a call to `listPresenterWillChangeListLayout(_:isInitialLayout:)`
    and a call to `listPresenterDidChangeListLayout(_:isInitialLayout:)` with the value `isForInitialLayout!`.
*/
func updateListColorForListPresenterIfDifferent(listPresenter: ListPresenterType, inout color: List.Color, newColor: List.Color, isForInitialLayout: Bool? = nil) {    
    // Don't trigger any updates if the new color is the same as the current color.
    if color == newColor { return }
    
    if isForInitialLayout != nil {
        listPresenter.delegate?.listPresenterWillChangeListLayout(listPresenter, isInitialLayout: isForInitialLayout!)
    }
    
    color = newColor
    
    listPresenter.delegate?.listPresenter(listPresenter, didUpdateListColorWithColor: newColor)
    
    if isForInitialLayout != nil {
        listPresenter.delegate?.listPresenterDidChangeListLayout(listPresenter, isInitialLayout: isForInitialLayout!)
    }
}
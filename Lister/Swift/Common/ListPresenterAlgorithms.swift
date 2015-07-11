/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Simple internal helper functions to share across `IncompleteListItemsPresenter` and `AllListItemsPresenter`. These functions help diff two arrays of `ListItem` objects.
*/

import Foundation

/// An enum to keep track of the different kinds of changes that may take place within a list.
enum ListItemsBatchChangeKind {
    case Removed
    case Inserted
    case Toggled
    case UpdatedText
    case Multiple
}

/// Returns an array of `ListItem` objects in `initialListItems` that don't exist in `changedListItems`.
func findRemovedListItems(initialListItems initialListItems: [ListItem], changedListItems: [ListItem]) -> [ListItem] {
    return initialListItems.filter { !changedListItems.contains($0) }
}

/// Returns an array of `ListItem` objects in `changedListItems` that don't exist in `initialListItems`.
func findInsertedListItems(initialListItems initialListItems: [ListItem], changedListItems: [ListItem], filter filterHandler: ListItem -> Bool = { _ in return true }) -> [ListItem] {
    return changedListItems.filter { !initialListItems.contains($0) && filterHandler($0) }
}

/**
    Returns an array of `ListItem` objects in `changedListItems` whose completion state changed from `initialListItems`
    relative to `changedListItems`.
*/
func findToggledListItems(initialListItems initialListItems: [ListItem], changedListItems: [ListItem]) -> [ListItem] {
    return changedListItems.filter { changedListItem in
        if let indexOfChangedListItemInInitialListItems = initialListItems.indexOf(changedListItem) {
            let initialListItem = initialListItems[indexOfChangedListItemInInitialListItems]
            
            if initialListItem.isComplete != changedListItem.isComplete {
                return true
            }
        }
        
        return false
    }
}

/**
    Returns an array of `ListItem` objects in `changedListItems` whose text changed from `initialListItems`
    relative to `changedListItems.
*/
func findListItemsWithUpdatedText(initialListItems initialListItems: [ListItem], changedListItems: [ListItem]) -> [ListItem] {
    return changedListItems.filter { changedListItem in
        if let indexOfChangedListItemInInitialListItems = initialListItems.indexOf(changedListItem) {
            let initialListItem = initialListItems[indexOfChangedListItemInInitialListItems]

            if initialListItem.text != changedListItem.text {
                return true
            }
        }
        
        return false
    }
}

/**
    Update `replaceableNewListItems` in place with all of the list items that are equal in `previousUnchangedListItems`.
    For example, if `replaceableNewListItems` has list items of UUID "1", "2", and "3" and `previousUnchangedListItems`
    has list items of UUID "2" and "3", the `replaceableNewListItems` array will have it's list items with UUID
    "2" and "3" replaced with the list items whose UUID is "2" and "3" in `previousUnchangedListItems`. This is
    used to ensure that the list items in multiple arrays are referencing the same objects in memory as what the
    presented list items are presenting.
*/
func replaceAnyEqualUnchangedNewListItemsWithPreviousUnchangedListItems(inout replaceableNewListItems replaceableNewListItems: [ListItem], previousUnchangedListItems: [ListItem]) {
    let replaceableNewListItemsCopy = replaceableNewListItems
    
    for (idx, replaceableNewListItem) in replaceableNewListItemsCopy.enumerate() {
        if let indexOfUnchangedListItem = previousUnchangedListItems.indexOf(replaceableNewListItem) {
            replaceableNewListItems[idx] = previousUnchangedListItems[indexOfUnchangedListItem]
        }
    }
}

/**
    Returns the type of `ListItemsBatchChangeKind` based on the different types of changes. The parameters for
    this function should be based on the result of the functions above. If there were no changes whatsoever,
    `nil` is returned.
*/
func listItemsBatchChangeKindForChanges(removedListItems removedListItems: [ListItem], insertedListItems: [ListItem], toggledListItems: [ListItem], listItemsWithUpdatedText: [ListItem]) -> ListItemsBatchChangeKind? {
    /**
        Switch on the different scenarios that we can isolate uniquely for whether or not changes were made in
        a specific kind of change. Look at the case values for a quick way to see which batch change kind is
        being targeted.
    */

    switch (!removedListItems.isEmpty, !insertedListItems.isEmpty, !toggledListItems.isEmpty, !listItemsWithUpdatedText.isEmpty) {
        case (false, false, false, false):  return nil
        case (true,  false, false, false):  return .Removed
        case (false, true,  false, false):  return .Inserted
        case (false, false, true,  false):  return .Toggled
        case (false, false, false, true):   return .UpdatedText
        default:                            return .Multiple
    }
}

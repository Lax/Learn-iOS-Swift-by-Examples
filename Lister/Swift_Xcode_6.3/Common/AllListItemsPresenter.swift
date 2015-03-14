/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The implementation for the `AllListItemsPresenter` type. This class is responsible for managing how a list is presented in the iOS and OS X apps.
*/

import Foundation

/**
    The `AllListItemsPresenter` list presenter class is responsible for managing how a list is displayed in
    both the iOS and OS X apps. The `AllListItemsPresenter` class conforms to `ListPresenterType` so consumers
    of this class can work with the presenter with a common interface.

    When a list is presented with an `AllListItemsPresenter`, all of the list items with a list are presented
    (as the name suggests!). When the list items are displayed to a user, the incomplete list items are
    ordered before the complete list items. This order is determined when `setList(_:)` is called on the
    `AllListItemsPresenter` instance. The presenter then reorders the list items accordingly, calling the
    delegate methods with any relevant changes.

    An `AllListItemsPresenter` can be interacted with in a few ways. It can insert, remove, toggle, move, and
    update list items. It can also change the color of the presented list. All of these changes get funnelled
    through callbacks to the delegate (a `ListPresenterDelegate`). For more information about how the delegate
    pattern for the `ListPresenterType` is architected, see the `ListPresenterType` definition. What's unique
    about the `AllListItemsPresenter` with respect to the delegate methods is that the `AllListItemsPresenter`
    has an undo manager. Whenever the presentation of the list is manipulated (as described above), the
    presenter pushes an undo operation that reverses the manipulation onto the undo stack. For example, if a
    list item is inserted, the `AllListItemsPresenter` instance registers an undo operation to remove the list
    item.  When a user performs an undo in either the iOS or OS X app, the list item that was inserted is
    removed.  The remove operation gets funnelled into the same delegate that inserted the list item. By
    abstracting these operations away into a presenter and delegate architecture, we're not only able to
    easily test the code that manipulates the list, but we're also able to test the undo registration code.

    One thing to note is that when a list item is toggled in the `AllListItemsPresenter`, it is moved from an
    index in its current completion state to an index opposite of the list items completion state. For
    example, if a list item that is complete is toggled, it will move to an incomplete index (e.g. index 0).
    For the `AllListItemsPresenter`, a toggle represents both the list item moving as well as the list item
    being updated.
*/
final public class AllListItemsPresenter: NSObject, ListPresenterType {
    // MARK: Properties
    
    /// The internal storage for the list that we're presenting. By default, it's an empty list.
    private var list = List()
    
    /// Flag to see whether or not the first `setList(_:)` call should trigger a batch reload.
    private var isInitialList = true

    /// The undo manager to register undo events with when the `AllListItemsPresenter` instance is manipulated.
    public var undoManager: NSUndoManager?
    
    /**
        The index of the first complete item within the list's items. `nil` if there is no complete list item
        in the presented list items.
    */
    private var indexOfFirstCompleteListItem: Int? {
        var firstCompleteListItemIndex: Int?

        for (idx, listItem) in enumerate(presentedListItems) {
            if listItem.isComplete {
                firstCompleteListItemIndex = idx

                break
            }
        }

        return firstCompleteListItemIndex
    }
    
    // MARK: ListPresenterType

    public weak var delegate: ListPresenterDelegate?

    public var color: List.Color {
        get {
            return list.color
        }

        set {
            updateListItemsWithRawColor(newValue.rawValue)
        }
    }
    
    public var archiveableList: List {
        // The list is already in archiveable form since we're updating it directly.
        return list
    }
    
    public var presentedListItems: [ListItem] {
        // We're showing all of the list items in the list.
        return list.items
    }
    
    /**
        Sets the list that should be presented. Calling `setList(_:)` on an `AllListItemsPresenter` does not
        trigger any undo registrations. Calling `setList(_:)` also removes all of the undo actions from the
        undo manager.
    */
    public func setList(newList: List) {
        /**
            If this is the initial list that's being presented, just tell the delegate to reload all of the data.
        */
        if isInitialList {
            isInitialList = false
            
            list = newList
            list.items = reorderedListItemsFromListItems(list.items)

            delegate?.listPresenterDidRefreshCompleteLayout(self)
            
            return
        }

        /**
            Perform more granular changes (if we can). To do this, we group the changes into the different
            types of possible changes. If we know that a group of similar changes occured, we batch them
            together (e.g. four updates to list items). If multiple changes occur that we can't correctly
            resolve (an implementation detail), we refresh the complete layout. An example of this is if more
            than one list item is inserted or toggled. Since this algorithm doesn't track the indexes that
            list items are inserted at, we just refresh the complete layout to make sure that the list items
            are presented correctly. This applies for multiple groups of changes (e.g. one insert and one
            toggle), and also for any unique group of toggles/inserts where there's more than a single update.
        */
        let oldList = list

        let newRemovedListItems = findRemovedListItems(initialListItems: oldList.items, changedListItems: newList.items)
        let newInsertedListItems = findInsertedListItems(initialListItems: oldList.items, changedListItems: newList.items)
        let newToggledListItems = findToggledListItems(initialListItems: oldList.items, changedListItems: newList.items)
        let newListItemsWithUpdatedText = findListItemsWithUpdatedText(initialListItems: oldList.items, changedListItems: newList.items)
        
        /**
            Determine if there was a unique group of batch changes we can make. Otherwise, we refresh all the
            data in the list.
        */
        let listItemsBatchChangeKind = listItemsBatchChangeKindForChanges(removedListItems: newRemovedListItems, insertedListItems: newInsertedListItems, toggledListItems: newToggledListItems, listItemsWithUpdatedText: newListItemsWithUpdatedText)

        /**
            If there was no changes to the list items, check to see if the color changed and notify the
            delegate if it did. If there was not a unique group of changes, updated the entire list.
        */
        if listItemsBatchChangeKind == nil {
            if oldList.color != newList.color {
                undoManager?.removeAllActionsWithTarget(self)

                updateListColorForListPresenterIfDifferent(self, &list.color, newList.color, isForInitialLayout: true)
            }
            
            return
        }
        
        /**
            Check to see if there was more than one kind of unique group of changes, or if there were multiple
            toggled/inserted list items that we don't handle.
        */
        if listItemsBatchChangeKind! == .Multiple || newToggledListItems.count > 1 || newInsertedListItems.count > 1 {
            undoManager?.removeAllActionsWithTarget(self)
            
            list = newList
            list.items = reorderedListItemsFromListItems(list.items)

            delegate?.listPresenterDidRefreshCompleteLayout(self)
            
            return
        }
        
        /** 
            At this point we know that we have changes that are uniquely identifiable: for example, one
            inserted list item, one toggled list item, multiple removed list items, or multiple list items
            whose text has been updated.
        */
        undoManager?.removeAllActionsWithTarget(self)
        
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: true)
        
        // Make the changes based on the unique change kind.
        switch listItemsBatchChangeKind! {
            case .Removed:
                removeListItemsFromListItemsWithListPresenter(self, initialListItems: &list.items, listItemsToRemove: newRemovedListItems)
            
            case .Inserted:
                unsafeInsertListItem(newInsertedListItems.first!)
            
            case .Toggled:
                // We want to toggle the *old* list item, not the one that's in `newList`.
                let indexOfToggledListItemInOldListItems = find(oldList.items, newToggledListItems.first!)!

                let listItemToToggle = oldList.items[indexOfToggledListItemInOldListItems]
    
                unsafeToggleListItem(listItemToToggle)

            case .UpdatedText:
                updateListItemsWithListItemsForListPresenter(self, presentedListItems: &list.items, newUpdatedListItems: newListItemsWithUpdatedText)

            default:
                break
        }
        
        updateListColorForListPresenterIfDifferent(self, &list.color, newList.color)
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: true)
    }
    
    public var count: Int {
        return presentedListItems.count
    }
    
    public var isEmpty: Bool {
        return presentedListItems.isEmpty
    }

    // MARK: Methods
    
    /**
        Inserts `listItem` into the list. If the list item is incomplete, `listItem` is inserted at index 0.
        Otherwise, it is inserted at the end of the list. Inserting a list item calls the delegate's
        `listPresenter(_:didInsertListItem:atIndex:)` method. Calling this method registers an undo event to
        remove the list item.
    
        :param: listItem The `ListItem` instance to insert.
    */
    public func insertListItem(listItem: ListItem) {
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        unsafeInsertListItem(listItem)
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
        
        // Undo
        undoManager?.prepareWithInvocationTarget(self).removeListItem(listItem)
        
        let undoActionName = NSLocalizedString("Remove", comment: "")
        undoManager?.setActionName(undoActionName)
    }

    /**
        Inserts `listItems` into the list. The net effect of this is calling `insertListItem(_:)` for each
        `ListItem` instance in `listItems`. Inserting list items calls the delegate's
        `listPresenter(_:didInsertListItem:atIndex:)` method for each inserted list item after an individual
        list item has been inserted. Calling this method registers an undo event to remove each list item.
    
        :param: listItems The `ListItem` instances to insert.
    */
    public func insertListItems(listItems: [ListItem]) {
        if listItems.isEmpty { return }
        
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        for listItem in listItems {
            unsafeInsertListItem(listItem)
        }
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
        
        // Undo
        undoManager?.prepareWithInvocationTarget(self).removeListItems(listItems)

        let undoActionName = NSLocalizedString("Remove", comment: "")
        undoManager?.setActionName(undoActionName)
    }
    
    /**
        Removes `listItem` from the list. Removing the list item calls the delegate's
        `listPresenter(_:didRemoveListItem:atIndex:)` method for the removed list item
        after it has been removed. Calling this method registers an undo event to insert
        the list item at its previous index.
        
        :param: listItem The `ListItem` instance to remove.
    */
    @objc public func removeListItem(listItem: ListItem) {
        let listItemIndex = find(presentedListItems, listItem)
        
        if listItemIndex == nil {
            preconditionFailure("A list item was requested to be removed that isn't in the list.")
        }
        
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        list.items.removeAtIndex(listItemIndex!)
        
        delegate?.listPresenter(self, didRemoveListItem: listItem, atIndex: listItemIndex!)

        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)

        // Undo
        undoManager?.prepareWithInvocationTarget(self).insertListItemsForUndo([listItem], atIndexes: [listItemIndex!])
        
        let undoActionName = NSLocalizedString("Remove", comment: "")
        undoManager?.setActionName(undoActionName)
    }

    /**
        Removes `listItems` from the list. Removing list items calls the delegate's
        `listPresenter(_:didRemoveListItem:atIndex:)` method for each of the removed list items after an
        individual list item has been removed. Calling this method registers an undo event to insert the list
        items that were removed at their previous indexes.
        
        :param: listItems The `ListItem` instances to remove.
    */
    @objc public func removeListItems(listItems: [ListItem]) {
        if listItems.isEmpty { return }
        
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        /**
            We're going to store the indexes of the list items that will be removed in an array.
            We do that so that when we insert the same list items back in for undo, we don't need
            to worry about insertion order (since it will just be the opposite of insertion order).
        */
        var removedIndexes = [Int]()
        
        for listItem in listItems {
            if let listItemIndex = find(presentedListItems, listItem) {
                list.items.removeAtIndex(listItemIndex)
                
                delegate?.listPresenter(self, didRemoveListItem: listItem, atIndex: listItemIndex)
                
                removedIndexes += [listItemIndex]
            }
            else {
                preconditionFailure("A list item was requested to be removed that isn't in the list.")
            }
        }
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
        
        // Undo
        undoManager?.prepareWithInvocationTarget(self).insertListItemsForUndo(listItems.reverse(), atIndexes: removedIndexes.reverse())
        
        let undoActionName = NSLocalizedString("Remove", comment: "")
        undoManager?.setActionName(undoActionName)
    }
    
    /**
        Updates the `text` property of `listItem` with `newText`. Updating the text property of the list item
        calls the delegate's `listPresenter(_:didUpdateListItem:atIndex:)` method for the list item that was
        updated. Calling this method registers an undo event to revert the text change back to the text before
        the method was invoked.
    
        :param: listItem The `ListItem` instance whose text needs to be updated.
        :param: newText The new text for `listItem`.
    */
    @objc public func updateListItem(listItem: ListItem, withText newText: String) {
        precondition(contains(presentedListItems, listItem), "A list item can only be updated if it already exists in the list.")
        
        // If the text is the same, it's a no op.
        if listItem.text == newText { return }
        
        var index = find(presentedListItems, listItem)!
        
        let oldText = listItem.text
        
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        listItem.text = newText
        
        delegate?.listPresenter(self, didUpdateListItem: listItem, atIndex: index)
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
        
        // Undo
        undoManager?.prepareWithInvocationTarget(self).updateListItem(listItem, withText: oldText)
        
        let undoActionName = NSLocalizedString("Text Change", comment: "")
        undoManager?.setActionName(undoActionName)
    }

    /**
        Tests whether `listItem` is in the list and can be moved from its current index in the list to `toIndex`.
    
        :param: listItem The item to test for insertion.
        :param: toIndex The index to use to determine if `listItem` can be inserted into the list.
    
        :returns: Whether or not `listItem` can be moved to `toIndex`.
    */
    public func canMoveListItem(listItem: ListItem, toIndex: Int) -> Bool {
        if !contains(presentedListItems, listItem) { return false }

        let firstCompleteListItemIndex = indexOfFirstCompleteListItem
        
        if firstCompleteListItemIndex != nil {
            if listItem.isComplete {
                return firstCompleteListItemIndex!...count ~= toIndex
            }
            else {
                return 0..<firstCompleteListItemIndex! ~= toIndex
            }
        }
        
        return !listItem.isComplete && 0...count ~= toIndex
    }
    
    /**
        Moves `listItem` to `toIndex`. Moving the `listItem` to a new index calls the delegate's
        `listPresenter(_:didMoveListItem:fromIndex:toIndex)` method with the moved list item. Calling this
        method registers an undo event that moves the list item from its new index back to its old index.

        :param: listItem The list item to move.
        :param: toIndex The index to move `listItem` to.
    */
    @objc public func moveListItem(listItem: ListItem, toIndex: Int) {
        precondition(canMoveListItem(listItem, toIndex: toIndex), "An item can only be moved if it passes a \"can move\" test.")
        
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)

        let fromIndex = unsafeMoveListItem(listItem, toIndex: toIndex)
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
        
        // Undo
        undoManager?.prepareWithInvocationTarget(self).moveListItem(listItem, toIndex: fromIndex)
        
        let undoActionName = NSLocalizedString("Move", comment: "")
        undoManager?.setActionName(undoActionName)
    }
    
    /**
        Toggles `listItem` within the list. This method moves a complete list item to an incomplete index at
        the beginning of the list, or it moves an incomplete list item to a complete index at the last index
        of the list. The list item is also updated in place since the completion state is flipped. Toggling a
        list item calls the delegate's `listPresenter(_:didMoveListItem:fromIndex:toIndex:)` method followed
        by the delegate's `listPresenter(_:didUpdateListItem:atIndex:)` method. Calling this method registers
        an undo event that toggles the list item back to its original location and completion state.
    
        :param: listItem The list item to toggle.
    */
    public func toggleListItem(listItem: ListItem) {
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        let fromIndex = unsafeToggleListItem(listItem)
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
        
        // Undo
        undoManager?.prepareWithInvocationTarget(self).toggleListItemForUndo(listItem, toPreviousIndex: fromIndex)
        
        let undoActionName = NSLocalizedString("Toggle", comment: "")
        undoManager?.setActionName(undoActionName)
    }

    /**
        Set the completion state of all of the presented list items to `completionState`. This method does not
        move the list items around in any way. Changing the completion state on all of the list items calls
        the delegate's `listPresenter(_:didUpdateListItem:atIndex:)` method for each list item that has been
        updated. Calling this method registers an undo event that sets the completion states for all of the
        list items back to the original state before the method was invoked.
    
        :param: completionState The value that all presented list item instances should have as their `isComplete` property.
    */
    public func updatePresentedListItemsToCompletionState(completionState: Bool) {
        var presentedListItemsNotMatchingCompletionState = presentedListItems.filter { $0.isComplete != completionState }
      
        // If there are no list items that match the completion state, it's a no op.
        if presentedListItemsNotMatchingCompletionState.isEmpty { return }

        let undoActionName = completionState ? NSLocalizedString("Complete All", comment: "") : NSLocalizedString("Incomplete All", comment: "")
        toggleListItemsWithoutMoving(presentedListItemsNotMatchingCompletionState, undoActionName: undoActionName)
    }
    
    /**
        Returns the list items at each index in `indexes` within the `presentedListItems` array.
    
        :param: indexes The indexes that correspond to the list items that should be retrieved from `presentedListItems`.
    
        :returns: The list items that are located at each index in `indexes` within `presentedListItems`.
    */
    public func listItemsAtIndexes(indexes: NSIndexSet) -> [ListItem] {
        var listItems = [ListItem]()
        
        listItems.reserveCapacity(indexes.count)
        
        indexes.enumerateIndexesUsingBlock { idx, _ in
            listItems += [self.presentedListItems[idx]]
        }
        
        return listItems
    }
    
    // MARK: Undo Helper Methods

    /**
        Toggles a list item to a specific destination index. This method is used to in `toggleListItem(_:)`
        where the undo event needs to move the list item back into its original location (rather than being
        moved to an index that it would normally be moved to in a call to `toggleListItem(_:)`).
    
        :param: listItem The list item to toggle.
        :param: previousIndex The index to move `listItem` to.
    */
    @objc private func toggleListItemForUndo(listItem: ListItem, toPreviousIndex previousIndex: Int) {
        precondition(contains(presentedListItems, listItem), "The list item should already be in the list if it's going to be toggled.")

        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        // Move the list item.
        let fromIndex = unsafeMoveListItem(listItem, toIndex: previousIndex)
        
        // Update the list item's state.
        listItem.isComplete = !listItem.isComplete
        
        delegate?.listPresenter(self, didUpdateListItem: listItem, atIndex: previousIndex)
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
        
        // Undo
        undoManager?.prepareWithInvocationTarget(self).toggleListItemForUndo(listItem, toPreviousIndex: fromIndex)
        
        let undoActionName = NSLocalizedString("Toggle", comment: "")
        undoManager?.setActionName(undoActionName)
    }
    
    /**
        Inserts `listItems` at `indexes`. This is useful for undoing a call to `removeListItem(_:)` or
        `removeListItems(_:)` where the opposite action, such as re-inserting the list item, has to be done
        where each list item moves back to its original location before the removal.
    
        :param: listItems The list items to insert.
        :param: indexes The indexes at which to insert `listItems` into.
    */
    @objc private func insertListItemsForUndo(listItems: [ListItem], atIndexes indexes: [Int]) {
        precondition(listItems.count == indexes.count, "`listItems` must have as many elements as `indexes`.")
    
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        for (listItemIndex, listItem) in enumerate(listItems) {
            let insertionIndex = indexes[listItemIndex]

            list.items.insert(listItem, atIndex: insertionIndex)
            
            delegate?.listPresenter(self, didInsertListItem: listItem, atIndex: insertionIndex)
        }
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
        
        // Undo
        undoManager?.prepareWithInvocationTarget(self).removeListItems(listItems)
        
        let undoActionName = NSLocalizedString("Remove", comment: "")
        undoManager?.setActionName(undoActionName)
    }

    /**
        Sets the list's color to the new color. Calling this method registers an undo event to be called to
        reset the color the original color before this method was called. Note that in order for the method to
        be representable in Objective-C (to make sure that `NSUndoManager` can safely call
        `updateListItemsWithRawColor(_:)`), we must make the parameter an `Int` and not a `List.Color`.  This
        is because Swift enums are not representable in Objective-C.
    
        :param: rawColor The raw color value of the `List.Color` that should be set as the new color.
    */
    @objc private func updateListItemsWithRawColor(rawColor: Int) {
        let oldColor = color

        let newColor = List.Color(rawValue: rawColor)!

        updateListColorForListPresenterIfDifferent(self, &list.color, newColor, isForInitialLayout: false)
        
        // Undo
        undoManager?.prepareWithInvocationTarget(self).updateListItemsWithRawColor(rawColor)
        
        let undoActionName = NSLocalizedString("Change Color", comment: "")
        undoManager?.setActionName(undoActionName)
    }
    
    /**
        Toggles the completion state of each list item in `listItems` without moving the list items.  This is
        useful for `updatePresentedListItemsToCompletionState(_:)` to call with just the list items that are not
        equal to the new completion state. Toggling the list items without moving them registers an undo event
        that toggles the list items again (effectively undoing the toggle in the first place).
    
        :params: listItems The list items that should be toggled in place.
    */
    @objc private func toggleListItemsWithoutMoving(listItems: [ListItem], undoActionName: String) {
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)

        for listItem in listItems {
            listItem.isComplete = !listItem.isComplete

            let updatedIndex = find(presentedListItems, listItem)!
          
            delegate?.listPresenter(self, didUpdateListItem: listItem, atIndex: updatedIndex)
        }
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)

        // Undo
        undoManager?.prepareWithInvocationTarget(self).toggleListItemsWithoutMoving(listItems, undoActionName: undoActionName)
        undoManager?.setActionName(undoActionName)
    }
    
    // MARK: Internal Unsafe Updating Methods
    
    /**
        Inserts `listItem` into the list based on the list item's completion state. The delegate receives a
        `listPresenter(_:didInsertListItem:atIndex:)` callback. No undo registrations are performed.
        
        :param: listItem The list item to insert.
    */
    private func unsafeInsertListItem(listItem: ListItem) {
        precondition(!contains(presentedListItems, listItem), "A list item was requested to be added that is already in the list.")
        
        var indexToInsertListItem = listItem.isComplete ? count : 0
        
        list.items.insert(listItem, atIndex: indexToInsertListItem)
        
        delegate?.listPresenter(self, didInsertListItem: listItem, atIndex: indexToInsertListItem)
    }
    
    /**
        Moves `listItem` to `toIndex`. This method also notifies the delegate that a list item was moved
        through the `listPresenter(_:didMoveListItem:fromIndex:toIndex:)` callback.  No undo registrations are performed.
    
        :param: listItem The list item to move to `toIndex`.
        :param: toIndex The index at which `listItem` should be moved to.

        :returns: The index that `listItem` was initially located at.
    */
    private func unsafeMoveListItem(listItem: ListItem, toIndex: Int) -> Int {
        precondition(contains(presentedListItems, listItem), "A list item can only be moved if it already exists in the presented list items.")
        
        var fromIndex = find(presentedListItems, listItem)!

        list.items.removeAtIndex(fromIndex)
        list.items.insert(listItem, atIndex: toIndex)
        
        delegate?.listPresenter(self, didMoveListItem: listItem, fromIndex: fromIndex, toIndex: toIndex)
        
        return fromIndex
    }

    private func unsafeToggleListItem(listItem: ListItem) -> Int {
        precondition(contains(presentedListItems, listItem), "A list item can only be toggled if it already exists in the list.")
        
        // Move the list item.
        let targetIndex = listItem.isComplete ? 0 : count - 1
        let fromIndex = unsafeMoveListItem(listItem, toIndex: targetIndex)
        
        // Update the list item's state.
        listItem.isComplete = !listItem.isComplete
        delegate?.listPresenter(self, didUpdateListItem: listItem, atIndex: targetIndex)
        
        return fromIndex
    }
    
    // MARK: Private Convenience Methods
    
    /**
        Returns an array that contains the same elements as `listItems`, but sorted with incomplete list items
        followed by complete list items.
    
        :param: listItems List items that should be reordered.
    
        :returns: The reordered list items with incomplete list items followed by complete list items.
    */
    private func reorderedListItemsFromListItems(listItems: [ListItem]) -> [ListItem] {
        let incompleteListItems = listItems.filter { !$0.isComplete }
        let completeListItems = listItems.filter { $0.isComplete }

        return incompleteListItems + completeListItems
    }
}

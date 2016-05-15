/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The implementation for the `IncompleteListItemsPresenter` type. This class is responsible for managing how a list is presented in the iOS and OS X app Today widgets, as well as the Lister WatchKit application.
*/

import Foundation

/**
    The `IncompleteListItemsPresenter` list presenter is responsible for managing the how a list's incomplete
    list items are displayed in the iOS and OS X Today widgets as well as the Lister WatchKit app. The
    `IncompleteListItemsPresenter` class conforms to `ListPresenterType` so consumers of this class can work
    with the presenter using a common interface.

    When a list is initially presented with an `IncompleteListItemsPresenter`, only the incomplete list items
    are presented. That can change, however, if a user toggles list items (changing the list item's completion
    state). An `IncompleteListItemsPresenter` always shows the list items that are initially presented (unless
    they are removed from the list from another device). If an `IncompleteListItemsPresenter` stops presenting
    a list that has some presented list items that are complete (after toggling them) and another
    `IncompleteListItemsPresenter` presents the same list, the presenter displays *only* the incomplete list
    items.

    The `IncompleteListItemsPresenter` can be interacted with in a two ways. `ListItem` instances can be
    toggled individually or using a batch update, and the color of the list presenter can be changed.  All of
    these methods trigger calls to the delegate to be notified about inserted list items, removed list items,
    updated list items, etc.
*/
final public class IncompleteListItemsPresenter: NSObject, ListPresenterType {
    // MARK: Properties

    /// The internal storage for the list that we're presenting. By default, it's an empty list.
    private var list = List()
    
    /// Flag to see whether or not the first `setList(_:)` call should trigger a batch reload.
    private var isInitialList = true

    /**
        A cached array of the list items that should be presented. When the presenter initially has its
        underlying `list` set, the `_presentedListItems` is set to all of the incomplete list items.  As list
        items are toggled, `_presentedListItems` may contain incomplete list items as well as complete items
        that were incomplete when the presenter's list was set. Note that we've named the property
        `_presentedListItems` since there's already a readonly `presentedListItems` property (which returns the
        value of `_presentedListItems`).
    */
    private var _presentedListItems = [ListItem]()
    
    // MARK: ListPresenterType
    
    public weak var delegate: ListPresenterDelegate?
    
    public var color: List.Color {
        get {
            return list.color
        }
        
        set {
            updateListColorForListPresenterIfDifferent(self, color: &list.color, newColor: newValue, isForInitialLayout: false)
        }
    }
    
    public var archiveableList: List {
        return list
    }
    
    public var presentedListItems: [ListItem] {
        return _presentedListItems
    }

    /**
        This methods determines the changes betwen the current list and the new list provided, and it notifies
        the delegate accordingly. The delegate is notified of all changes except for reordering list items (an
        implementation detail). If the list is the initial list to be presented, we just reload all of the
        data.
    */
    public func setList(newList: List) {
        // If this is the initial list that's being presented, just tell the delegate to reload all of the data.
        if isInitialList {
            isInitialList = false
            
            list = newList
            _presentedListItems = list.items.filter { !$0.isComplete }
            
            delegate?.listPresenterDidRefreshCompleteLayout(self)
            
            return
        }

        /**
            First find all the differences between the lists that we want to reflect in the presentation of
            the list: list items that were removed, inserted list items that are incomplete, presented list
            items that are toggled, and presented list items whose text has changed. Note that although we'll
            gradually update `_presentedListItems` to reflect the changes we find, we also want to save the
            latest state of the list (i.e. the `newList` parameter) as the underlying storage of the list.
            Since we'll be presenting the same list either way, it's better not to change the underlying list
            representation unless we need to. Keep in mind, however, that all of the list items in
            `_presentedListItems` should also be in `list.items`.  In short, once we modify `_presentedListItems`
            with all of the changes, we need to also update `list.items` to contain all of the list items that
            were unchanged (this can be done by replacing the new list item representation by the old
            representation of the list item). Once that happens, all of the presentation logic carries on as
            normal.
        */
        let oldList = list
        
        let newRemovedPresentedListItems = findRemovedListItems(initialListItems: _presentedListItems, changedListItems: newList.items)
        let newInsertedIncompleteListItems = findInsertedListItems(initialListItems: _presentedListItems, changedListItems: newList.items) { listItem in
            return !listItem.isComplete
        }
        let newPresentedToggledListItems = findToggledListItems(initialListItems: _presentedListItems, changedListItems: newList.items)
        let newPresentedListItemsWithUpdatedText = findListItemsWithUpdatedText(initialListItems: _presentedListItems, changedListItems: newList.items)

        let listItemsBatchChangeKind = listItemsBatchChangeKindForChanges(removedListItems: newRemovedPresentedListItems, insertedListItems: newInsertedIncompleteListItems, toggledListItems: newPresentedToggledListItems, listItemsWithUpdatedText: newPresentedListItemsWithUpdatedText)

        // If no changes occured we'll ignore the update.
        if listItemsBatchChangeKind == nil && oldList.color == newList.color {
            return
        }
        
        // Start performing changes to the presentation of the list.
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: true)
        
        // Remove the list items from the presented list items that were removed somewhere else.
        if !newRemovedPresentedListItems.isEmpty {
            removeListItemsFromListItemsWithListPresenter(self, initialListItems: &_presentedListItems, listItemsToRemove: newRemovedPresentedListItems)
        }
        
        // Insert the incomplete list items into the presented list items that were inserted elsewhere.
        if !newInsertedIncompleteListItems.isEmpty {
            insertListItemsIntoListItemsWithListPresenter(self, initialListItems: &_presentedListItems, listItemsToInsert: newInsertedIncompleteListItems)
        }
        
        /**
            For all of the list items whose content has changed elsewhere, we need to update the list items in
            place.  Since the `IncompleteListItemsPresenter` keeps toggled list items in place, we only need
            to perform one update for list items that have a different completion state and text. We'll batch
            both of these changes into a single update.
        */
        if !newPresentedToggledListItems.isEmpty || !newPresentedListItemsWithUpdatedText.isEmpty {
            // Find the unique list of list items that are updated.
            let uniqueUpdatedListItems = Set(newPresentedToggledListItems).union(newPresentedListItemsWithUpdatedText)

            updateListItemsWithListItemsForListPresenter(self, presentedListItems: &_presentedListItems, newUpdatedListItems: Array(uniqueUpdatedListItems))
        }

        /**
            At this point, the presented list items have been updated. As mentioned before, to ensure that
            we're consistent about how we persist the updated list, we'll just use new the new list as the
            underlying model. To do that, we'll need to update the new list's unchanged list items with the
            list items that are stored in the visual list items. Specifically, we need to make sure that any
            references to list items in `_presentedListItems` are reflected in the new list's items.
        */
        list = newList
        
        // Obtain the presented list items that were unchanged. We need to update the new list to reference the old list items.
        let unchangedPresentedListItems = _presentedListItems.filter { oldListItem in
            return !newRemovedPresentedListItems.contains(oldListItem) && !newInsertedIncompleteListItems.contains(oldListItem) && !newPresentedToggledListItems.contains(oldListItem) && !newPresentedListItemsWithUpdatedText.contains(oldListItem)
        }
        replaceAnyEqualUnchangedNewListItemsWithPreviousUnchangedListItems(replaceableNewListItems: &list.items, previousUnchangedListItems: unchangedPresentedListItems)

        /**
            Even though the old list's color will change if there's a difference between the old list's color
            and the new list's color, the delegate only cares about this change in reference to what it
            already knows.  Because the delegate hasn't seen a color change yet, the update (if it happens) is
            ok.
        */
        updateListColorForListPresenterIfDifferent(self, color: &oldList.color, newColor: newList.color)
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: true)
    }

    // MARK: Methods
    
    /**
        Toggles `listItem` within the list. This method keeps the list item in the same place, but it toggles
        the completion state of the list item. Toggling a list item calls the delegate's
        `listPresenter(_:didUpdateListItem:atIndex:)` method.
        
        - parameter listItem: The list item to toggle.
    */
    public func toggleListItem(listItem: ListItem) {
        precondition(presentedListItems.contains(listItem), "The list item must already be in the presented list items.")
        
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        listItem.isComplete = !listItem.isComplete
        
        let currentIndex = presentedListItems.indexOf(listItem)!
        
        delegate?.listPresenter(self, didUpdateListItem: listItem, atIndex: currentIndex)
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
    }

    /**
        Sets all of the presented list item's completion states to `completionState`. This method does not move
        the list items around in any way. Changing the completion state on all of the list items calls the
        delegate's `listPresenter(_:didUpdateListItem:atIndex:)` method for each list item that has been
        updated. 

        - parameter completionState: The value that all presented list item instances should have as their `isComplete` property.
    */
    public func updatePresentedListItemsToCompletionState(completionState: Bool) {
        let presentedListItemsNotMatchingCompletionState = presentedListItems.filter { $0.isComplete != completionState }
        
        // If there are no list items that match the completion state, it's a no op.
        if presentedListItemsNotMatchingCompletionState.isEmpty { return }
        
        delegate?.listPresenterWillChangeListLayout(self, isInitialLayout: false)
        
        for listItem in presentedListItemsNotMatchingCompletionState {
            listItem.isComplete = !listItem.isComplete
            
            let indexOfListItem = presentedListItems.indexOf(listItem)!
            
            delegate?.listPresenter(self, didUpdateListItem: listItem, atIndex: indexOfListItem)
        }
        
        delegate?.listPresenterDidChangeListLayout(self, isInitialLayout: false)
    }
}

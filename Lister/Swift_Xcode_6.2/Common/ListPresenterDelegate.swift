/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The definition for the `ListPresenterDelegate` type. This protocol defines the contract between the `ListPresenterType` interactions and receivers of those events (the type that conforms to the `ListPresenterDelegate` protocol).
*/

/**
    The `ListPresenterDelegate` type is used to receive events from a `ListPresenterType` about updates to the
    presenter's layout. This happens, for example, if a `ListItem` object is inserted into the list or removed
    from the list. For any change that occurs to the list, a delegate message can be called. As a conformer
    you must implement all of these methods, but you may decide not to take any action if the method doesn't
    apply to your use case. For an implementation of `ListPresenterDelegate`, see the `AllListItemsPresenter`
    or `IncompleteListItemsPresenter` types.
*/
public protocol ListPresenterDelegate: class {
    /**
        A `ListItemPresenterType` invokes this method on its delegate when a large change to the underlying
        list changed, but the presenter couldn't resolve the granular changes. A full layout change includes
        changing anything on the underlying list: list item toggling, text updates, color changes, etc. This
        is invoked, for example, when the list is initially loaded, because there could be many changes that
        happened relative to an empty list--the delegate should just reload everything immediately.  This
        method is not wrapped in `listPresenterWillChangeListLayout(_:isInitialLayout:)` and
        `listPresenterDidChangeListLayout(_:isInitialLayout:)` method invocations.
    
        :param: listPresenter The list presenter whose full layout has changed.
    */
    func listPresenterDidRefreshCompleteLayout(listPresenter: ListPresenterType)
    
    /**
        A `ListPresenterType` invokes this method on its delegate before a set of layout changes occur. This
        could involve list item insertions, removals, updates, toggles, etc. This can also include changes to
        the color of the `ListPresenterType`.  If `isInitialLayout` is `true`, it means that the new list is
        being presented for the first time--for example, if `setList(_:)` is called on the `ListPresenterType`,
        the delegate will receive a `listPresenterWillChangeListLayout(_:isInitialLayout:)` call where
        `isInitialLayout` is `true`.
    
        :param: listPresenter The list presenter whose presentation will change.
        :param: isInitialLayout Whether or not the presenter is presenting the most recent list for the first time.
    */
    func listPresenterWillChangeListLayout(listPresenter: ListPresenterType, isInitialLayout: Bool)
    
    /**
        A `ListPresenterType` invokes this method on its delegate when an item was inserted into the list.
        This method is called only if the invocation is wrapped in a call to
        `listPresenterWillChangeListLayout(_:isInitialLayout:)` and `listPresenterDidChangeListLayout(_:isInitialLayout:)`.
    
        :param: listPresenter The list presenter whose presentation has changed.
        :param: listItem The list item that has been inserted.
        :param: index The index that `listItem` was inserted into.
    */
    func listPresenter(listPresenter: ListPresenterType, didInsertListItem listItem: ListItem, atIndex index: Int)
    
    /**
        A `ListPresenterType` invokes this method on its delegate when an item was removed from the list. This
        method is called only if the invocation is wrapped in a call to
        `listPresenterWillChangeListLayout(_:isInitialLayout:)` and `listPresenterDidChangeListLayout(_:isInitialLayout:)`.
        
        :param: listPresenter The list presenter whose presentation has changed.
        :param: listItem The list item that has been removed.
        :param: index The index that `listItem` was removed from.
    */
    func listPresenter(listPresenter: ListPresenterType, didRemoveListItem listItem: ListItem, atIndex index: Int)

    /**
        A `ListPresenterType` invokes this method on its delegate when an item is updated in place. This could
        happen, for example, if the text of a `ListItem` instance changes. This method is called only if the
        invocation is wrapped in a call to `listPresenterWillChangeListLayout(_:isInitialLayout:)` and
        `listPresenterDidChangeListLayout(_:isInitialLayout:)`.
        
        :param: listPresenter The list presenter whose presentation has changed.
        :param: listItem The list item that has been updated.
        :param: index The index that `listItem` was updated at in place.
    */
    func listPresenter(listPresenter: ListPresenterType, didUpdateListItem listItem: ListItem, atIndex index: Int)

    /**
        A `ListPresenterType` invokes this method on its delegate when an item moved `fromIndex` to `toIndex`.
        This could happen, for example, if the list presenter toggles a `ListItem` instance and it needs to be
        moved from one index to another.  This method is called only if the invocation is wrapped in a call to
        `listPresenterWillChangeListLayout(_:isInitialLayout:)` and `listPresenterDidChangeListLayout(_:isInitialLayout:)`.
        
        :param: listPresenter The list presenter whose presentation has changed.
        :param: listItem The list item that has been moved.
        :param: fromIndex The original index that `listItem` was located at before the move.
        :param: toIndex The index that `listItem` was moved to.
    */
    func listPresenter(listPresenter: ListPresenterType, didMoveListItem listItem: ListItem, fromIndex: Int, toIndex: Int)

    /**
        A `ListPresenterType` invokes this method on its delegate when the color of the `ListPresenterType`
        changes. This method is called only if the invocation is wrapped in a call to
        `listPresenterWillChangeListLayout(_:isInitialLayout:)` and `listPresenterDidChangeListLayout(_:isInitialLayout:)`.
    
        :param: listPresenter The list presenter whose presentation has changed.
        :param: color The new color of the presented list.
    */
    func listPresenter(listPresenter: ListPresenterType, didUpdateListColorWithColor color: List.Color)

    /**
        A `ListPresenterType` invokes this method on its delegate after a set of layout changes occur. See
        `listPresenterWillChangeListLayout(_:isInitialLayout:)` for examples of when this is called.
        
        :param: listPresenter The list presenter whose presentation has changed.
        :param: isInitialLayout Whether or not the presenter is presenting the most recent list for the first time.
    */
    func listPresenterDidChangeListLayout(listPresenter: ListPresenterType, isInitialLayout: Bool)
}

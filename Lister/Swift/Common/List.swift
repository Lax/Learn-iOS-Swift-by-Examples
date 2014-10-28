/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `List` class manages a list of items and the color of the list.
            
*/

import Foundation

/**
    The `List` class manages the color of a list and each `ListItem` object, including the order of items
    in a list. Incomplete items are located at the start of the items array, followed by complete list
    items. Various convenience methods on the `List` class query whether an item can be moved or inserted
    at a certain index, perform those move and insert operations, toggle an item between a complete
    and an incomplete state, and fetch list items by index. `List` objects are copyable and archivable.
    To ensure that the `List` class is unarchivable from an instance that was archived in the Objective-C
    version of Lister, the `List` class declaration is annotated with @objc(AAPLList). This annotation
    ensures that the runtime name of the `List` class is the same as the `AAPLList` class defined in
    the Objective-C version of the app. It also allows the Objective-C version of Lister to unarchive
    a `List` instance that was archived in the Swift version.
*/
@objc(AAPLList)
public class List: NSObject, NSCoding, NSCopying {
    // MARK: Types
    
    /**
        String constants that are used to archive the stored properties of a `List`. These constants
        are used to help implement `NSCoding`.
    */
    private struct SerializationKeys {
        static let items = "items"
        static let color = "color"
    }
    
    /**
        The possible colors a list can have. Because a list's color is specific to a `List` object,
        it is represented by a nested type.

        - Gray (default)
        - Blue
        - Green
        - Yellow
        - Orange
        - Red
    */
    public enum Color: Int {
        case Gray, Blue, Green, Yellow, Orange, Red
    }
    
    // MARK: Properties
    
    /// The list's color. This property is stored when it is archived and read when it is unarchived.
    public var color: Color
    
    /// :returns: A copy of the list's items.
    public var items: [ListItem] {
        return _items
    }
    
    /**
        The underlying storage for the list's items. This property is stored when it is archived and
        read when it is unarchived.
    */
    private var _items: [ListItem]
    
    /// :returns: The number of items in the list.
    public var count: Int {
        return _items.count
    }
    
    /**
        :returns: The index of the first complete item in the list of items. If the list has no
                  complete item, this property returns nil.
    */
    public var indexOfFirstCompletedItem: Int? {
        for (current, item) in enumerate(_items) {
            if item.isComplete {
                return current
            }
        }
            
        return nil
    }
    
    /// :returns: `true` if the list has no items, `false` otherwise.
    public var isEmpty: Bool {
        return _items.isEmpty
    }

    /// :returns: The index that represents the separator between incomplete and complete items.
    private var separatorIndex: Int {
        if let firstCompleteItemIndex = indexOfFirstCompletedItem {
            return firstCompleteItemIndex
        }
            
        return count
    }
    
    // MARK: Initializers
    
    /**
        Initializes a `List` instance with the designated color and items.
        
        :param: color The intended color of the list.
        :param: items The items that represent the underlying list. The `List` class copies the items
                      in initialization.
    */
    public init(color: List.Color, items: [ListItem]) {
        self.color = color
        
        _items = items.map { $0.copy() as ListItem }
    }

    /// Initializes a `List` instance with a default color of gray and an empty items array.
    public convenience override init() {
        self.init(color: .Gray, items: [])
    }
    
    // MARK: NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        _items = aDecoder.decodeObjectForKey(SerializationKeys.items) as [ListItem]
        color = List.Color(rawValue: aDecoder.decodeIntegerForKey(SerializationKeys.color))!
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(items, forKey: SerializationKeys.items)
        aCoder.encodeInteger(color.rawValue, forKey: SerializationKeys.color)
    }
    
    // MARK: NSCopying
    
    public func copyWithZone(zone: NSZone) -> AnyObject  {
        return List(color: color, items: items)
    }
    
    // MARK: Subscripts
    
    /**
        Finds the `ListItem` that corresponds to an index. The method traps if the index is out of
        bounds.
        
        :param: index The index for the requested item.
        
        :returns: The `ListItem` object corresponding to the provided index.
    */
    public subscript(index: Int) -> ListItem {
        return items[index]
    }
    
    /**
        Finds an array of `ListItem` instances that correspond to a set of indexes. The method traps
        if any index in the set is out of bounds.
        
        :param: indexes The indexes for the requested items.
        
        :returns: The `ListItem` objects corresponding to the provided indexes.
    */
    public subscript(#indexes: NSIndexSet) -> [ListItem] {
        var items = [ListItem]()

        items.reserveCapacity(indexes.count)
            
        indexes.enumerateIndexesUsingBlock { idx, _ in
            items += [self[idx]]
        }

        return items
    }
    
    // MARK: List Management
    
    /**
        Computes the index of where an item is located.
        
        :param: item The item whose index should be found.
        
        :returns: The index of `item`, or nil if `item` is not in the list's items.
    */
    public func indexOfItem(item: ListItem) -> Int? {
        return find(_items, item)
    }
    
    /**
        Ensures that the items that are provided can be inserted into this list. All inserted items
        must be incomplete when inserted.
        
        :param: incompleteItems The items that should be incomplete.
        :param: index The index into which the items should be inserted.
        
        :returns: `true` if all items are incomplete and `index` comes before the first complete item's
                  index, otherwise `false`.
    */
    public func canInsertIncompleteItems(incompleteItems: [ListItem], atIndex index: Int) -> Bool {
        let completeItems = incompleteItems.filter { $0.isComplete }
        
        if !completeItems.isEmpty { return false }
        
        return index <= separatorIndex
    }
    
    /**
        Inserts iterms according to their completion state, maintaining their initial ordering. For
        example, if items are [complete(0), incomplete(1), incomplete(2), completed(3)], they will
        be inserted into two sections of the items. [incomplete(1), incomplete(2)] will be inserted
        at index 0 of the list and [complete(0), complete(3)] will be inserted at the index of the
        list.
        
        :params: itemsToInsert The iterms to insert.

        :returns: The indexes of the items that were inserted.
    */
    public func insertItems(itemsToInsert: [ListItem]) -> NSIndexSet {
        let initialCount = count
        
        var incompleteItemsCount = 0
        var completeItemsCount = 0
        
        for item in itemsToInsert {
            if item.isComplete {
                _items.insert(item, atIndex: count)
                
                completeItemsCount++
            }
            else {
                _items.insert(item, atIndex: incompleteItemsCount)
                
                incompleteItemsCount++
            }
        }
        
        let insertedIndexes = NSMutableIndexSet()
        
        let incompleteItemsRange = NSRange(location: 0, length: incompleteItemsCount)
        insertedIndexes.addIndexesInRange(incompleteItemsRange)
        
        let completeItemsRange = NSRange(location: initialCount + incompleteItemsCount, length: completeItemsCount)
        insertedIndexes.addIndexesInRange(completeItemsRange)
        
        return insertedIndexes
    }
    
    /**
        Inserts an item at a specific index. If the index is not valid (that is, if the item is complete
        but the `index` is not in the range of the complete items), the method traps.
        
        :param: item The item to insert.
        :param: index The index to insert `item` at.
    */
    public func insertItem(item: ListItem, atIndex index: Int) {
        var isValidInsertion = false
        
        if item.isComplete {
            // If the item comes on or after the first incomplete item index, insert it.
            if let completedItemIndex = indexOfFirstCompletedItem {
                isValidInsertion = completedItemIndex...count ~= index
            }
            else if index == count {
                // If there is no completed item, the only place a completed item can be inserted is at
                // the end of the list.
                isValidInsertion = true
            }
        }
        else {
            // If there is at least one completed item, make sure the target index precedes the item.
            if let completedItemIndex = indexOfFirstCompletedItem {
                isValidInsertion = 0..<completedItemIndex ~= index
            }
            // If all are incomplete items, make sure the index is within the bounds of the array.
            else if 0...count ~= index {
                isValidInsertion = true
            }
        }
        
        if isValidInsertion {
            _items.insert(item, atIndex: index)
        }
        else {
            fatalError("This item could not be inserted at the requested index.")
        }
    }
    
    /**
        Inserts an item at an index chosen based on the `isComplete` state of `item`. If `item.isComplete`
        is `true`, `items` is inserted at the tail of the items. If it is `false`, `item` is inserted
        at the head of the items.
        
        :param: item The item to insert.
        
        :returns: The index of the inserted item.
    */
    public func insertItem(item: ListItem) -> Int {
        let index = item.isComplete ? count : 0
        
        _items.insert(item, atIndex: index)
        
        return index
    }
    
    /**
        Tests whether an item can be inserted at a given index.
        
        :param: item The item to test for insertion.
        :param: toIndex The index to use to determine if `item` can be inserted into the list.
        :param: inclusive Whether ot not testing `toIndex` should be an inclusive range.
        
        :returns: Whether or not the item can be inserted at a given index.
    */
    public func canMoveItem(item: ListItem, toIndex: Int, inclusive: Bool) -> Bool {
        if let fromIndex = find(items, item) {
            if item.isComplete {
                return separatorIndex...count  ~= toIndex
            }
            else if inclusive {
                return 0...separatorIndex ~= toIndex
            }
            else {
                return 0..<separatorIndex ~= toIndex
            }
        }
        
        return false
    }
    
    /**
        Moves `item` to `toIndex`. This method traps if `item` cannot be moved, based on the result of
        `canMoveItem(_:toIndex:inclusive:)`.
        
        :param: item The item to move.
        :param: toIndex The index to move `item` to.
        
        :returns: The pair of indexes that represent the move.
    */
    public func moveItem(item: ListItem, var toIndex: Int) -> (fromIndex: Int, toIndex: Int) {
        // Note that a parameter marked as `var` can be reassigned within the context of the func.
        
        if !canMoveItem(item, toIndex: toIndex, inclusive: false) {
            fatalError("Cannot move the item to an invalid index.")
        }
        
        let fromIndex = find(_items, item)!
        
        _items.removeAtIndex(fromIndex)
        
        // Decrement `toIndex` if it is ordered befored the `fromIndex`.
        if fromIndex < toIndex {
            toIndex--
        }
        
        _items.insert(item, atIndex: toIndex)
        
        return (fromIndex, toIndex)
    }
    
    /**
        Removes `itemsToRemove` from this list's items. This method traps if an item is provided that
        doesn't exist in this list.
        
        :param: itemsToRemove The items to remove.
    */
    public func removeItems(itemsToRemove: [ListItem]) {
        for item in itemsToRemove {
            _items.removeAtIndex(find(items, item)!)
        }
    }
    
    /**
        Toggles an item's completion state and moves the item to the appropriate index. This method
        traps if `item` is not in this list's items.
        
        :param: item The item to toggle.
        :param: preferredTargetIndex The target index at which to insert the item. The default value
                signals that the item should be inserted at the same place as a call to
                insertItem(_:) would be inserted.
        
        :returns: The pair of indexes that represent the move.
    */
    public func toggleItem(item: ListItem, preferredTargetIndex: Int? = nil) -> (fromIndex: Int, toIndex: Int) {
        if let fromIndex = find(items, item) {
            _items.removeAtIndex(fromIndex)
            
            item.isComplete = !item.isComplete
            
            var toIndex: Int
            
            if let actualPreferredTargetIndex = preferredTargetIndex {
                toIndex = actualPreferredTargetIndex
            }
            else {
                toIndex = item.isComplete ? count : separatorIndex
            }
            
            _items.insert(item, atIndex: toIndex)
            
            return (fromIndex: fromIndex, toIndex: toIndex)
        }
        
        fatalError("Toggling an item that isn't in the list is undefined.")
    }
    
    /**
        Sets the `isComplete` property of each item to the designated value.
        
        :param: completionState The value to assign to each item's `isComplete` property.
    */
    public func updateAllItemsToCompletionState(completionState: Bool) {
        for item in items {
            item.isComplete = completionState
        }
    }
    
    // MARK: Equality
    
    /**
        Overrides NSObject's isEqual(_:) instance method to return whether or not the list is equal
        to another list. A `List` is considered to be equal to another `List` if its color and items
        are equal.
        
        :param: object Any object, or nil.
        
        :returns: `true` if the object is a `List` and it has the same color and items as the receiving
                  instance. `false` otherwise.
    */
    override public func isEqual(object: AnyObject?) -> Bool {
        if let list = object as? List {
            if color != list.color {
                return false
            }
            
            return items == list.items
        }
        
        return false
    }
}

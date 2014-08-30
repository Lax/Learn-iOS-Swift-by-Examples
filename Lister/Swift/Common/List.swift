/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The List class manages a list of items and the color of the list.
            
*/

import Foundation

// To ensure that the List class can be serialized from both Swift and Objective-C, we need to make sure that
// the runtime name of the List class is the same in both contexts. To do this in Swift, we use the @objc attribute
// on the class with the desired runtime name.
@objc(AAPLList) class List: NSObject, NSCoding, NSCopying {
    // MARK: Types
    
    // Serialization keys that are using to implement NSCoding.
    struct SerializationKey {
        static let items = "items"
        static let color = "color"
    }

    // A nested enum type that defines the possible colors a list can have.
    enum Color: Int {
        case Gray, Blue, Green, Yellow, Orange, Red
    }
    
    // MARK: Properties

    var items: ListItem[]

    var color: Color
    
    var count: Int {
        return items.count
    }
    
    var indexOfFirstCompletedItem: Int {
        for (current, item) in enumerate(items) {
            if item.isComplete {
                return current
            }
        }
        
        return items.count
    }
    
    var isEmpty: Bool {
        return items.isEmpty
    }

    // MARK: Initializers

    init(color: List.Color, items: ListItem[]) {
        self.color = color
        self.items = items.map { $0.copy() as ListItem }
    }
    
    convenience init() {
        self.init(color: .Gray, items: [])
    }
    
    // MARK: NSCoding
    
    init(coder aDecoder: NSCoder) {
        items = aDecoder.decodeObjectForKey(SerializationKey.items) as ListItem[]
        color = List.Color.fromRaw(aDecoder.decodeIntegerForKey(SerializationKey.color))!
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(items as AnyObject[], forKey: SerializationKey.items)
        aCoder.encodeInteger(color.toRaw(), forKey: SerializationKey.color)
    }
    
    // MARK: NSCopying
    
    func copyWithZone(zone: NSZone) -> AnyObject  {
        return List(color: color, items: items)
    }

    // MARK: Subscripts
    
    subscript(index: Int) -> ListItem {
        return items[index]
    }
    
    subscript(#indexes: NSIndexSet) -> ListItem[] {
        var items = ListItem[]()
            
        indexes.enumerateIndexesUsingBlock { (idx, _) in
            items.append(self[idx])
        }
        
        return items
    }
    
    // MARK: List Management
    
    func indexOfItem(item: ListItem) -> Int {
        return find(items, item)!
    }
    
    // All inserted items must be incomplete.
    func canInsertIncompleteItems(incompleteItems: ListItem[], atIndex index: Int) -> Bool {
        let completeItems = incompleteItems.filter { $0.isComplete }

        if !completeItems.isEmpty { return false }

        return index <= indexOfFirstCompletedItem
    }
    
    // Items will be inserted according to their completion state, maintaining their initial ordering.
    // e.g. if items are [complete(0), incomplete(1), incomplete(2), completed(3)], they will be inserted
    // into to sections of the items array. [incomplete(1), incomplete(2)] will be inserted at index 0 of the
    // list. [complete(0), completed(3)] will be inserted at the index of the list.
    func insertItems(itemsToInsert: ListItem[]) -> NSIndexSet {
        let initialCount = count

        var incompleteItemsCount = 0
        var completeItemsCount = 0

        for item in reverse(itemsToInsert) {
            if item.isComplete {
                completeItemsCount++
                
                items.insert(item, atIndex: count)
            }
            else {
                incompleteItemsCount++
                
                items.insert(item, atIndex: 0)
            }
        }
        
        let insertedIndexes = NSMutableIndexSet()
        
        insertedIndexes.addIndexesInRange(NSRange(location: 0, length: incompleteItemsCount))
        insertedIndexes.addIndexesInRange(NSRange(location: initialCount + incompleteItemsCount, length: completeItemsCount))
        
        return insertedIndexes
    }
    
    func insertItem(item: ListItem, atIndex index: Int) {
        items.insert(item, atIndex: index)
    }
    
    func insertItem(item: ListItem) -> Int {
        let index = item.isComplete ? count : 0
        
        items.insert(item, atIndex: index)
        
        return index
    }
    
    func canMoveItem(item: ListItem, toIndex: Int, inclusive: Bool) -> Bool {
        if let fromIndex = find(items, item) {
            if item.isComplete {
                return toIndex >= indexOfFirstCompletedItem && toIndex <= items.count
            }
            else if inclusive {
                return toIndex >= 0 && toIndex <= indexOfFirstCompletedItem
            }
            else {
                return toIndex >= 0 && toIndex < indexOfFirstCompletedItem
            }
        }
        
        return false
    }
    
    // Note that a parameter marked as `var` can be reassigned within the context of the func.
    func moveItem(item: ListItem, var toIndex: Int) -> (fromIndex: Int, toIndex: Int) {
        if let fromIndex = find(items, item) {
            items.removeAtIndex(fromIndex)
            
            // Decrement `toIndex` if it is ordered befored the fromIndex.
            if fromIndex < toIndex {
                toIndex--
            }
            
            items.insert(item, atIndex: toIndex)
            
            return (fromIndex: fromIndex, toIndex: toIndex)
        }
        
        fatalError("Moving items that aren't in the list is undefined.")
    }
    
    func removeItems(itemsToRemove: ListItem[]) {
        for item in itemsToRemove {
            items.removeAtIndex(find(items, item)!)
        }
    }
    
    // Toggles an item's completion state and moves the item to the appropriate index. The normalized from/to indexes are returned.
    func toggleItem(item: ListItem, preferredTargetIndex: Int? = nil) -> (fromIndex: Int, toIndex: Int) {
        if let fromIndex = find(items, item) {
            items.removeAtIndex(fromIndex)
            
            item.isComplete = !item.isComplete
            
            var toIndex: Int
            
            if let actualPreferredTargetIndex = preferredTargetIndex {
                toIndex = actualPreferredTargetIndex
            }
            else {
                toIndex = item.isComplete ? count : indexOfFirstCompletedItem
            }
            
            items.insert(item, atIndex: toIndex)
            
            return (fromIndex: fromIndex, toIndex: toIndex)
        }
        
        fatalError("Toggling an item that isn't in the list is undefined.")
    }
    
    // Set all of the items to be a specific completion state.
    func updateAllItemsToCompletionState(completionState: Bool) {
        for item in items {
            item.isComplete = completionState
        }
    }
    
    // MARK: Equality

    override func isEqual(object: AnyObject!) -> Bool {
        if let list = object as? List {
            return self == list
        }

        return false
    }
}

// An operator overload to equate two List objects.
func ==(lhs: List, rhs: List) -> Bool {
    if lhs.color != rhs.color {
        return false
    }
    
    return lhs.items == rhs.items
}

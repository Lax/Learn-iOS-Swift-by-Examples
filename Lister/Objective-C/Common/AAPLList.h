/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLList class manages a list of items and the color of the list.
            
*/

@import Foundation;

@class AAPLListItem;

/*!
 * The possible colors a list can have.
 */
typedef NS_ENUM(NSInteger, AAPLListColor) {
    AAPLListColorGray = 0,
    AAPLListColorBlue,
    AAPLListColorGreen,
    AAPLListColorYellow,
    AAPLListColorOrange,
    AAPLListColorRed
};

/*!
 * A lightweight structure that represents a move or toggle on a list item within the list. The
 * \c fromIndex and \c toIndex represent what index a given item moved from or to.
 */
typedef struct AAPLListOperationInfo {
    NSInteger fromIndex;
    NSInteger toIndex;
} AAPLListOperationInfo;

/*!
 * The \c AAPLList class manages the color of a list and each \c AAPLListItem, including the order of
 * the list. Incomplete items are located at the start of the items array, followed by complete list
 * items. There are many convenience methods on the \c AAPLList class to query whether an item can be
 * moved or inserted at a certain index, to perform those move and insert operations, to toggle an
 * item between a complete and incomplete state, and to fetch list items by index. Note that in order
 * to be able to archive and unarchive \c AAPLList objects in both the Objective-C and Swift versions
 * of the app, the Swift version of the app ensures that the runtime name of its \c List object is
 * also \c AAPLList.
 */
@interface AAPLList : NSObject <NSCoding, NSCopying>

/*!
 * Initializes an \c AAPLList instance with the designated color and items.
 *
 * \param color
 * The intended color of the list.
 *
 * \param items
 * The items that represent the underlying list. The \c AAPLList class copies the items in
 * initialization.
 */
- (instancetype)initWithColor:(AAPLListColor)color items:(NSArray *)items;

/*!
 * Initializes an \c AAPLList instance with a default color of gray and an empty items array.
 */
- (instancetype)init;

/*!
 *  The list's color. This property is stored when it is archived and read when it is unarchived.
 */
@property (nonatomic) AAPLListColor color;

/*!
 * \returns
 * A copy of the list items. The underlying items are stored when the list is archived and read when
 * they are unarchived.
 */
@property (nonatomic, readonly) NSArray *allItems;

/*!
 * \returns
 * The number of items in the list.
 */
@property (readonly) NSInteger count;

/*!
 * \returns
 * The index of the first complete item in the list of items. If there is no completed item, this
 * property returns \c NSNotFound.
 */
@property (readonly) NSInteger indexOfFirstCompletedItem;

/*!
 * \returns
 * \c YES if the list has no items, \c NO otherwise.
 */
@property (readonly, getter=isEmpty) BOOL empty;

/*!
 * Finds the \c AAPLListItem that corresponds to an index. The method traps if the index is out of bounds.
 *
 * \param index
 * The index for the requested item.
 *
 * \returns
 * The \c AAPLListItem object corresponding to the provided index.
 */
- (AAPLListItem *)objectAtIndexedSubscript:(NSUInteger)index;

/*!
 * Finds an array of \c AAPLListItem instances that correspond to a set of indexes. The method traps
 * if any index in the set is out of bounds.
 *
 * \param indexes
 * The indexes for the requested items.
 *
 * \returns
 * The \c AAPLListItem object corresponding to the provided index.
 */
- (NSArray *)objectForKeyedSubscript:(NSIndexSet *)indexes;

/*!
 * Computes the index of where an item is located.
 *
 * \param item
 * The item whose index should be found.
 *
 * \returns
 * The index of \c item, or \c NSNotFound if \c item is not in the list.
 */
- (NSInteger)indexOfItem:(AAPLListItem *)item;

/*!
 * Determines whether the items that are provided can be inserted into this list. All
 * inserted items must be incomplete when inserted.
 *
 * \param incompleteItems
 * The items that should be incomplete.
 *
 * \param index
 * The index into which the items should be inserted.
 *
 * \returns
 * \c YES if all items are incomplete and \c index comes before the first complete item's index.
 * \c NO otherwise.
 */
- (BOOL)canInsertIncompleteItems:(NSArray *)incompleteItems atIndex:(NSInteger)index;

/*!
 * Inserts iterms according to their completion state, maintaining their initial ordering. For example,
 * if items are [complete(0), incomplete(1), incomplete(2), completed(3)], they will be inserted into
 * two sections of the items. [incomplete(1), incomplete(2)] will be inserted at index 0 of the list
 * and [complete(0), completed(3)] will be inserted at the index of the list.
 *
 * \param itemsToInsert
 * The iterms to insert.
 *
 * \returns
 * The indexes of the items that were inserted.
 */
- (NSIndexSet *)insertItems:(NSArray *)itemsToInsert;

/*!
 * Inserts an item at a specific index. If the index is not valid (that is, the item is complete but
 * the \c index is not in the range of the complete items), the method traps.
 *
 * \param item
 * The item to insert.
 *
 * \param index
 * The index to insert \c item at.
 *
 * \returns
 * The \c AAPLListOperationInfo index pair that represent the move.
 */
- (void)insertItem:(AAPLListItem *)item atIndex:(NSInteger)index;

/*!
 * Inserts an item at an index chosen based on the \c completed state of \c item. If \c item.isComplete
 * is \c YES, \c items is inserted at the tail of the items. If it is \C NO, \c item is inserted at the
 * head of the items.
 *
 * \param item
 * The item to insert.
 *
 * \returns
 * The index of the inserted item.
 */
- (NSInteger)insertItem:(AAPLListItem *)item;

/*!
 * Tests to see whether or not an item can be inserted at a given index.
 *
 * \param item
 * The item to test for insertion.
 *
 * \param toIndex
 * The index to use to determine if \c item can be inserted into the list.
 *
 * \param index
 * inclusive Whether ot not testing \c toIndex should be an inclusive range.
 *
 * \returns
 * Whether or not the item can be inserted at a given index.
 */
- (BOOL)canMoveItem:(AAPLListItem *)item toIndex:(NSInteger)index inclusive:(BOOL)inclusive;

/*!
 * Moves \c item to \c toIndex. This method traps if \c item cannot be moved (based on the result of
 * \c -canMoveItem:toIndex:inclusive:.
 *
 * \param item
 * The item to move.
 *
 * \param toIndex
 * The index to move \c item to.
 *
 * \returns
 * The \c AAPLListOperationInfo index pair that represent the move.
 */
- (AAPLListOperationInfo)moveItem:(AAPLListItem *)item toIndex:(NSInteger)toIndex;

/*!
 * Removes \c itemsToRemove from this list's items. This method traps if an item is provided that
 * doesn't exist in this list.
 *
 * \param itemsToRemove
 * The items to remove.
 */
- (void)removeItems:(NSArray *)itemsToRemove;

/*!
 * Toggles an item's completion state and moves the item to the appropriate index. This method traps
 * if \c item is not in this list's items.
 *
 * \param item
 * The item to toggle.
 *
 * \param preferredTargetIndex
 * The target index at which to insert the item. A value of \c NSNotFound signals that the item
 * should be inserted at the same place as a call to \c -insertItem: would be inserted.
 *
 * \returns
 * The \c AAPLListOperationInfo index pair that represent the move.
 */
- (AAPLListOperationInfo)toggleItem:(AAPLListItem *)item withPreferredDestinationIndex:(NSInteger)preferredTargetIndex;

/*!
 * Sets the \c complete property of each item to the designated value.
 *
 * \param completionState
 * The value to assign to each item's \c complete property.
 */
- (void)updateAllItemsToCompletionState:(BOOL)completionState;

/*!
 * Determines whether or not a list is equal to another list. This is a specialization of \c -isEqual:
 * that is specific for instances of \c AAPLList.
 *
 * \param
 * list Any list.
 *
 * \returns
 * \c YES if the list has the same color and items as the receiving instance. \c NO otherwise.
 */
- (BOOL)isEqualToList:(AAPLList *)list;

@end

/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLList class manages a list of items and the color of the list.
            
*/

#import "AAPLList.h"
#import "AAPLListItem.h"

NSString *const AAPLListEncodingItemsKey = @"items";
NSString *const AAPLListEncodingColorKey = @"color";


@interface AAPLList ()

@property (readwrite, copy) NSMutableArray *items;
@property (readonly) NSInteger separatorIndex;

@end


@implementation AAPLList

#pragma mark - Initializers

- (instancetype)initWithColor:(AAPLListColor)color items:(NSArray *)items {
    self = [super init];
    
    if (self) {
        _items = [[NSMutableArray alloc] initWithArray:items copyItems:YES];
        _color = color;
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithColor:AAPLListColorGray items:@[]];
}


#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    if (self) {
        _items = [[aDecoder decodeObjectForKey:AAPLListEncodingItemsKey] mutableCopy];
        
        _color = (AAPLListColor)[aDecoder decodeIntegerForKey:AAPLListEncodingColorKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.items forKey:AAPLListEncodingItemsKey];
    [aCoder encodeInteger:self.color forKey:AAPLListEncodingColorKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [[AAPLList alloc] initWithColor:self.color items:self.items];
}

#pragma mark - Subscripts

- (NSArray *)objectForKeyedSubscript:(NSIndexSet *)indexes {
    return [self.items objectsAtIndexes:indexes];
}

- (AAPLListItem *)objectAtIndexedSubscript:(NSUInteger)index {
    return self.items[index];
}

#pragma mark - List Management

- (BOOL)isEmpty {
    return self.items.count <= 0;
}

- (NSInteger)count {
    return self.items.count;
}

- (NSInteger)indexOfItem:(AAPLListItem *)item {
    return [self.items indexOfObject:item];
}

/*!
 * Use this function to ensure that all inserted items are complete.
 * All inserted items must be incomplete when inserted.
 */
- (BOOL)canInsertIncompleteItems:(NSArray *)incompleteItems atIndex:(NSInteger)index {
    BOOL anyCompleteItem = NO;
    for (AAPLListItem *item in incompleteItems) {
        anyCompleteItem |= item.complete;
    }
    
    if (anyCompleteItem) {
        return NO;
    }
    
    return index <= self.indexOfFirstCompletedItem;
}

/*!
 * Items will be inserted according to their completion state, maintaining their initial ordering.
 * e.g. if items are [complete(0), incomplete(1), incomplete(2), completed(3)], they will be inserted
 * into to sections of the items array. [incomplete(1), incomplete(2)] will be inserted at index 0 of the
 * list. [complete(0), completed(3)] will be inserted at the index of the list.
 */
- (NSIndexSet *)insertItems:(NSArray *)itemsToInsert {
    NSInteger initialCount = self.count;
    
    NSInteger incompleteItemsCount = 0;
    NSInteger completedItemsCount = 0;
    
    for (AAPLListItem *item in itemsToInsert) {
        if (item.complete) {
            [self.items insertObject:item atIndex:self.count];

            completedItemsCount++;
        }
        else {
            [self.items insertObject:item atIndex:incompleteItemsCount];
            
            incompleteItemsCount++;
        }
    }
    
    NSMutableIndexSet *insertedIndexes = [[NSMutableIndexSet alloc] init];
    
    NSRange incompleteItemsRange = NSMakeRange(0, incompleteItemsCount);
    [insertedIndexes addIndexesInRange:incompleteItemsRange];

    NSRange completeItemsRange = NSMakeRange(incompleteItemsCount + initialCount, completedItemsCount);
    [insertedIndexes addIndexesInRange:completeItemsRange];
    
    return insertedIndexes;
}

- (void)insertItem:(AAPLListItem *)item atIndex:(NSInteger)index {
    [self.items insertObject:item atIndex:index];
}

- (NSInteger)insertItem:(AAPLListItem *)item {
    NSInteger index = item.complete ? self.count : 0;
    
    [self.items insertObject:item atIndex:index];
    
    return index;
}

- (BOOL)canMoveItem:(AAPLListItem *)item toIndex:(NSInteger)index inclusive:(BOOL)inclusive {
    NSInteger fromIndex = [self.items indexOfObject:item];
    
    if (fromIndex != NSNotFound) {
        if (item.complete) {
            return index <= self.count && index >= self.indexOfFirstCompletedItem;
        }
        else if (inclusive) {
            return index >= 0 && index <= self.indexOfFirstCompletedItem;
        }
        else {
            return index >= 0 && index < self.indexOfFirstCompletedItem;
        }
    }
    
    return NO;
}

- (AAPLListOperationInfo)moveItem:(AAPLListItem *)item toIndex:(NSInteger)toIndex {
    NSInteger fromIndex = [self.items indexOfObject:item];
    
    NSAssert(fromIndex != NSNotFound, @"Moving an item that isn't in the list is undefined.");

    [self.items removeObject:item];
    
    NSInteger normalizedToIndex = toIndex;
    
    if (fromIndex < toIndex) {
        normalizedToIndex--;
    }
    
    [self.items insertObject:item atIndex:normalizedToIndex];
    
    AAPLListOperationInfo moveInfo = {
        .fromIndex = fromIndex,
        .toIndex = normalizedToIndex
    };
    
    return moveInfo;
}

- (void)removeItems:(NSArray *)itemsToRemove {
    [self.items removeObjectsInArray:itemsToRemove];
}

// Toggles an item's completion state and moves the item to the appropriate index. The normalized from/to indexes are returned in the AAPLListOperationInfo struct.
- (AAPLListOperationInfo)toggleItem:(AAPLListItem *)item withPreferredDestinationIndex:(NSInteger)preferredTargetIndex {
    NSInteger fromIndex = [self.items indexOfObject:item];
    
    NSAssert(fromIndex != NSNotFound, @"Toggling an item that isn't in the list is undefined.");
    
    [self.items removeObjectAtIndex:fromIndex];
    
    item.complete = !item.complete;
    
    NSInteger toIndex = preferredTargetIndex;
    
    if (toIndex == NSNotFound) {
        toIndex = item.complete ? self.count : self.separatorIndex;
    }
    
    [self.items insertObject:item atIndex:toIndex];
    
    AAPLListOperationInfo toggleInfo = {
        .fromIndex = fromIndex,
        .toIndex = toIndex
    };
    
    return toggleInfo;
}

// Set all of the items to be a specific completion state.
- (void)updateAllItemsToCompletionState:(BOOL)completionState {
    for (AAPLListItem *item in self.items) {
        item.complete = completionState;
    }
}

#pragma mark - Convenience

- (NSInteger)indexOfFirstCompletedItem {
    return [self.items indexOfObjectPassingTest:^BOOL(AAPLListItem *item, NSUInteger index, BOOL *stop) {
        return item.complete;
    }];
}

- (NSArray *)allItems {
    return [self.items copy];
}

- (NSInteger)separatorIndex {
    NSInteger indexOfFirstCompletedItem = self.indexOfFirstCompletedItem;

    if (indexOfFirstCompletedItem != NSNotFound) {
        return indexOfFirstCompletedItem;
    }

    return self.count;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[AAPLList class]]) {
        return [self isEqualToList:object];
    }
    
    return NO;
}

#pragma mark - Equality

- (BOOL)isEqualToList:(AAPLList *)list {
    if (self.color != list.color) {
        return NO;
    }

    return [self.items isEqualToArray:list.items];
}

@end

/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLListController and \c AAPLListControllerDelegate infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to \c AAPLListInfo objects. In addition, it also provides a way for parts of the application to present errors that occured when creating or removing lists.
            
*/

#import "AAPLListController.h"
#import "AAPLListCoordinator.h"
#import "AAPLListInfo.h"

@interface AAPLListController () <AAPLListCoordinatorDelegate>

/*!
 * The \c AAPLListInfo objects that are cached by the \c AAPLListController to allow for users of the
 * \c AAPLListController class to easily subscript the controller.
 */
@property (nonatomic, strong) NSMutableArray *listInfos;

/*!
 * @return A private, local queue to the \c AAPLListController that is used to perform updates on
 *         \c listInfos.
 */
@property (nonatomic, strong) dispatch_queue_t listInfoQueue;

/*!
 * The sort comparator that's set in initialization. The sort predicate ensures a strict sort ordering
 * of the \c listInfos array. If \c sortComparator is nil, the sort order is ignored.
 */
@property (nonatomic, copy) NSComparisonResult (^sortComparator)(AAPLListInfo *lhs, AAPLListInfo *rhs);

@end


@implementation AAPLListController
@synthesize listCoordinator = _listCoordinator;

#pragma mark - Initialization

- (instancetype)initWithListCoordinator:(id<AAPLListCoordinator>)listCoordinator sortComparator:(NSComparisonResult (^)(AAPLListInfo *, AAPLListInfo *))sortComparator {
    self = [super init];

    if (self) {
        _listCoordinator = listCoordinator;
        _sortComparator = sortComparator;

        _listInfoQueue = dispatch_queue_create("com.example.apple-samplecode.lister.listcontroller", DISPATCH_QUEUE_SERIAL);
        _listInfos = [NSMutableArray array];
        
        _listCoordinator.delegate = self;

        [_listCoordinator startQuery];
    }
    
    return self;
}

#pragma mark - Property Overrides

- (NSInteger)count {
    return self.listInfos.count;
}

- (void)setListCoordinator:(id<AAPLListCoordinator>)listCoordinator {
    if (![_listCoordinator isEqual:listCoordinator]) {
        id<AAPLListCoordinator> oldListCoordinator = _listCoordinator;
        _listCoordinator = listCoordinator;
        
        [oldListCoordinator stopQuery];
        
        // Map the listInfo objects protected by listInfoQueue.
        __block NSArray *allURLs;
        dispatch_sync(self.listInfoQueue, ^{
            allURLs = [self.listInfos valueForKey:@"URL"];
        });
        [self processContentChangesWithInsertedURLs:@[] removedURLs:allURLs updatedURLs:@[]];
        
        _listCoordinator.delegate = self;
        oldListCoordinator.delegate = nil;
        
        [_listCoordinator startQuery];
    }
}

#pragma mark - Subscripting

- (AAPLListInfo *)objectAtIndexedSubscript:(NSInteger)index {
    // Fetch the appropriate list info protected by listInfoQueue.
    __block AAPLListInfo *listInfo = nil;

    dispatch_sync(self.listInfoQueue, ^{
        listInfo = self.listInfos[index];
    });
    
    return listInfo;
}

#pragma mark - Inserting / Removing / Managing / Updating AAPLListInfo Objects

- (void)removeListInfo:(AAPLListInfo *)listInfo {
    [self.listCoordinator removeListAtURL:listInfo.URL];
}

- (void)createListInfoForList:(AAPLList *)list withName:(NSString *)name {
    [self.listCoordinator createURLForList:list withName:name];
}

- (BOOL)canCreateListInfoWithName:(NSString *)name {
    return [self.listCoordinator canCreateListWithName:name];
}

- (void)setListInfoHasNewContents:(AAPLListInfo *)listInfo {
    dispatch_async(self.listInfoQueue, ^{
        // Remove the old list info and replace it with the new one.
        NSInteger indexOfListInfo = [self.listInfos indexOfObject:listInfo];
        self.listInfos[indexOfListInfo] = listInfo;
        
        [self.delegate listControllerWillChangeContent:self];
        [self.delegate listController:self didUpdateListInfo:listInfo atIndex:indexOfListInfo];
        [self.delegate listControllerDidChangeContent:self];
    });
}

- (void)listCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs removedURLs:(NSArray *)removedURLs updatedURLs:(NSArray *)updatedURLs {
    [self processContentChangesWithInsertedURLs:insertedURLs removedURLs:removedURLs updatedURLs:updatedURLs];
}

- (void)listCoordinatorDidFailCreatingListAtURL:(NSURL *)URL withError:(NSError *)error {
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithURL:URL];
    
    [self.delegate listController:self didFailCreatingListInfo:listInfo withError:error];
}

- (void)listCoordinatorDidFailRemovingListAtURL:(NSURL *)URL withError:(NSError *)error {
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithURL:URL];

    [self.delegate listController:self didFailRemovingListInfo:listInfo withError:error];
}

#pragma mark - Change Processing

/*!
 * Processes inteneded changes to the \c AAPLListController object's \c AAPLListInfo collection. This
 * implementation performs the updates and determines where each of these URLs were located so that
 * the controller can forward the new / removed / updated indexes as well.
 *
 * @param insertedURLs The \c NSURL instances that are newly tracked.
 * @param removedURLs The \c NSURL instances that have just been untracked.
 * @param updatedURLs The \c NSURL instances that have had their underlying model updated.
 */
- (void)processContentChangesWithInsertedURLs:(NSArray *)insertedURLs removedURLs:(NSArray *)removedURLs updatedURLs:(NSArray *)updatedURLs {
    NSArray *insertedListInfos = [self listInfosByMappingURLs:insertedURLs];
    NSArray *removedListInfos = [self listInfosByMappingURLs:removedURLs];
    NSArray *updatedListInfos = [self listInfosByMappingURLs:updatedURLs];
    
    dispatch_async(self.listInfoQueue, ^{
        // Filter out all lists that are already included in the tracked lists.
        NSIndexSet *indexesOfTrackedRemovedListInfos = [removedListInfos indexesOfObjectsPassingTest:^BOOL(AAPLListInfo *listInfo, NSUInteger idx, BOOL *stop) {
            return [self.listInfos containsObject:listInfo];
        }];

        NSIndexSet *indexesOfUntrackedInsertedListInfos = [insertedListInfos indexesOfObjectsPassingTest:^BOOL(AAPLListInfo *listInfo, NSUInteger idx, BOOL *stop) {
            return ![self.listInfos containsObject:listInfo];
        }];
        
        if (indexesOfUntrackedInsertedListInfos.count == 0 && indexesOfTrackedRemovedListInfos.count == 0 && updatedURLs.count == 0) {
            return;
        }
        
        NSArray *trackedRemovedListInfos = [removedListInfos objectsAtIndexes:indexesOfTrackedRemovedListInfos];
        NSArray *untrackedInsertedListInfos = [insertedListInfos objectsAtIndexes:indexesOfUntrackedInsertedListInfos];

        [self.delegate listControllerWillChangeContent:self];
        
        // Remove all of the removed lists. We need to send the delegate the removed indexes before
        // the listInfos array is mutated to reflect the new changes. To do that, we'll build up the
        // array of removed indexes *before* we mutate it.
        NSMutableArray *indexesOfTrackedRemovedListInfosInListInfos = [NSMutableArray arrayWithCapacity:trackedRemovedListInfos.count];
        for (AAPLListInfo *trackedRemovedListInfo in trackedRemovedListInfos) {
            NSInteger indexOfTrackedRemovedListInfoInListInfos = [self.listInfos indexOfObject:trackedRemovedListInfo];
            
            [indexesOfTrackedRemovedListInfosInListInfos addObject:@(indexOfTrackedRemovedListInfoInListInfos)];
        }
        
        [trackedRemovedListInfos enumerateObjectsUsingBlock:^(AAPLListInfo *removedListInfo, NSUInteger idx, BOOL *stop) {
            [self.listInfos removeObject:removedListInfo];

            NSNumber *indexOfTrackedRemovedListInfoInListInfos = indexesOfTrackedRemovedListInfosInListInfos[idx];
            
            [self.delegate listController:self didRemoveListInfo:removedListInfo atIndex:indexOfTrackedRemovedListInfoInListInfos.integerValue];
        }];
        
        // Add the new lists.
        [self.listInfos addObjectsFromArray:untrackedInsertedListInfos];
        
        // Nor sort the list after all the inserts.
        if (self.sortComparator) {
            [self.listInfos sortUsingComparator:self.sortComparator];
        }
        
        for (AAPLListInfo *untrackedInsertedListInfo in untrackedInsertedListInfos) {
            NSInteger insertedIndex = [self.listInfos indexOfObject:untrackedInsertedListInfo];
            
            [self.delegate listController:self didInsertListInfo:untrackedInsertedListInfo atIndex:insertedIndex];
        }
        
        // Update the old lists.
        for (AAPLListInfo *updatedListInfo in updatedListInfos) {
            NSInteger updatedIndex = [self.listInfos indexOfObject:updatedListInfo];
            
            NSAssert(updatedIndex != NSNotFound, @"An updated list info should always already be tracked in the list infos.");
            
            self.listInfos[updatedIndex] = updatedListInfo;
            [self.delegate listController:self didUpdateListInfo:updatedListInfo atIndex:updatedIndex];
        }
        
        [self.delegate listControllerDidChangeContent:self];
    });
}

#pragma mark - Convenience

- (NSArray *)listInfosByMappingURLs:(NSArray *)URLs {
    NSMutableArray *listInfos = [NSMutableArray arrayWithCapacity:URLs.count];
    
    for (NSURL *URL in URLs) {
        AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithURL:URL];
        
        [listInfos addObject:listInfo];
    }
    
    return listInfos;
}

@end

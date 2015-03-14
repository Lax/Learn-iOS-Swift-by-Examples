/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListsController and \c AAPLListsControllerDelegate infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to \c AAPLListInfo objects. In addition, it also provides a way for parts of the application to present errors that occured when creating or removing lists.
*/

#import "AAPLListsController.h"
#import "AAPLListCoordinator.h"
#import "AAPLListInfo.h"

@interface AAPLListsController () <AAPLListCoordinatorDelegate>

/*!
 * The \c AAPLListInfo objects that are cached by the \c AAPLListsController to allow for users of the
 * \c AAPLListsController class to easily subscript the controller.
 */
@property (nonatomic, strong) NSMutableArray *listInfos;

/*!
 * @return A private, local queue to the \c AAPLListsController that is used to perform updates on
 *         \c listInfos.
 */
@property (nonatomic, strong) dispatch_queue_t listInfoQueue;

/*!
 * The sort comparator that's set in initialization. The sort predicate ensures a strict sort ordering
 * of the \c listInfos array. If \c sortComparator is nil, the sort order is ignored.
 */
@property (nonatomic, copy) NSComparisonResult (^sortComparator)(AAPLListInfo *lhs, AAPLListInfo *rhs);

/*!
 * The queue in which the \c AAPLListsController object invokes delegate messages.
 */
@property (nonatomic, strong) NSOperationQueue *delegateQueue;

@end


@implementation AAPLListsController
@synthesize listCoordinator = _listCoordinator;
@synthesize delegateQueue = _delegateQueue;

#pragma mark - Initialization

- (instancetype)initWithListCoordinator:(id<AAPLListCoordinator>)listCoordinator delegateQueue:(NSOperationQueue *)delegateQueue sortComparator:(NSComparisonResult (^)(AAPLListInfo *lhs, AAPLListInfo *rhs))sortComparator {
    self = [super init];

    if (self) {
        _listCoordinator = listCoordinator;
        _sortComparator = sortComparator;
        
        _delegateQueue = delegateQueue ?: [NSOperationQueue mainQueue];

        _listInfoQueue = dispatch_queue_create("com.example.apple-samplecode.lister.listcontroller", DISPATCH_QUEUE_SERIAL);
        _listInfos = [NSMutableArray array];
        
        _listCoordinator.delegate = self;
    }
    
    return self;
}

- (void)startSearching {
    [self.listCoordinator startQuery];
}

- (void)stopSearching {
    [self.listCoordinator stopQuery];
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
        
        [self.delegateQueue addOperationWithBlock:^{
            if ([self.delegate respondsToSelector:@selector(listsControllerWillChangeContent:)]) {
                [self.delegate listsControllerWillChangeContent:self];
            }
            
            if ([self.delegate respondsToSelector:@selector(listsController:didUpdateListInfo:atIndex:)]) {
                [self.delegate listsController:self didUpdateListInfo:listInfo atIndex:indexOfListInfo];
            }
            
            if ([self.delegate respondsToSelector:@selector(listsControllerDidChangeContent:)]) {
                [self.delegate listsControllerDidChangeContent:self];
            }
        }];
    });
}

- (void)listCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs removedURLs:(NSArray *)removedURLs updatedURLs:(NSArray *)updatedURLs {
    [self processContentChangesWithInsertedURLs:insertedURLs removedURLs:removedURLs updatedURLs:updatedURLs];
}

- (void)listCoordinatorDidFailCreatingListAtURL:(NSURL *)URL withError:(NSError *)error {
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithURL:URL];
    
    [self.delegateQueue addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(listsController:didFailCreatingListInfo:withError:)]) {
            [self.delegate listsController:self didFailCreatingListInfo:listInfo withError:error];
        }
    }];
}

- (void)listCoordinatorDidFailRemovingListAtURL:(NSURL *)URL withError:(NSError *)error {
    AAPLListInfo *listInfo = [[AAPLListInfo alloc] initWithURL:URL];
    
    [self.delegateQueue addOperationWithBlock:^{
        if ([self.delegate respondsToSelector:@selector(listsController:didFailRemovingListInfo:withError:)]) {
            [self.delegate listsController:self didFailRemovingListInfo:listInfo withError:error];
        }
    }];
}

#pragma mark - Change Processing

/*!
 * Processes changes to the \c AAPLListsController object's \c AAPLListInfo collection. This
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
    
    [self.delegateQueue addOperationWithBlock:^{
        // Filter out all lists that are already included in the tracked lists.
        __block NSArray *trackedRemovedListInfos;
        __block NSArray *untrackedInsertedListInfos;
        
        dispatch_sync(self.listInfoQueue, ^{
            NSPredicate *containPredicate = [NSPredicate predicateWithFormat:@"self in %@", self.listInfos];
            trackedRemovedListInfos = [removedListInfos filteredArrayUsingPredicate:containPredicate];
            
            NSPredicate *doesntContainPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:containPredicate];
            untrackedInsertedListInfos = [insertedListInfos filteredArrayUsingPredicate:doesntContainPredicate];
        });
        
        if (untrackedInsertedListInfos.count == 0 && trackedRemovedListInfos.count == 0 && updatedListInfos.count == 0) {
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(listsControllerWillChangeContent:)]) {
            [self.delegate listsControllerWillChangeContent:self];
        }
        
        // Remove
        for (AAPLListInfo *trackedRemovedListInfo in trackedRemovedListInfos) {
            __block NSInteger trackedRemovedListInfoIndex;
            
            dispatch_sync(self.listInfoQueue, ^{
                trackedRemovedListInfoIndex = [self.listInfos indexOfObject:trackedRemovedListInfo];
                
                [self.listInfos removeObjectAtIndex:trackedRemovedListInfoIndex];
            });
            
            if ([self.delegate respondsToSelector:@selector(listsController:didRemoveListInfo:atIndex:)]) {
                [self.delegate listsController:self didRemoveListInfo:trackedRemovedListInfo atIndex:trackedRemovedListInfoIndex];
            }
        }
        
        // Sort the untracked inserted list infos
        if (self.sortComparator) {
            untrackedInsertedListInfos = [untrackedInsertedListInfos sortedArrayUsingComparator:self.sortComparator];
        }
        
        // Insert
        for (AAPLListInfo *untrackedInsertedListInfo in untrackedInsertedListInfos) {
            __block NSInteger untrackedInsertedListInfoIndex;
            
            dispatch_sync(self.listInfoQueue, ^{
                [self.listInfos addObject:untrackedInsertedListInfo];
                
                if (self.sortComparator) {
                    [self.listInfos sortUsingComparator:self.sortComparator];
                }
                
                untrackedInsertedListInfoIndex = [self.listInfos indexOfObject:untrackedInsertedListInfo];
            });
            
            if ([self.delegate respondsToSelector:@selector(listsController:didInsertListInfo:atIndex:)]) {
                [self.delegate listsController:self didInsertListInfo:untrackedInsertedListInfo atIndex:untrackedInsertedListInfoIndex];
            }
        }
        
        // Update
        for (AAPLListInfo *updatedListInfo in updatedListInfos) {
            __block NSInteger updatedListInfoIndex;
            
            dispatch_sync(self.listInfoQueue, ^{
                updatedListInfoIndex = [self.listInfos indexOfObject:updatedListInfo];
                
                // Track the new list info instead of the old one.
                if (updatedListInfoIndex != NSNotFound) {
                    self.listInfos[updatedListInfoIndex] = updatedListInfo;
                }
            });
            
            if (updatedListInfoIndex != NSNotFound && [self.delegate respondsToSelector:@selector(listsController:didUpdateListInfo:atIndex:)]) {
                [self.delegate listsController:self didUpdateListInfo:updatedListInfo atIndex:updatedListInfoIndex];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(listsControllerDidChangeContent:)]) {
            [self.delegate listsControllerDidChangeContent:self];
        }
    }];
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

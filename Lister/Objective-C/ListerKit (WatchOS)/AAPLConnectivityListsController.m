/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLConnectivityListsController and \c AAPLConnectivityListsControllerDelegate infrastructure provide a mechanism for other objects within the application to be notified of inserts, removes, and updates to \c AAPLListInfo objects.
*/

#import "AAPLConnectivityListsController.h"

#import "AAPLListInfo.h"
#import "AAPLAppConfiguration.h"
#import "AAPLListUtilities.h"


@import WatchConnectivity;

@interface AAPLConnectivityListsController () <WCSessionDelegate>

@property (nonatomic, strong) NSMutableArray *listInfos;

@property (nonatomic, strong) dispatch_queue_t listInfoQueue;

@property (nonatomic, strong) NSPredicate *predicate;

@end

@implementation AAPLConnectivityListsController

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _listInfos = [NSMutableArray array];
        
        _listInfoQueue = dispatch_queue_create("com.example.apple-samplecode.lister.listcontroller", DISPATCH_QUEUE_SERIAL);
        
        if ([WCSession isSupported]) {
            [WCSession defaultSession].delegate = self;
            [[WCSession defaultSession] activateSession];
        }
    }
    
    return self;
}

- (instancetype)initWithListName:(NSString *)listName {
    self = [super init];
    
    if (self) {
        _listInfos = [NSMutableArray array];
        
        _listInfoQueue = dispatch_queue_create("com.example.apple-samplecode.lister.listcontroller", DISPATCH_QUEUE_SERIAL);
        
        _predicate = [NSPredicate predicateWithFormat:@"(name = %@)", listName];
        
        if ([WCSession isSupported]) {
            [WCSession defaultSession].delegate = self;
            [[WCSession defaultSession] activateSession];
        }
    }
    
    return self;
}

- (void)startSearching {
    if ([WCSession defaultSession].receivedApplicationContext != nil) {
        [self processApplicationContext:[WCSession defaultSession].receivedApplicationContext];
    }
}

- (void)stopSearching {
    // Once the session has been started, stop receiving updates by setting the delegate to nil.
    self.delegate = nil;
}

#pragma mark - Property Overrides

- (NSInteger)count {
    return self.listInfos.count;
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

#pragma - WCSessionDelegate

- (void)session:(nonnull WCSession *)session didReceiveApplicationContext:(nonnull NSDictionary<NSString *,id> *)applicationContext {
    [self processApplicationContext:applicationContext];
}

- (void)processApplicationContext:(nonnull NSDictionary<NSString *,id> *)applicationContext {
    NSArray<NSDictionary<NSString *, id> *> *lists = applicationContext[AAPLApplicationActivityContextCurrentListsKey];
    
    NSInteger numberOfLists = lists.count;
    
    NSMutableArray *changedListInfos = [NSMutableArray array];
    for (int idx = 0; idx < numberOfLists; idx++) {
        AAPLListInfo *info = [[AAPLListInfo alloc] init];
        info.name = lists[idx][AAPLApplicationActivityContextListNameKey];
        info.color = [lists[idx][AAPLApplicationActivityContextListColorKey] integerValue];
        
        [changedListInfos addObject:info];
    }
    
    // If a filter predicate has been supplied, apply it.
    if (self.predicate) {
        [changedListInfos filterUsingPredicate:self.predicate];
    }
    
    if ([self.delegate respondsToSelector:@selector(listsControllerWillChangeContent:)]) {
        [self.delegate listsControllerWillChangeContent:self];
    }
    
    NSArray *removed = [self removedListInfosToChangedListInfos:changedListInfos];
    NSArray *inserted = [self insertedListInfosToChangedListInfos:changedListInfos];
    NSArray *updated = [self updatedListInfosToChangedListInfos:changedListInfos];
    
    for (AAPLListInfo *listInfoToRemove in removed) {
        NSInteger indexOfListInfoToRemove = [self.listInfos indexOfObject:listInfoToRemove];
        
        [self.listInfos removeObjectAtIndex:indexOfListInfoToRemove];
        
        if ([self.delegate respondsToSelector:@selector(listsController:didRemoveListInfo:atIndex:)]) {
            [self.delegate listsController:self didRemoveListInfo:listInfoToRemove atIndex:indexOfListInfoToRemove];
        }
    }
    
    [inserted enumerateObjectsUsingBlock:^(AAPLListInfo * __nonnull listInfoToInsert, NSUInteger idx, BOOL * __nonnull stop) {
        [self.listInfos insertObject:listInfoToInsert atIndex:idx];
        
        if ([self.delegate respondsToSelector:@selector(listsController:didInsertListInfo:atIndex:)]) {
            [self.delegate listsController:self didInsertListInfo:listInfoToInsert atIndex:idx];
        }
    }];

    for (AAPLListInfo *listInfoToUpdate in updated) {
        NSInteger indexOfListInfoToUpdate = [self.listInfos indexOfObject:listInfoToUpdate];
        
        self.listInfos[indexOfListInfoToUpdate] = listInfoToUpdate;
        
        if ([self.delegate respondsToSelector:@selector(listsController:didUpdateListInfo:atIndex:)]) {
            [self.delegate listsController:self didUpdateListInfo:listInfoToUpdate atIndex:indexOfListInfoToUpdate];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(listsControllerDidChangeContent:)]) {
        [self.delegate listsControllerDidChangeContent:self];
    }
}

- (void)session:(nonnull WCSession *)session didReceiveFile:(nonnull WCSessionFile *)file {
    [self copyURLToDocumentsDirectory:file.fileURL];
}

- (void)session:(nonnull WCSession *)session didFinishFileTransfer:(nonnull WCSessionFileTransfer *)fileTransfer error:(nullable NSError *)error {
    if (error) {
        NSLog(@"%s, file: %@, error: %@", __FUNCTION__, fileTransfer.file.fileURL.lastPathComponent, error.localizedDescription);
    }
}

#pragma mark - Convenience

- (void)copyURLToDocumentsDirectory:(NSURL *)url {
    NSURL *documentsURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *toURL = [documentsURL URLByAppendingPathComponent:url.lastPathComponent];
    
    [AAPLListUtilities copyFromURL:url toURL:toURL];
}

#pragma mark - List Differencing

- (NSArray *)removedListInfosToChangedListInfos:(NSArray *)changedListInfos {
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"!(self in %@)", changedListInfos];
    
    return [[self.listInfos copy] filteredArrayUsingPredicate:filterPredicate];
}

- (NSArray *)insertedListInfosToChangedListInfos:(NSArray *)changedListInfos {
    NSPredicate *containmentPredicate = [NSPredicate predicateWithFormat:@"!(self in %@)", [self.listInfos copy]];
    
    return [changedListInfos filteredArrayUsingPredicate:containmentPredicate];
}

- (NSArray *)updatedListInfosToChangedListInfos:(NSArray *)changedListInfos {
    NSArray *initialListInfos = [self.listInfos copy];
    
    NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(AAPLListInfo *changedListInfo, NSDictionary *bindings) {
        NSInteger indexOfChangedListInfoInInitialListInfos = [initialListInfos indexOfObject:changedListInfo];
        
        if (indexOfChangedListInfoInInitialListInfos == NSNotFound) {
            return NO;
        }
        
        AAPLListInfo *initialListInfo = initialListInfos[indexOfChangedListInfoInInitialListInfos];
        
        return initialListInfo.color != changedListInfo.color;
    }];
    
    return [changedListInfos filteredArrayUsingPredicate:filterPredicate];
}

@end

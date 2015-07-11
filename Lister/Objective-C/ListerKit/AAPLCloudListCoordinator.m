/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLCloudListCoordinator class handles querying for and interacting with lists stored as files in iCloud Drive.
*/

#import "AAPLCloudListCoordinator.h"
#import "AAPLListUtilities.h"
#import "AAPLAppConfiguration.h"

@interface AAPLCloudListCoordinator ()

@property (nonatomic, strong) NSMetadataQuery *metadataQuery;
@property (nonatomic, strong) dispatch_queue_t documentsDirectoryQueue;

@property (nonatomic, strong) NSURL *documentsDirectory;

/// Closure executed after the first update provided by the coordinator regarding tracked URLs.
@property (nonatomic, strong) void (^firstQueryUpdateHandler)(void);

@end

@implementation AAPLCloudListCoordinator
@synthesize delegate = _delegate;
@synthesize documentsDirectory = _documentsDirectory;

#pragma mark - Initialization

- (instancetype)initWithPredicate:(NSPredicate *)predicate firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    self = [super init];

    if (self) {
        _firstQueryUpdateHandler = firstQueryUpdateHandler;
        _documentsDirectoryQueue = dispatch_queue_create("com.example.apple-samplecode.lister.cloudlistcoordinator.documentsDirectory", DISPATCH_QUEUE_SERIAL);

        _metadataQuery = [[NSMetadataQuery alloc] init];
        _metadataQuery.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope];
        
        _metadataQuery.predicate = predicate;
        _metadataQuery.operationQueue = [[NSOperationQueue alloc] init];
        _metadataQuery.operationQueue.name = @"com.example.apple-samplecode.lister.cloudlistcoordinator.metadataQuery";

        dispatch_barrier_async(_documentsDirectoryQueue, ^{
            NSURL *cloudContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
            
            _documentsDirectory = [cloudContainerURL URLByAppendingPathComponent:@"Documents"];
        });
        
        // Observe the query.
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self selector:@selector(metadataQueryDidFinishGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:_metadataQuery];
        
        [notificationCenter addObserver:self selector:@selector(metadataQueryDidUpdate:) name:NSMetadataQueryDidUpdateNotification object:_metadataQuery];
    }
    
    return self;
}

- (instancetype)initWithPathExtension:(NSString *)pathExtension firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)", NSMetadataItemURLKey, pathExtension];
    
    self = [self initWithPredicate:predicate firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.lastPathComponent = %@)", NSMetadataItemURLKey, lastPathComponent];
    
    self = [self initWithPredicate:predicate firstQueryUpdateHandler:firstQueryUpdateHandler];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

#pragma mark - Lifetime

- (void)dealloc {
    // Stop observing the query.
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:self.metadataQuery];
    [notificationCenter removeObserver:self name:NSMetadataQueryDidUpdateNotification object:self.metadataQuery];
}

#pragma mark - Property Overrides

- (NSURL *)documentsDirectory {
    __block NSURL *documentsDirectory;

    dispatch_sync(self.documentsDirectoryQueue, ^{
        documentsDirectory = _documentsDirectory;
    });
    
    return documentsDirectory;
}

#pragma mark - AAPLListCoordinator

- (void)startQuery {
    // \c NSMetadataQuery should always be started on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.metadataQuery startQuery];
    });
}

- (void)stopQuery {
    // \c NSMetadataQuery should always be stopped on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.metadataQuery stopQuery];
    });
}

- (void)createURLForList:(AAPLList *)list withName:(NSString *)name {
    NSURL *documentURL = [self documentURLForName:name];
    
    [AAPLListUtilities createList:list atURL:documentURL withCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate listCoordinatorDidFailCreatingListAtURL:documentURL withError:error];
        }
        else {
            [self.delegate listCoordinatorDidUpdateContentsWithInsertedURLs:@[documentURL] removedURLs:@[] updatedURLs:@[]];
        }
    }];
}

- (BOOL)canCreateListWithName:(NSString *)name {
    if (name.length <= 0) {
        return NO;
    }
    
    NSURL *documentURL = [self documentURLForName:name];

    return ![[NSFileManager defaultManager] fileExistsAtPath:documentURL.path];
}

- (void)copyListFromURL:(NSURL *)URL toListWithName:(NSString *)name {
    NSURL *documentURL = [self documentURLForName:name];
    
    [AAPLListUtilities copyFromURL:URL toURL:documentURL];
}

- (void)removeListAtURL:(NSURL *)URL {
    [AAPLListUtilities removeListAtURL:URL withCompletionHandler:^(NSError *error) {
        if (error) {
            [self.delegate listCoordinatorDidFailRemovingListAtURL:URL withError:error];
        }
        else {
            [self.delegate listCoordinatorDidUpdateContentsWithInsertedURLs:@[] removedURLs:@[URL] updatedURLs:@[]];
        }
    }];
}

#pragma mark - NSMetadataQuery Notifications

- (void)metadataQueryDidFinishGathering:(NSNotification *)notification {
    [self.metadataQuery disableUpdates];
    
    NSMutableArray *insertedURLs = [NSMutableArray arrayWithCapacity:self.metadataQuery.results.count];
    for (NSMetadataItem *metadataItem in self.metadataQuery.results) {
        NSURL *insertedURL = [metadataItem valueForAttribute:NSMetadataItemURLKey];
        
        [insertedURLs addObject:insertedURL];
    }
    
    [self.delegate listCoordinatorDidUpdateContentsWithInsertedURLs:insertedURLs removedURLs:@[] updatedURLs:@[]];
    
    [self.metadataQuery enableUpdates];
    
    if (self.firstQueryUpdateHandler) {
        // Execute the `firstQueryUpdateHandler`, it will contain the closure from initialization on first update.
        self.firstQueryUpdateHandler();
        
        // Set `firstQueryUpdateHandler` to an empty closure so that the handler provided is only run on first update.
        self.firstQueryUpdateHandler = nil;
    }
}

- (void)metadataQueryDidUpdate:(NSNotification *)notification {
    [self.metadataQuery disableUpdates];
    
    NSArray *insertedURLs;
    NSArray *removedURLs;
    NSArray *updatedURLs;
    
    NSArray *insertedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateAddedItemsKey];
    if (insertedMetadataItemsOrNil) {
        insertedURLs = [self URLsByMappingMetadataItems:insertedMetadataItemsOrNil];
    }
    
    NSArray *removedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateRemovedItemsKey];
    if (removedMetadataItemsOrNil) {
        removedURLs = [self URLsByMappingMetadataItems:removedMetadataItemsOrNil];
    }
    
    NSArray *updatedMetadataItemsOrNil = notification.userInfo[NSMetadataQueryUpdateChangedItemsKey];
    if (updatedMetadataItemsOrNil) {
        NSIndexSet *indexesOfCompletelyDownloadedUpdatedMetadataItems = [updatedMetadataItemsOrNil indexesOfObjectsPassingTest:^BOOL(NSMetadataItem *updatedMetadataItem, NSUInteger idx, BOOL *stop) {
            NSString *downloadStatus = [updatedMetadataItem valueForAttribute:NSMetadataUbiquitousItemDownloadingStatusKey];
            
            return [downloadStatus isEqualToString:NSMetadataUbiquitousItemDownloadingStatusCurrent];
        }];
        
        NSArray *completelyDownloadedUpdatedMetadataItems = [updatedMetadataItemsOrNil objectsAtIndexes:indexesOfCompletelyDownloadedUpdatedMetadataItems];
        
        updatedURLs = [self URLsByMappingMetadataItems:completelyDownloadedUpdatedMetadataItems];
    }
    
    // Make sure that the arrays are all initialized before calling the didUpdateContents method.
    insertedURLs = insertedURLs ?: @[];
    removedURLs = removedURLs ?: @[];
    updatedURLs = updatedURLs ?: @[];
    
    [self.delegate listCoordinatorDidUpdateContentsWithInsertedURLs:insertedURLs removedURLs:removedURLs updatedURLs:updatedURLs];

    [self.metadataQuery enableUpdates];
}

#pragma mark - Convenience

- (NSURL *)documentURLForName:(NSString *)name {
    NSURL *documentURLWithoutExtension = [self.documentsDirectory URLByAppendingPathComponent:name];
    
    return [documentURLWithoutExtension URLByAppendingPathExtension:AAPLAppConfigurationListerFileExtension];
}

- (NSArray *)URLsByMappingMetadataItems:(NSArray *)metadataItems {
    NSMutableArray *URLs = [NSMutableArray arrayWithCapacity:metadataItems.count];
    
    for (NSMetadataItem *metadataItem in metadataItems) {
        NSURL *URL = [metadataItem valueForAttribute:NSMetadataItemURLKey];
        
        [URLs addObject:URL];
    }
    
    return URLs;
}
@end

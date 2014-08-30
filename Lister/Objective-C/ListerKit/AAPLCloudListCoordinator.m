/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

*/

#import "AAPLCloudListCoordinator.h"
#import "AAPLListUtilities.h"
#import "AAPLAppConfiguration.h"

@interface AAPLCloudListCoordinator ()

@property (nonatomic, strong) NSMetadataQuery *metadataQuery;

@property (nonatomic, strong) dispatch_queue_t documentsDirectoryQueue;

@property (nonatomic, strong) NSURL *documentsDirectory;

@end

@implementation AAPLCloudListCoordinator
@synthesize delegate = _delegate;
@synthesize documentsDirectory = _documentsDirectory;

#pragma mark - Initializers

- (instancetype)initWithPredicate:(NSPredicate *)predicate {
    self = [super init];

    if (self) {
        _documentsDirectoryQueue = dispatch_queue_create("com.example.apple-samplecode.lister.cloudlistcoordinator", 0ul);
        
        _metadataQuery = [[NSMetadataQuery alloc] init];
        _metadataQuery.searchScopes = @[NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope];
        
        _metadataQuery.predicate = predicate;
        
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

- (instancetype)initWithPathExtension:(NSString *)pathExtension {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.pathExtension = %@)", NSMetadataItemURLKey, pathExtension];
    
    self = [self initWithPredicate:predicate];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K.lastPathComponent = %@)", NSMetadataItemURLKey, lastPathComponent];
    
    self = [self initWithPredicate:predicate];
    
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
    [self.metadataQuery startQuery];
}

- (void)stopQuery {
    [self.metadataQuery stopQuery];
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

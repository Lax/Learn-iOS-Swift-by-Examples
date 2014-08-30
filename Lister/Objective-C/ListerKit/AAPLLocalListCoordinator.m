/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

*/

#import "AAPLLocalListCoordinator.h"
#import "AAPLListUtilities.h"
#import "AAPLAppConfiguration.h"

@interface AAPLLocalListCoordinator ()

@property (nonatomic, strong) NSPredicate *predicate;

@end

@implementation AAPLLocalListCoordinator
@synthesize delegate = _delegate;

#pragma mark - Initializers

- (instancetype)initWithPredicate:(NSPredicate *)predicate {
    self = [super init];
    
    if (self) {
        _predicate = predicate;
    }
    
    return self;
}

- (instancetype)initWithPathExtension:(NSString *)pathExtension {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(pathExtension = %@)", pathExtension];
    
    self = [self initWithPredicate:predicate];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(lastPathComponent = %@)", lastPathComponent];

    self = [self initWithPredicate:predicate];
    
    if (self) {
        // No need for additional initialization.
    }
    
    return self;
}

#pragma mark - AAPLListCoordinator

- (void)startQuery {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(defaultQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // Fetch the list documents from container documents directory.
        NSArray *localDocumentURLs = [fileManager contentsOfDirectoryAtURL:[AAPLListUtilities localDocumentsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsPackageDescendants error:nil];
        
        NSArray *localListURLs = [localDocumentURLs filteredArrayUsingPredicate:self.predicate];
        
        if (localListURLs.count > 0) {
            [self.delegate listCoordinatorDidUpdateContentsWithInsertedURLs:localListURLs removedURLs:@[] updatedURLs:@[]];
        }
    });
}

- (void)stopQuery {
    // Nothing to do here since the documents are local and everything gets funnelled this class
    // if the storage is local.
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

#pragma mark - Convenience

- (NSURL *)documentURLForName:(NSString *)name {
    NSURL *documentURLWithoutExtension = [[AAPLListUtilities localDocumentsDirectory] URLByAppendingPathComponent:name];
    
    return [documentURLWithoutExtension URLByAppendingPathExtension:AAPLAppConfigurationListerFileExtension];
}

@end

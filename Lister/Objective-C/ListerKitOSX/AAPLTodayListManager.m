/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  The AAPLTodayListManager class implements convenience methods to create and retrieve the Today list document from the user's ubiquity container.
              
 */

#import "AAPLTodayListManager.h"
#import "AAPLAppConfiguration.h"

@interface AAPLTodayListManager()
@property (readonly) NSURL *todayDocumentFolderURL;
@end

@implementation AAPLTodayListManager

+ (AAPLTodayListManager *)sharedTodayListManager {
    static AAPLTodayListManager *sharedTodayListManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTodayListManager = [[AAPLTodayListManager alloc] init];
    });
    
    return sharedTodayListManager;
}

- (void)fetchTodayDocumentURLWithCompletionHandler:(void (^)(NSURL *url))completionHandler {
    dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(defaultQueue, ^{
        NSURL *url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        
        if (url) {
            NSURL *successURL = [self createTodayDocumentURLWithContainerURL:url];
            
            completionHandler(successURL);
        }
        else {
            completionHandler(nil);
        }
    });
}

- (NSURL *)createTodayDocumentURLWithContainerURL:(NSURL *)containerURL {
    NSURL *todayDocumentFolderURL = [containerURL URLByAppendingPathComponent:@"Documents"];
    
    NSString *localizedTodayDocumentName = [AAPLAppConfiguration sharedAppConfiguration].localizedTodayDocumentName;
    NSURL *todayDocumentURL = [todayDocumentFolderURL URLByAppendingPathComponent:localizedTodayDocumentName];
    todayDocumentURL = [todayDocumentURL URLByAppendingPathExtension:AAPLAppConfigurationListerFileExtension];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:todayDocumentURL.path]) {
        return todayDocumentURL;
    }

    if (![fileManager createDirectoryAtURL:todayDocumentFolderURL withIntermediateDirectories:YES attributes:nil error:nil]) {
        return nil;
    }

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *sampleTodayDocumentURL = [bundle URLForResource:@"Today" withExtension:AAPLAppConfigurationListerFileExtension];
    
    if ([fileManager copyItemAtURL:sampleTodayDocumentURL toURL:todayDocumentURL error:nil]) {
        // Make the file's extension hidden.
        [fileManager setAttributes:@{ NSFileExtensionHidden : @YES } ofItemAtPath:todayDocumentURL.path error:nil];

        return todayDocumentURL;
    }
    
    return nil;
}

@end

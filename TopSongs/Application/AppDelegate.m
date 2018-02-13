/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Configures the Core Data persistence stack and starts the RSS importer.
 */

#import "AppDelegate.h"
#import "SongsViewController.h"
#import "iTunesRSSImporter.h"

@import CoreData;

// String used to identify the update object in the user defaults storage.
static NSString * const kLastStoreUpdateKey = @"LastStoreUpdate";

// Get the RSS feed for the first time or if the store is older than kRefreshTimeInterval seconds.
static NSTimeInterval const kRefreshTimeInterval = 3600;

// The number of songs to be retrieved from the RSS feed.
static NSUInteger const kImportSize = 300;

@interface AppDelegate() <iTunesRSSImporterDelegate>

@property (nonatomic, strong) SongsViewController *songsViewController;

// Properties for the importer and its background processing queue.
@property (nonatomic, strong) iTunesRSSImporter *importer;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

// Properties for the Core Data stack.
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSString *persistentStorePath;

@end


#pragma mark -

@implementation AppDelegate

// The app delegate must implement the window @property
// from UIApplicationDelegate @protocol to use a main storyboard file.
//
@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {

    // check the last update, stored in NSUserDefaults
    NSDate *lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastStoreUpdateKey];
    if (lastUpdate == nil || -lastUpdate.timeIntervalSinceNow > kRefreshTimeInterval) {
        
        // remove the old store; easier than deleting every object
        // first, test for an existing store
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.persistentStorePath]) {
            NSError *error = nil;
            BOOL oldStoreRemovalSuccess = [[NSFileManager defaultManager] removeItemAtPath:self.persistentStorePath error:&error];
            NSAssert3(oldStoreRemovalSuccess, @"Unhandled error adding persistent store in %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
        }
        
        // create an importer object to retrieve, parse, and import into the CoreData store 
        self.importer = [[iTunesRSSImporter alloc] init];
        self.importer.delegate = self;
        // pass the coordinator so the importer can create its own managed object context
        self.importer.persistentStoreCoordinator = self.persistentStoreCoordinator;
        self.importer.iTunesURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wpa/MRSS/newreleases/limit=%ld/rss.xml", (unsigned long)kImportSize]];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        // add the importer to an operation queue for background processing (works on a separate thread)
        [self.operationQueue addOperation:self.importer];
    }

    // obtain our current initial view controller on the nav stack and set it's managed object context
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    _songsViewController = (SongsViewController *)navController.visibleViewController;
    self.songsViewController.managedObjectContext = self.managedObjectContext;
    
    return YES;
}

- (NSOperationQueue *)operationQueue {
    
    if (_operationQueue == nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}


#pragma mark - Core Data stack setup

//
// These methods are very slightly modified from what is provided by the Xcode template
// An overview of what these methods do can be found in the section "The Core Data Stack" 
// in the following article: 
// http://developer.apple.com/iphone/library/documentation/DataManagement/Conceptual/iPhoneCoreData01/Articles/01_StartingOut.html
//
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator == nil) {
        NSURL *storeUrl = [NSURL fileURLWithPath:self.persistentStorePath];
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
        NSError *error = nil;
        NSPersistentStore *persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error];
        NSAssert3(persistentStore != nil, @"Unhandled error adding persistent store in %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    return _managedObjectContext;
}

- (NSString *)persistentStorePath {
    
    if (_persistentStorePath == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths.lastObject;
        _persistentStorePath = [documentsDirectory stringByAppendingPathComponent:@"TopSongs.sqlite"];
    }
    return _persistentStorePath;
}


#pragma mark - iTunesRSSImporterDelegate

// This method will be called on a secondary thread. Forward to the main thread for safe handling of UIKit objects.
- (void)importerDidSave:(NSNotification *)saveNotification {
    
    if ([NSThread isMainThread]) {
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification];
        [self.songsViewController fetch];
    } else {
        [self performSelectorOnMainThread:@selector(importerDidSave:) withObject:saveNotification waitUntilDone:NO];
    }
}

// Helper method for main-thread processing of import completion.
- (void)handleImportCompletion {
    
    // Store the current time as the time of the last import.
    // This will be used to determine whether an import is necessary when the application runs.
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastStoreUpdateKey];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.importer = nil;
}

// This method will be called on a secondary thread. Forward to the main thread for safe handling of UIKit objects.
- (void)importerDidFinishParsingData:(iTunesRSSImporter *)importer {
    
    [self performSelectorOnMainThread:@selector(handleImportCompletion) withObject:nil waitUntilDone:NO];
}

// Helper method for main-thread processing of errors received in the delegate callback below.
- (void)handleImportError:(NSError *)error {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.importer = nil;
    
    // handle errors as appropriate to your application, here we just alert the user
    NSString *errorMessage = error.localizedDescription;
    NSString *alertTitle = NSLocalizedString(@"Error", @"Title for alert displayed when download or parse error occurs.");
    NSString *okTitle = NSLocalizedString(@"OK", @"OK");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
        [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:action];
    
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

// This method will be called on a secondary thread. Forward to the main thread for safe handling of UIKit objects.
- (void)importer:(iTunesRSSImporter *)importer didFailWithError:(NSError *)error {
    
    [self performSelectorOnMainThread:@selector(handleImportError:) withObject:error waitUntilDone:NO];
}

@end


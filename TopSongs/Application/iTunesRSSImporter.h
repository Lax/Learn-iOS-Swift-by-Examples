/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Downloads, parses, and imports the iTunes top songs RSS feed into Core Data.
 */

@import UIKit;

@class iTunesRSSImporter, Song, CategoryCache;

// Protocol for the importer to communicate with its delegate.
@protocol iTunesRSSImporterDelegate <NSObject>

@optional
// Notification posted by NSManagedObjectContext when saved.
- (void)importerDidSave:(NSNotification *)saveNotification;
// Called by the importer when parsing is finished.
- (void)importerDidFinishParsingData:(iTunesRSSImporter *)importer;
// Called by the importer in the case of an error.
- (void)importer:(iTunesRSSImporter *)importer didFailWithError:(NSError *)error;

@end


// Although NSURLConnection is inherently asynchronous, the parsing can be quite CPU intensive on the device, so
// the user interface can be kept responsive by moving that work off the main thread. This does create additional
// complexity, as any code which interacts with the UI must then do so in a thread-safe manner.
//
@interface iTunesRSSImporter : NSOperation

@property (nonatomic, strong, readonly) CategoryCache *theCache;
@property (nonatomic, strong) NSURL *iTunesURL;
@property (nonatomic, assign) id <iTunesRSSImporterDelegate> delegate;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListUtilities class provides a suite of convenience methods for interacting with \c AAPLList objects and their associated files.
*/

@import Foundation;

@class AAPLList;

@interface AAPLListUtilities : NSObject

+ (NSURL *)localDocumentsDirectory;

+ (void)copyInitialLists;

+ (void)copyTodayList;

+ (void)migrateLocalListsToCloud;

+ (void)readListAtURL:(NSURL *)url withCompletionHandler:(void (^)(AAPLList *list, NSError *error))completionHandler;

+ (void)createList:(AAPLList *)list atURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler;

+ (void)removeListAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler;

@end

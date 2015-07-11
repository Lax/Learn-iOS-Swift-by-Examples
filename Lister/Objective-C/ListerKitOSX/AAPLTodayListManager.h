/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLTodayListManager class implements convenience methods to create and retrieve the Today list document from the user's ubiquity container.
*/

@import Foundation;

@interface AAPLTodayListManager : NSObject

+ (AAPLTodayListManager *)sharedTodayListManager;

/*!
    Fetches the ubiquity container URL for the Today list document. If one isn't found, the block is invoked
    with a nil value.
 */
- (void)fetchTodayDocumentURLWithCompletionHandler:(void (^)(NSURL *url))completionHandler;

@end

/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListInfo class is a caching abstraction over an \c AAPLList object that contains information about lists (e.g. color and name).
*/

@import Foundation;
#import "AAPLList.h"

@interface AAPLListInfo : NSObject

- (instancetype)initWithURL:(NSURL *)URL;

@property (nonatomic, strong, readonly) NSURL *URL;

@property (nonatomic, copy, readonly) NSString *name;

@property AAPLListColor color;

- (void)fetchInfoWithCompletionHandler:(void (^)(void))completionHandler;

@end

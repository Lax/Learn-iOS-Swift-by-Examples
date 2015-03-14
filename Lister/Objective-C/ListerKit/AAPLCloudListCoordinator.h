/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLCloudListCoordinator class handles querying for and interacting with lists stored as files in iCloud Drive.
*/

@import Foundation;
#import "AAPLListCoordinator.h"

@interface AAPLCloudListCoordinator : NSObject <AAPLListCoordinator>

- (instancetype)initWithPathExtension:(NSString *)pathExtension firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

@end

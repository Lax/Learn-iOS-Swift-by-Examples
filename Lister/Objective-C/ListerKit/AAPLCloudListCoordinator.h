/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLCloudListCoordinator class handles querying for and interacting with lists stored as files in iCloud Drive.
*/

@import Foundation;
#import "AAPLListCoordinator.h"

/*!
    An object that conforms to the \c AAPLListCoordinator protocol and is responsible for implementing
    entry points in order to communicate with an \c AAPLListCoordinatorDelegate. In the case of Lister,
    this is the \c AAPLListsController instance. The main responsibility of a \c AAPLListCoordinator is
    to track different \c NSURL instances that are important. The iCloud coordinator is responsible for
    making sure that the \c AAPLListsController knows about the current set of iCloud documents that are
    available.

    There are also other responsibilities that an \c AAPLListCoordinator must have that are specific
    to the underlying storage mechanism of the coordinator. An \c AAPLListCoordinator determines whether
    or not a new list can be created with a specific name, it removes URLs tied to a specific list, and
    it is also responsible for listening for updates to any changes that occur at a specific URL
    (e.g. a list document is updated on another device, etc.).

    Instances of \c AAPLListCoordinator can search for URLs in an asynchronous way. When a new \c NSURL
    instance is found, removed, or updated, the \c AAPLListCoordinator instance must make its delegate
    aware of the updates. If a failure occured in removing or creating an \c NSURL for a given list,
    it must make its delegate aware by calling one of the appropriate error methods defined in the
    \c AAPLListCoordinatorDelegate protocol.
 */
@interface AAPLCloudListCoordinator : NSObject <AAPLListCoordinator>

/*!
    Initializes an \c AAPLCloudListCoordinator based on a path extension used to identify files that can be 
    managed by the app. Also provides a block parameter that can be used to provide actions to be executed
    when the coordinator returns its first set of documents. This coordinator monitors the app's iCloud Drive
    container.

    @param pathExtension The extension that should be used to identify documents of interest to this coordinator.
    @param firstQueryUpdateHandler The handler that is executed once the first results are returned.
 */
- (instancetype)initWithPathExtension:(NSString *)pathExtension firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

/*!
    Initializes an \c AAPLCloudListCoordinator based on a single document used to identify a file that should
    be monitored. Also provides a block parameter that can be used to provide actions to be executed when the 
    coordinator returns its initial result. This coordinator monitors the app's iCloud Drive container.

    @param lastPathComponent The file name that should be monitored by this coordinator.
    @param firstQueryUpdateHandler The handler that is executed once the first results are returned.
 */
- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent firstQueryUpdateHandler:(void (^)(void))firstQueryUpdateHandler;

@end

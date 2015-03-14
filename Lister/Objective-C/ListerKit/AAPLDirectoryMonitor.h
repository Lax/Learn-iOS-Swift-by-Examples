/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    \c AAPLDirectoryMonitor is used to monitor the contents of the provided directory by using a GCD dispatch source.
*/

@import Foundation;

@class AAPLDirectoryMonitor;

/// A protocol that allows delegates of \c AAPLDirectoryMonitor to respond to changes in a directory.
@protocol AAPLDirectoryMonitorDelegate <NSObject>

- (void)directoryMonitorDidObserveChange:(AAPLDirectoryMonitor *)directoryMonitor;

@end

@interface AAPLDirectoryMonitor: NSObject

/// The AAPLDirectoryMonitor's delegate who is responsible for responding to AAPLDirectoryMonitor updates.
@property (nonatomic, weak) id<AAPLDirectoryMonitorDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)URL;

- (void)startMonitoring;
- (void)stopMonitoring;

@end

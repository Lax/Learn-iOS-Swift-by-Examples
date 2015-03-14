/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    \c AAPLDirectoryMonitor is used to monitor the contents of the provided directory by using a GCD dispatch source.
*/

#import "AAPLDirectoryMonitor.h"

@interface AAPLDirectoryMonitor ()

/// A file descriptor for the monitored directory.
@property (nonatomic) int monitoredDirectoryFileDescriptor;

/// A dispatch queue used for sending file changes in the directory.
@property (nonatomic, strong) dispatch_queue_t directoryMonitorQueue;

/// A dispatch source to monitor a file descriptor created from the directory.
@property (nonatomic, strong) dispatch_source_t directoryMonitorSource;

/// URL for the directory being monitored.
@property (nonatomic, strong) NSURL *URL;

@end

@implementation AAPLDirectoryMonitor
#pragma mark - Initializers

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];

    if (self) {
        _URL = URL;
        
        _monitoredDirectoryFileDescriptor = -1;
    }

    return self;
}

#pragma mark - Monitoring

- (void)startMonitoring {
    // Listen for changes to the directory (if we are not already).
    if (self.directoryMonitorSource == nil && self.monitoredDirectoryFileDescriptor == -1) {
        // Open the directory referenced by URL for monitoring only.
        self.monitoredDirectoryFileDescriptor = open([self.URL.path cStringUsingEncoding:NSUTF8StringEncoding], O_EVTONLY);
        
        // Create the monitor queue for handling monitoring events.
        self.directoryMonitorQueue = dispatch_queue_create("com.example.apple-samplecode.lister.directorymonitor", DISPATCH_QUEUE_CONCURRENT);
        
        // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
        self.directoryMonitorSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, self.monitoredDirectoryFileDescriptor, DISPATCH_VNODE_WRITE, self.directoryMonitorQueue);
        
        // Define the block to call when a file change is detected.
        dispatch_source_set_event_handler(self.directoryMonitorSource, ^{
            // Call out to the `AAPLDirectoryMonitorDelegate` so that it can react appropriately to the change.
            [self.delegate directoryMonitorDidObserveChange:self];
        });
        
        // Define a cancel handler to ensure the directory is closed when the source is cancelled.
        dispatch_source_set_cancel_handler(self.directoryMonitorSource, ^{
            close(self.monitoredDirectoryFileDescriptor);
            
            self.monitoredDirectoryFileDescriptor = -1;
            
            self.directoryMonitorSource = nil;
        });
        
        // Start monitoring the directory via the source.
        dispatch_resume(self.directoryMonitorSource);
    }
}

- (void)stopMonitoring {
    // Stop listening for changes to the directory, if the source has been created.
    if (self.directoryMonitorSource != nil) {
        // Stop monitoring the directory via the source.
        dispatch_source_cancel(self.directoryMonitorSource);
    }
}

@end

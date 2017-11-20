/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Resolves an IP address to a list of DNS names.
 */

#import "QHostNameQuery.h"

NS_ASSUME_NONNULL_BEGIN

@interface QHostNameQuery ()

/// The underlying CFHost object that does the resolution.

@property (nonatomic, strong, readwrite, nullable) CFHostRef host __attribute__ (( NSObject ));

/// The run loop on which the CFHost object is scheduled; this is set in `start()` 
/// and cleared when the query stops (either via `cancel()` or by completing).

@property (nonatomic, strong, readwrite, nullable) NSRunLoop * targetRunLoop;

@end

NS_ASSUME_NONNULL_END

@implementation QHostNameQuery

- (instancetype)initWithAddress:(NSData *)address {
    NSParameterAssert(address != nil);
    self = [super init];
    if (self != nil) {
        self->_address = [address copy];
        self->_host = CFHostCreateWithAddress(NULL, (__bridge CFDataRef) self->_address);
    }
    return self;
}

- (instancetype)init {
    abort();
}

- (void)start {
    NSParameterAssert(self.targetRunLoop == nil);
    self.targetRunLoop = NSRunLoop.currentRunLoop;
    
    CFHostClientContext context = {
        .info = (void *) CFBridgingRetain(self)
    };
    BOOL success = CFHostSetClient(self.host, HostClientCallBack, &context) != false;
    assert(success);
    CFHostScheduleWithRunLoop(self.host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
    CFStreamError streamError;
    success = CFHostStartInfoResolution(self.host, kCFHostNames, &streamError) != false;
    if ( ! success ) {
        [self stopWithStreamError:&streamError notify:NO];
    }
}

/// Our CFHost callback function for our host; this just extracts the object from the `info` 
/// pointer and calls methods on it.

static void HostClientCallBack(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError * __nullable error, void * __nullable info) {
    #pragma unused(theHost)
    #pragma unused(typeInfo)

    QHostNameQuery * obj = (__bridge QHostNameQuery *) info;
    assert([obj isKindOfClass:[QHostNameQuery class]]);
    
    if ( (error == NULL) || ( (error->domain == 0) && (error->error == 0) ) ) {
        [obj stopWithStreamError:NULL notify:YES];
    } else {
        [obj stopWithStreamError:error notify:YES];
    }
}

/// Stops the query with the supplied error, notifying the delegate if `notify` is true.

- (void)stopWithStreamError:(nullable const CFStreamError *)streamError notify:(BOOL)notify {
    NSError * error = nil;
    
    if (streamError != NULL) {
        // Convert a CFStreamError to a NSError.  This is less than ideal.  I only handle a 
        // limited number of error domains, and I can't use a switch statement because 
        // some of the `kCFStreamErrorDomainXxx` values are not a constant.  Wouldn't it be 
        // nice if there was a public API to do this mapping <rdar://problem/5845848> 
        // or a CFHost API that used CFError <rdar://problem/6016542>.
        if (streamError->domain == kCFStreamErrorDomainPOSIX) {
            error = [NSError errorWithDomain:NSPOSIXErrorDomain code:streamError->error userInfo:nil];
        } else if (streamError->domain == kCFStreamErrorDomainMacOSStatus) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:streamError->error userInfo:nil];
        } else if (streamError->domain == kCFStreamErrorDomainNetServices) {
            error = [NSError errorWithDomain:(__bridge NSString *) kCFErrorDomainCFNetwork code:streamError->error userInfo:nil];
        } else if (streamError->domain == kCFStreamErrorDomainNetDB) {
            error = [NSError errorWithDomain:(__bridge NSString *) kCFErrorDomainCFNetwork code:kCFHostErrorUnknown userInfo:@{
                (__bridge NSString *) kCFGetAddrInfoFailureKey: @(streamError->error)
            }];
        } else {
            // If it's something we don't understand, we just assume it comes from 
            // CFNetwork.
            error = [NSError errorWithDomain:(__bridge NSString *) kCFErrorDomainCFNetwork code:streamError->error userInfo:nil];
        }
    }
    
    [self stopWithError:error notify:notify];
}

/// Stops the query with the supplied error, notifying the delegate if `notify` is true.

- (void)stopWithError:(nullable NSError *)error notify:(BOOL)notify {
    NSParameterAssert(NSRunLoop.currentRunLoop == self.targetRunLoop);
    self.targetRunLoop = nil;
    
    CFHostSetClient(self.host, nil, nil);
    CFHostUnscheduleFromRunLoop(self.host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFHostCancelInfoResolution(self.host, kCFHostAddresses);
    CFRelease( (__bridge CFTypeRef) self );
    
    id<QHostNameQueryDelegate> strongDelegate = self.delegate;
    if (notify && (strongDelegate != nil) ) {
        if (error != nil) {
            [strongDelegate hostNameQuery:self didCompleteWithError:error];
        } else {
            NSArray<NSString *> * names = (__bridge NSArray<NSString *> *) CFHostGetNames(self.host, NULL);
            [strongDelegate hostNameQuery:self didCompleteWithNames:names];
        }
    }
}

- (void)cancel {
    if (self.targetRunLoop != nil) {
        [self stopWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil] notify:NO];
    }
}

@end

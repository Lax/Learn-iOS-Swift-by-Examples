/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Resolves an IP address to a list of DNS names.
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol QHostNameQueryDelegate;

/// This class uses CFHost to query an IP address for its DNS names.  To do this:
///
/// 1. Create the `QHostNameQuery` object with the name in question.
///
/// 2. Set a delegate.
///
/// 3. Call `start()`.
///
/// 4. Wait for `-hostNameQuery:didCompleteWithNames:` or `-hostNameQuery:didCompleteWithError:` 
///    to be called.
///
/// CFHost, and hence this class, is run loop based.  The class remembers the run loop on which you 
/// call `start()` and delivers the delegate callbacks on that run loop.
///
/// - Important: Reverse DNS queries are notoriously unreliable.  Specifically, you must not 
///   assume that:
///
///   - Every IP address has a valid reverse DNS name
///   - The reverse DNS name is unique
///   - There's any correlation between the forward and reverse DNS mappings
///   
///   Unless you have domain specific knowledge (for example, you're working in an enterprise 
///   environment where you know how the DNS is set up), reverse DNS queries are generally not 
///   useful for anything other than logging.

@interface QHostNameQuery : NSObject

/// Creates an instance to query the specified IP address for its DNS name.
///
/// - Parameter address: The IP address to query, as a `NSData` value containing some flavour of `sockaddr`.

- (instancetype)initWithAddress:(NSData *)address NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// The IP address to query, as a `NSData` value containing some flavour of `sockaddr`. 

@property (nonatomic, copy, readonly) NSData * address;

/// You must set this to learn about the results of your query.

@property (nonatomic, weak, readwrite) id<QHostNameQueryDelegate> delegate;

/// Starts the query process.
///
/// The query remembers the thread that called this method and calls any delegate 
/// callbacks on that thread.
///
/// - Important: For the query to make progress, this thread must run its run loop in 
///   the default run loop mode.
/// 
/// - Warning: It is an error to start a query that's running.

- (void)start;

/// Cancels a running query.
///
/// If you successfully cancel a query, no delegate callback for that query will be 
/// called.
/// 
/// If the query is running, you must call this from the thread that called `start()`.
/// 
/// - Note: It is acceptable to call this on a query that's not running; it does nothing 
//    in that case.

- (void)cancel;

@end

/// The delegate protocol for the HostNameQuery class.

@protocol QHostNameQueryDelegate <NSObject>

@required

/// Called when the query completes successfully.
///
/// This is called on the same thread that called `start()`.
///
/// - Parameters:
///   - names: The DNS names for the IP address.
///   - query: The query that completed.

- (void)hostNameQuery:(QHostNameQuery *)query didCompleteWithNames:(NSArray<NSString *> *)names;

/// Called when the query completes with an error.
///
/// This is called on the same thread that called `start()`.
///
/// - Parameters:
///   - error: An error describing the failure.
///   - query: The query that completed.
///
/// - Important: In most cases the error will be in domain `kCFErrorDomainCFNetwork` 
///   with a code of `kCFHostErrorUnknown` (aka `CFNetworkErrors.cfHostErrorUnknown`), 
///   and the user info dictionary will contain an element with the `kCFGetAddrInfoFailureKey` 
///   key whose value is an NSNumber containing an `EAI_XXX` value (from `<netdb.h>`).

- (void)hostNameQuery:(QHostNameQuery *)query didCompleteWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END

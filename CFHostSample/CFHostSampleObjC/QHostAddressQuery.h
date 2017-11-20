/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Resolves a DNS name to a list of IP addresses.
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol QHostAddressQueryDelegate;

/// This class uses CFHost to query a DNS name for its addresses.  To do this:
///
/// 1. Create the `QHostAddressQuery` object with the name in question.
///
/// 2. Set a delegate.
///
/// 3. Call `start()`.
///
/// 4. Wait for `-hostAddressQuery:didCompleteWithAddresses:` or `-hostAddressQuery:didCompleteWithError:` 
///    to be called.
///
/// CFHost, and hence this class, is run loop based.  The class remembers the run loop on which you 
/// call `start()` and delivers the delegate callbacks on that run loop.

@interface QHostAddressQuery : NSObject

/// Creates an instance to query the specified DNS name for its addresses.
///
/// - Parameter name: The DNS name to query.

- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// The DNS name to query.

@property (nonatomic, copy, readonly) NSString * name;

/// You must set this to learn about the results of your query.

@property (nonatomic, weak, readwrite) id<QHostAddressQueryDelegate> delegate;

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

/// The delegate protocol for the HostAddressQuery class.

@protocol QHostAddressQueryDelegate <NSObject>

@required

/// Called when the query completes successfully.
///
/// This is called on the same thread that called `start()`.
///
/// - Parameters:
///   - addresses: The addresses for the DNS name.  This has some important properties:
///     - It will not be empty.
///     - Each element is an `NSData` value that contains some flavour of `sockaddr`
///     - It can contain any combination of IPv4 and IPv6 addresses
///     - The addresses are sorted, with the most preferred first
///   - query: The query that completed.

- (void)hostAddressQuery:(QHostAddressQuery *)query didCompleteWithAddresses:(NSArray<NSData *> *)addresses;

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

- (void)hostAddressQuery:(QHostAddressQuery *)query didCompleteWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END

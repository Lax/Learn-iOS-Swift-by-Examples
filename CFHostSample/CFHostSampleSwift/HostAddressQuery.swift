/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Resolves a DNS name to a list of IP addresses.
 */

import Foundation

/// This class uses CFHost to query a DNS name for its addresses.  To do this:
///
/// 1. Create the `HostAddressQuery` object with the name in question.
///
/// 2. Set a delegate.
///
/// 3. Call `start()`.
///
/// 4. Wait for `didComplete(addresses:hostAddressQuery:)` or `didComplete(error:hostAddressQuery:)` 
///    to be called.
///
/// CFHost, and hence this class, is run loop based.  The class remembers the run loop on which you 
/// call `start()` and delivers the delegate callbacks on that run loop.

final class HostAddressQuery {
    
    /// Creates an instance to query the specified DNS name for its addresses.
    ///
    /// - Parameter name: The DNS name to query.
    
    init(name: String) {
        self.name = name
        self.host = CFHostCreateWithName(nil, name as NSString).takeRetainedValue()
    }
    
    /// The DNS name to query.
    
    let name: String
    
    /// You must set this to learn about the results of your query.
    
    weak var delegate: HostAddressQueryDelegate? = nil
    
    /// Starts the query process.
    ///
    /// The query remembers the thread that called this method and calls any delegate 
    /// callbacks on that thread.
    ///
    /// - Important: For the query to make progress, this thread must run its run loop in 
    ///   the default run loop mode.
    /// 
    /// - Warning: It is an error to start a query that's running.
    
    func start() {
        precondition(self.targetRunLoop == nil)
        self.targetRunLoop = RunLoop.current
        
        var context = CFHostClientContext()
        context.info = Unmanaged.passRetained(self).toOpaque()
        var success = CFHostSetClient(self.host, { (_ host: CFHost, _: CFHostInfoType, _ streamErrorPtr: UnsafePointer<CFStreamError>?, _ info: UnsafeMutableRawPointer?) in 
            let obj = Unmanaged<HostAddressQuery>.fromOpaque(info!).takeUnretainedValue()
            if let streamError = streamErrorPtr?.pointee, (streamError.domain != 0 || streamError.error != 0) {
                obj.stop(streamError: streamError, notify: true)
            } else {
                obj.stop(streamError: nil, notify: true)
            }
        }, &context)
        assert(success)
        CFHostScheduleWithRunLoop(self.host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        var streamError = CFStreamError()
        success = CFHostStartInfoResolution(self.host, .addresses, &streamError)
        if !success {
            self.stop(streamError: streamError, notify: true)
        }
    }
    
    /// Stops the query with the supplied error, notifying the delegate if `notify` is true.

    private func stop(streamError: CFStreamError?, notify: Bool) {
        let error: Error?
        if let streamError = streamError {
            // Convert a CFStreamError to a NSError.  This is less than ideal because I only handle 
            // a limited number of error domains.  Wouldn't it be nice if there was a public API to 
            // do this mapping <rdar://problem/5845848> or a CFHost API that used CFError 
            // <rdar://problem/6016542>.
            switch streamError.domain {
                case CFStreamErrorDomain.POSIX.rawValue:
                    error = NSError(domain: NSPOSIXErrorDomain, code: Int(streamError.error))
                case CFStreamErrorDomain.macOSStatus.rawValue:
                    error = NSError(domain: NSOSStatusErrorDomain, code: Int(streamError.error))
                case Int(kCFStreamErrorDomainNetServices):
                    error = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(streamError.error))
                case Int(kCFStreamErrorDomainNetDB):
                    error = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue), userInfo: [
                        kCFGetAddrInfoFailureKey as String: streamError.error as NSNumber
                    ])
                default:
                    // If it's something we don't understand, we just assume it comes from 
                    // CFNetwork.
                    error = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(streamError.error))
            }
        } else {
            error = nil
        }
        self.stop(error: error, notify: notify)
    }

    /// Stops the query with the supplied error, notifying the delegate if `notify` is true.

    private func stop(error: Error?, notify: Bool) {
        precondition(RunLoop.current == self.targetRunLoop)
        self.targetRunLoop = nil
        
        CFHostSetClient(self.host, nil, nil)
        CFHostUnscheduleFromRunLoop(self.host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        CFHostCancelInfoResolution(self.host, .addresses)
        Unmanaged.passUnretained(self).release()
        
        if notify {
            if let error = error {
                self.delegate?.didComplete(error: error, hostAddressQuery: self)
            } else {
                let addresses = CFHostGetAddressing(self.host, nil)!.takeUnretainedValue() as NSArray as! [Data]
                self.delegate?.didComplete(addresses: addresses, hostAddressQuery: self)
            }
        }
    }
    
    /// Cancels a running query.
    ///
    /// If you successfully cancel a query, no delegate callback for that query will be 
    /// called.
    /// 
    /// If the query is running, you must call this from the thread that called `start()`.
    /// 
    /// - Note: It is acceptable to call this on a query that's not running; it does nothing 
    //    in that case.
    
    func cancel() {
        if self.targetRunLoop != nil {
            self.stop(error: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil), notify: false)
        }
    }
    
    /// The underlying CFHost object that does the resolution.
    
    private var host: CFHost
    
    /// The run loop on which the CFHost object is scheduled; this is set in `start()` 
    /// and cleared when the query stops (either via `cancel()` or by completing).
    
    private var targetRunLoop: RunLoop? = nil
}


/// The delegate protocol for the HostAddressQuery class.

protocol HostAddressQueryDelegate: class {

    /// Called when the query completes successfully.
    ///
    /// This is called on the same thread that called `start()`.
    ///
    /// - Parameters:
    ///   - addresses: The addresses for the DNS name.  This has some important properties:
    ///     - It will not be empty.
    ///     - Each element is a `Data` value that contains some flavour of `sockaddr`
    ///     - It can contain any combination of IPv4 and IPv6 addresses
    ///     - The addresses are sorted, with the most preferred first
    ///   - query: The query that completed.

    func didComplete(addresses: [Data], hostAddressQuery query: HostAddressQuery)

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
    
    func didComplete(error: Error, hostAddressQuery query: HostAddressQuery)
}

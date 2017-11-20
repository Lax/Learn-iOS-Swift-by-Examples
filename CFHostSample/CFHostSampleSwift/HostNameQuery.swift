/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Resolves an IP address to a list of DNS names.
 */

import Foundation

/// This class uses CFHost to query an IP address for its DNS names.  To do this:
///
/// 1. Create the `HostNameQuery` object with the IP address in question.
///
/// 2. Set a delegate.
///
/// 3. Call `start()`.
///
/// 4. Wait for `didComplete(names:hostNameQuery:)` or `didComplete(error:hostNameQuery:)` 
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

final class HostNameQuery {
    
    /// Creates an instance to query the specified IP address for its DNS name.
    ///
    /// - Parameter address: The IP address to query, as a `Data` value containing some flavour of `sockaddr`.

    init(address: Data) {
        self.address = address
        self.host = CFHostCreateWithAddress(nil, address as NSData).takeRetainedValue()
    }
    
    /// The IP address to query, as a `Data` value containing some flavour of `sockaddr`. 

    let address: Data

    /// You must set this to learn about the results of your query.
    
    weak var delegate: HostNameQueryDelegate? = nil
    
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
            let obj = Unmanaged<HostNameQuery>.fromOpaque(info!).takeUnretainedValue()
            if let streamError = streamErrorPtr?.pointee, (streamError.domain != 0 || streamError.error != 0) {
                obj.stop(streamError: streamError, notify: true)
            } else {
                obj.stop(streamError: nil, notify: true)
            }
        }, &context)
        assert(success)
        CFHostScheduleWithRunLoop(self.host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        
        var streamError = CFStreamError()
        success = CFHostStartInfoResolution(self.host, .names, &streamError)
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
        CFHostCancelInfoResolution(self.host, .names)
        Unmanaged.passUnretained(self).release()
        
        if notify {
            if let error = error {
                self.delegate?.didComplete(error: error, hostNameQuery: self)
            } else {
                let names = CFHostGetNames(self.host, nil)!.takeUnretainedValue() as NSArray as! [String]
                self.delegate?.didComplete(names: names, hostNameQuery: self)
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

/// The delegate protocol for the HostNameQuery class.

protocol HostNameQueryDelegate: class {

    /// Called when the query completes successfully.
    ///
    /// This is called on the same thread that called `start()`.
    ///
    /// - Parameters:
    ///   - names: The DNS names for the IP address.
    ///   - query: The query that completed.

    func didComplete(names: [String], hostNameQuery query: HostNameQuery)

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

    func didComplete(error: Error, hostNameQuery query: HostNameQuery)
}

/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Command line tool main.
 */

import Foundation

// MARK: - main object

/// The main object, which is instantiated and run by the main function.
///
/// We have to use an object here because the underlying `HostAddressQuery` 
/// and `HostNameQuery` classes need a delegate.

class MainObj: HostAddressQueryDelegate, HostNameQueryDelegate {

    /// The name-to-address queries to run.
    
    var addressQueries: [HostAddressQuery] = []

    /// The address-to-name queries to run.

    var nameQueries: [HostNameQuery] = []
    
    /// The total number of queries to run.
    
    var queryCount: Int { return self.addressQueries.count + self.nameQueries.count }
    
    /// The number of queries that have finished.
    
    var finishedQueryCount = 0

    /// Runs the queries, not returning until they're all finished.
    
    func run() {
        self.addressQueries.forEach( {
            $0.delegate = self
            $0.start()
        } )

        self.nameQueries.forEach( { 
            $0.delegate = self 
            $0.start() 
        } )

        while self.finishedQueryCount != self.queryCount {
            RunLoop.current.run(mode: .defaultRunLoopMode, before: .distantFuture)
        }
    }

    func didComplete(addresses: [Data], hostAddressQuery query: HostAddressQuery) {
        let addressList = addresses.map { numeric(for: $0) }.joined(separator: ", ")
        print("\(query.name) -> \(addressList)", to: &Process.stdout)
        self.finishedQueryCount += 1
    }

    func didComplete(error: Error, hostAddressQuery query: HostAddressQuery) {
        print("\(query.name) -> \(string(for: error))", to: &Process.stdout)
        self.finishedQueryCount += 1
    }
    
    func didComplete(names: [String], hostNameQuery query: HostNameQuery) {
        let addressString = numeric(for: query.address)
        let nameList = names.joined(separator: ",")
        print("\(addressString) -> \(nameList)", to: &Process.stdout)
        self.finishedQueryCount += 1
    }

    func didComplete(error: Error, hostNameQuery query: HostNameQuery) {
        let addressString = numeric(for: query.address)
        print("\(addressString) -> \(string(for: error))", to: &Process.stdout)
        self.finishedQueryCount += 1
    }
}

// MARK: - utilities

/// Returns a string for the supplied error, formatted to make sense as command line output.
///
/// - Parameter error: The error to format.
/// - Returns: A string for that error, formatted to make sense as command line output.

func string(for error: Error) -> String {
    let error = error as NSError
    if error.domain == kCFErrorDomainCFNetwork as String {
        if let code = (error.userInfo[kCFGetAddrInfoFailureKey as String] as? NSNumber)?.int32Value {
            // We deliberately don't call `gai_strerror` here because this is a developer- 
            // oriented tool and we want to show the symbolic name of the error.
            switch code {
                case EAI_ADDRFAMILY: return "EAI_ADDRFAMILY"
                case EAI_AGAIN:      return "EAI_AGAIN"
                case EAI_BADFLAGS:   return "EAI_BADFLAGS"
                case EAI_FAIL:       return "EAI_FAIL"
                case EAI_FAMILY:     return "EAI_FAMILY"
                case EAI_MEMORY:     return "EAI_MEMORY"
                case EAI_NODATA:     return "EAI_NODATA"
                case EAI_NONAME:     return "EAI_NONAME"
                case EAI_SERVICE:    return "EAI_SERVICE"
                case EAI_SOCKTYPE:   return "EAI_SOCKTYPE"
                case EAI_SYSTEM:     return "EAI_SYSTEM"
                case EAI_BADHINTS:   return "EAI_BADHINTS"
                case EAI_PROTOCOL:   return "EAI_PROTOCOL"
                case EAI_OVERFLOW:   return "EAI_OVERFLOW"
                default:
                    break
            }
        }
    }
    return error.description
}

/// Converts an IP address to its string equivalent.
///
/// This does not hit the network and thus won't fail.
/// 
/// - Parameter address: An IP address, as a `Data` value containing some flavour of `sockaddr`.
/// - Returns: The string equivalent of that IP address.

func numeric(for address: Data) -> String {
    var name = [CChar](repeating: 0, count: Int(NI_MAXHOST))
    let saLen = socklen_t(address.count)
    let success = address.withUnsafeBytes { (sa: UnsafePointer<sockaddr>) in
        return getnameinfo(sa, saLen, &name, socklen_t(name.count), nil, 0, NI_NUMERICHOST | NI_NUMERICSERV) == 0
    }
    guard success else {
        return "?"
    }
    return String(cString: name)
}

/// Converts an IP address string to an IP address.
///
/// This does not hit the network but can fail if the string is not a valid IP address.
/// 
/// - Parameter numeric: An IP address string.
/// - Returns: An IP address, as a `Data` value containing some flavour of `sockaddr`, or nil.

func data(for numeric: String) -> Data? {
    var hints = addrinfo()
    hints.ai_flags = AI_NUMERICHOST | AI_NUMERICSERV
    var addrList: UnsafeMutablePointer<addrinfo>? = nil
    let success = getaddrinfo(numeric, nil, &hints, &addrList) == 0
    guard success else {
        return nil
    }
    defer { freeaddrinfo(addrList) }
    let cursor = addrList!.pointee
    return Data(bytes: cursor.ai_addr, count: Int(cursor.ai_addrlen))
}

extension Process {

    /// The Swift equivalent of `getprogname`.
    
    static var progName: String {
        return String(CommandLine.arguments[0].characters.split(separator: "/").last!)
    }
    
    /// An implementation of the `TextOutputStream` protocol that prints to a C `FILE`.
    
    struct CFileOutputStream : TextOutputStream {
        let file: UnsafeMutablePointer<FILE>
        mutating func write(_ string: String) {
            string.withCString { cStr in
                _ = fputs(cStr, self.file)
            }
        }
    }
    
    /// The Swift equivalent of `stdout`.

    static var stdout = CFileOutputStream(file: Darwin.stdout)

    /// The Swift equivalent of `stderr`.

    static var stderr = CFileOutputStream(file: Darwin.stderr)
}

// MARK: - main function

/// The main function, called below.
///
/// I created this just to encapsulate the code that is a little complex.

func main() {

    func usage() -> Never {
        print("usage: \(Process.progName) -h apple.com", to: &Process.stderr)
        print("       \(Process.progName) -a 17.172.224.47", to: &Process.stderr)
        exit(EXIT_FAILURE)
    }

    // Parse any options.
    
    let m = MainObj()
    var opt: Int32
    repeat {
        opt = getopt(CommandLine.argc, CommandLine.unsafeArgv, "h:a:")
        switch opt {
            case -1:
                break
            case Int32(UInt8(ascii: "h")):
                let name = String(cString: optarg)
                guard !name.isEmpty else {
                    usage()
                }
                m.addressQueries.append( HostAddressQuery(name: name) )
            case Int32(UInt8(ascii: "a")):
                guard let address = data(for: String(cString: optarg)) else {
                    usage()
                }
                m.nameQueries.append( HostNameQuery(address: address) )
            default:
                usage()
        }
    } while opt != -1

    // Check for inconsistencies and then run.

    guard m.queryCount != 0 else {
        usage()                                     // nothing to do
    }
    guard optind == CommandLine.argc else {
        usage()                                     // extra stuff an the command line
    }
    m.run()
}

main()

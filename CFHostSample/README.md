# CFHostSample

3.0

CFHostSample shows how to use the CFHost API to do asynchronous DNS name-to-address and address-to-name queries.


## Before You Start

CFHost is only necessary if you have specialist DNS needs, for example, if you want to map all of the addresses in a log file to their host names.  If you just want to connect to a DNS name, it’s both easier and better to use a connect-by-name API, that is, an API that takes a DNS name and does the resolution on your behalf.  Most notably, to create an outgoing TCP connection to a server, use `+[NSStream getStreamsToHostWithName:port:inputStream:outputStream:]` or, if you need to support older platforms, the compatibility shim contained in QA1652 [Using NSStreams For A TCP Connection Without NSHost][qa1652].

[qa1652]: <https://developer.apple.com/library/ios/#qa/qa1652/_index.html>



## Requirements

### Build

Xcode 8.2

The sample was built using Xcode 8.2 on macOS 10.12.3 with the macOS 10.12 SDK.  You should be able to just open the project, select the appropriate scheme (Objective-C or Swift), and choose *Product* > *Build*.


### Runtime

OS X 10.11

While the sample itself requires 10.11 or later, the core code should work on older versions of macOS, at least as far back as 10.7.  Additionally, that same core code will work unmodified on recent versions of iOS.


## Packing List

The sample contains the following items:

* `README.md` — This file.

* `LICENSE.txt` — The sample code license.

* `CFHostSample.xcodeproj` — An Xcode project for the program.

* `CFHostSampleObjC` — A directory containing an Objective-C version of the code.

* `CFHostSampleSwift` — A directory containing a Swift version of the code.

Within these two directories you’ll find:

- `main.{m,swift}` — The command line tool main.

- `QHostAddressQuery.{h,m}` / `HostAddressQuery.swift` — Resolves a DNS name to a list of IP addresses.

- `QHostNameQuery.{h,m}` / `HostNameQuery.swift` — Resolves an IP address to a list of DNS names.


## Using the Sample

The sample supports two functions.  To test name-to-address queries, run the tool with the `-h` option:

    $ build/Debug/CFHostSampleSwift -h apple.com
    apple.com -> 17.142.160.59, 17.172.224.47, 17.178.96.59

To test address-to-name queries, run the tool with the `-a` option:

    $ build/Debug/CFHostSampleSwift -a 17.172.224.47
    17.172.224.47 -> apple.com

The sample has full support for IPv6.  The easiest way to see this in action is to use a local DNS name.  For example, if you have a machine on your local network called *Biff*, you can do this:

    $ build/Debug/CFHostSampleSwift -h biff.local.
    biff.local. -> fe80::c06:6593:cfc3:5504%en0, 192.168.1.189
    $ build/Debug/CFHostSampleSwift -a fe80::c06:6593:cfc3:5504%en0
    fe80::c06:6593:cfc3:5504%en0 -> biff.local


## How it Works

The main program is a simple command line tool that accepts parameters, creates query objects, runs them, and prints the results.

The various query classes are each a simple wrapper around CFHost; each has extensive comments explaining how to use the class and how the class works internally.


## Caveats

A previous version of the sample let you do reachability tests using `kCFHostReachability`.  This is a rarely used feature of CFHost, and something generally better done with the SCNetworkReachability API, and so it’s been removed from the sample.

There is a lot of redundancy between the various query classes.  I’ve left that in because it makes it easier to understand each class in isolation.  In real code it would be sensible to factor that out into a common subclass, helper functions, or whatever.


## Feedback

If you find any problems with this sample, or you’d like to suggest improvements, please [file a bug][bug] against it.

[bug]: <http://developer.apple.com/bugreporter/>

## Version History

1.0 (Apr 2004) was the first shipping version.

2.0 (Mar 2012) was a major rewrite to use the latest tools and techniques.

3.0 (Feb 2017) was a major rewrite to add a Swift version of the code.

Share and Enjoy

Apple Developer Technical Support<br>
Core OS/Hardware

7 Feb 2017

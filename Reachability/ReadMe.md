
Reachability
============
The Reachability sample application demonstrates how to use the System Configuration framework to monitor the network state of an iOS device. In particular, it demonstrates how to know when IP can be routed and when traffic will be routed through a Wireless Wide Area Network (WWAN) interface such as EDGE or 3G.

Note: Reachability cannot tell your application if you can connect to a particular host, only that an interface is available that might allow a connection, and whether that interface is the WWAN. To understand when and how to use Reachability, read [Networking Overview][1].

[1]: <http://developer.apple.com/library/ios/#documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/>


IPv6 Support
============
Reachability fully supports IPv6.  More specifically, each of the APIs handles IPv6 in the following way:

- reachabilityWithHostName and SCNetworkReachabilityCreateWithName:  Internally, this API works be resolving the host name to a set of IP addresses (this can be any combination of IPv4 and IPv6 addresses) and establishing separate monitors on all available addresses.

- reachabilityWithAddress and SCNetworkReachabilityCreateWithAddress:  To monitor an IPv6 address, simply pass in an IPv6 `sockaddr_in6 struct` instead of the IPv4 `sockaddr_in struct`.

- reachabilityForInternetConnection:  This monitors the address 0.0.0.0, which reachability treats as a special token that causes it to actually monitor the general routing status of the device, both IPv4 and IPv6.



Removal of reachabilityForLocalWiFi
============
Older versions of this sample included the method reachabilityForLocalWiFi. As originally designed, this method allowed apps using Bonjour to check the status of "local only" Wi-Fi (Wi-Fi without a connection to the larger internet) to determine whether or not they should advertise or browse. 

However, the additional peer-to-peer APIs that have since been added to iOS and OS X have rendered it largely obsolete.  Because of the narrow use case for this API and the large potential for misuse, reachabilityForLocalWiFi has been removed from Reachability.

Apps that have a specific requirement can use reachabilityWithAddress to monitor IN_LINKLOCALNETNUM (that is, 169.254.0.0).  

Note: ONLY apps that have a specific requirement should be monitoring IN_LINKLOCALNETNUM.  For the overwhelming majority of apps, monitoring this address is unnecessary and potentially harmful.


Using the Sample
================

Build and run the sample using Xcode. When running the iPhone Simulator, you can exercise the application by disconnecting the Ethernet cable, turning off AirPort, or by joining an ad-hoc local Wi-Fi network.

By default, the application uses www.apple.com for its remote host. You can change the host it uses in APLViewController.m by modifying the value of the remoteHostName variable in -viewDidLoad.

IMPORTANT: Reachability must use DNS to resolve the host name before it can determine the Reachability of that host, and this may take time on certain network connections.  Because of this, the API will return NotReachable until name resolution has completed.  This delay may be visible in the interface on some networks.

The Reachability sample demonstrates the asynchronous use of the SCNetworkReachability API. You can use the API synchronously, but do not issue a synchronous check by hostName on the main thread. If the device cannot reach a DNS server or is on a slow network, a synchronous call to the SCNetworkReachabilityGetFlags function can block for up to 30 seconds trying to resolve the hostName. If this happens on the main thread, the application watchdog will kill the application after 20 seconds of inactivity.

SCNetworkReachability API's do not currently provide a means to detect support for device level peer-to-peer networking, including Multipeer Connectivity, GameKit, Game Center, or peer-to-peer NSNetService.


Main Files
==========

Reachability.{h,m}
 -Basic demonstration of how to use the SystemConfiguration Reachablity APIs.

APLViewController.{h,m}
- Simple view controller that displays information about network reachability.


=============================================
Copyright (C) Apple Inc. All rights reserved.


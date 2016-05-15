/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file declares utility Objective-C functions used by the SimpleTunnel server.
 */

#ifndef ServerUtils_h
#define ServerUtils_h

/// Get the identifier for the UTUN interface.
UInt32 getUTUNControlIdentifier(int socket);

/// Setup a socket as non-blocking.
BOOL setUTUNAddress(NSString *ifname, NSString *address);

/// Set the IP address on a UTUN interface.
int getUTUNNameOption(void);

/// Get value of the UTUN iterface name socket option.
BOOL setSocketNonBlocking(int socket);

#endif /* ServerUtils_h */

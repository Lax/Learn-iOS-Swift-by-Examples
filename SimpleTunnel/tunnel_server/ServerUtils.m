/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains utility Objective-C code used by the SimpleTunnel server.
*/

@import Foundation;
@import Darwin;

#import <net/if_utun.h>
#import "tunnel_server-Bridging-Header.h"

UInt32
getUTUNControlIdentifier(int socket)
{
	struct ctl_info kernelControlInfo;

	bzero(&kernelControlInfo, sizeof(kernelControlInfo));
	strlcpy(kernelControlInfo.ctl_name, UTUN_CONTROL_NAME, sizeof(kernelControlInfo.ctl_name));

	if (ioctl(socket, CTLIOCGINFO, &kernelControlInfo)) {
		printf("ioctl failed on kernel control socket: %s\n", strerror(errno));
		return 0;
	}

	return kernelControlInfo.ctl_id;
}

BOOL
setSocketNonBlocking(int socket)
{
	int currentFlags = fcntl(socket, F_GETFL);
	if (currentFlags < 0) {
		printf("fcntl(F_GETFL) failed: %s\n", strerror(errno));
		return NO;
	}

	currentFlags |= O_NONBLOCK;

	if (fcntl(socket, F_SETFL, currentFlags) < 0) {
		printf("fcntl(F_SETFL) failed: %s\n", strerror(errno));
		return NO;
	}

	return YES;
}

BOOL
setUTUNAddress(NSString *interfaceName, NSString *addressString)
{
	struct in_addr address;

	if (inet_pton(AF_INET, [addressString UTF8String], &address) == 1) {
		struct ifaliasreq interfaceAliasRequest __attribute__ ((aligned (4)));
		struct in_addr mask = { 0xffffffff };
		int socketDescriptor = socket(AF_INET, SOCK_DGRAM, 0);

		if (socketDescriptor < 0) {
			printf("Failed to create a DGRAM socket: %s\n", strerror(errno));
			return NO;
		}

		memset(&interfaceAliasRequest, 0, sizeof(interfaceAliasRequest));

		strlcpy(interfaceAliasRequest.ifra_name, [interfaceName UTF8String], sizeof(interfaceAliasRequest.ifra_name));

		interfaceAliasRequest.ifra_addr.sa_family = AF_INET;
		interfaceAliasRequest.ifra_addr.sa_len = sizeof(struct sockaddr_in);
		memcpy(&((struct sockaddr_in *)&interfaceAliasRequest.ifra_addr)->sin_addr, &address, sizeof(address));

		interfaceAliasRequest.ifra_broadaddr.sa_family = AF_INET;
		interfaceAliasRequest.ifra_broadaddr.sa_len = sizeof(struct sockaddr_in);
		memcpy(&((struct sockaddr_in *)&interfaceAliasRequest.ifra_broadaddr)->sin_addr, &address, sizeof(address));

		interfaceAliasRequest.ifra_mask.sa_family = AF_INET;
		interfaceAliasRequest.ifra_mask.sa_len = sizeof(struct sockaddr_in);
		memcpy(&((struct sockaddr_in *)&interfaceAliasRequest.ifra_mask)->sin_addr, &mask, sizeof(mask));

		if (ioctl(socketDescriptor, SIOCAIFADDR, &interfaceAliasRequest) < 0) {
			printf("Failed to set the address of %s interface address to %s: %s\n", [interfaceName UTF8String], [addressString UTF8String], strerror(errno));
			close(socketDescriptor);
			return NO;
		}

		close(socketDescriptor);
	}

	return YES;
}

int
getUTUNNameOption(void)
{
	return UTUN_OPT_IFNAME;
}
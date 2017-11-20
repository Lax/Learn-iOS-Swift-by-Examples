/*
    Copyright (C) 2017 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Command line tool main.
 */

@import Foundation;

#import "QHostAddressQuery.h"
#import "QHostNameQuery.h"

#include <netdb.h>

// MARK: - utilities

/// Returns a string for the supplied error, formatted to make sense as command line output.
///
/// - Parameter error: The error to format.
/// - Returns: A string for that error, formatted to make sense as command line output.

static NSString * _Nonnull stringForError(NSError * _Nonnull error) {
    if ([error.domain isEqual:(__bridge NSString *)kCFErrorDomainCFNetwork]) {
        NSNumber * code = error.userInfo[(__bridge NSString *) kCFGetAddrInfoFailureKey];
        // We deliberately don't call `gai_strerror` here because this is a developer- 
        // oriented tool and we want to show the symbolic name of the error.
        switch (code.intValue) {
            case EAI_ADDRFAMILY: return @"EAI_ADDRFAMILY";
            case EAI_AGAIN:      return @"EAI_AGAIN";
            case EAI_BADFLAGS:   return @"EAI_BADFLAGS";
            case EAI_FAIL:       return @"EAI_FAIL";
            case EAI_FAMILY:     return @"EAI_FAMILY";
            case EAI_MEMORY:     return @"EAI_MEMORY";
            case EAI_NODATA:     return @"EAI_NODATA";
            case EAI_NONAME:     return @"EAI_NONAME";
            case EAI_SERVICE:    return @"EAI_SERVICE";
            case EAI_SOCKTYPE:   return @"EAI_SOCKTYPE";
            case EAI_SYSTEM:     return @"EAI_SYSTEM";
            case EAI_BADHINTS:   return @"EAI_BADHINTS";
            case EAI_PROTOCOL:   return @"EAI_PROTOCOL";
            case EAI_OVERFLOW:   return @"EAI_OVERFLOW";
            default:
                break;
        }
    }
    return error.description;
}

/// Converts an IP address to its string equivalent.
///
/// This does not hit the network and thus won't fail.
/// 
/// - Parameter address: An IP address, as a `NSData` value containing some flavour of `sockaddr`.
/// - Returns: The string equivalent of that IP address.

static NSString * _Nonnull numericStringForAddress(NSData * _Nonnull address) {
    char name[NI_MAXHOST];
    
    BOOL success = getnameinfo(address.bytes, (socklen_t) address.length, name, sizeof(name), NULL, 0, NI_NUMERICHOST | NI_NUMERICSERV) == 0;
    if ( ! success ) {
        return @"?";
    }
    return @(name);
}

/// Converts an IP address string to an IP address.
///
/// This does not hit the network but can fail if the string is not a valid IP address.
/// 
/// - Parameter numeric: An IP address string.
/// - Returns: An IP address, as an `NSData` value containing some flavour of `sockaddr`, or nil.

static NSData * _Nullable addressForNumericString(NSString * _Nonnull numericString) {
    struct addrinfo hints = {
        .ai_flags = AI_NUMERICHOST | AI_NUMERICSERV
    };
    struct addrinfo * addrList;
    BOOL success = getaddrinfo(numericString.UTF8String, NULL, &hints, &addrList) == 0;
    if ( ! success ) {
        return nil;
    }
    const struct addrinfo * cursor = addrList;
    NSData * result = [NSData dataWithBytes:cursor->ai_addr length:cursor->ai_addrlen];
    freeaddrinfo(addrList);
    return result;
}

// MARK: - main object

/// The main object, which is instantiated and run by the main function.

NS_ASSUME_NONNULL_BEGIN

@interface MainObj : NSObject <QHostAddressQueryDelegate, QHostNameQueryDelegate>

/// The name-to-address queries to run.

@property (nonatomic, strong, readonly) NSMutableArray<QHostAddressQuery *> *   addressQueries;

/// The address-to-name queries to run.

@property (nonatomic, strong, readonly) NSMutableArray<QHostNameQuery *> *      nameQueries;

/// The total number of queries to run.

@property (nonatomic, assign, readonly) NSInteger queryCount;

/// Runs the queries, not returning until they're all finished.

- (void)run;

@end

@interface MainObj ()

/// The number of queries that have finished.

@property (nonatomic, assign, readwrite) NSInteger finishedQueryCount;

@end

NS_ASSUME_NONNULL_END

@implementation MainObj

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        self->_addressQueries = [[NSMutableArray alloc] init];
        self->_nameQueries = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSInteger)queryCount {
    return (NSInteger) (self.addressQueries.count + self.nameQueries.count);
}

- (void)run {
    for (QHostAddressQuery * q in self.addressQueries) {
        q.delegate = self;
        [q start];
    }
    for (QHostNameQuery * q in self.nameQueries) {
        q.delegate = self;
        [q start];
    }
    while (self.finishedQueryCount != self.queryCount) {
        [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)hostAddressQuery:(QHostAddressQuery *)query didCompleteWithAddresses:(NSArray<NSData *> *)addresses {
    NSMutableArray<NSString *> * stringAddresses = [[NSMutableArray alloc] init];
    for (NSData * address in addresses) {
        [stringAddresses addObject: numericStringForAddress(address) ];
    }
    NSString * addressList = [stringAddresses componentsJoinedByString:@", "];
    fprintf(stdout, "%s -> %s\n", query.name.UTF8String, addressList.UTF8String);
    self.finishedQueryCount += 1;
}

- (void)hostAddressQuery:(QHostAddressQuery *)query didCompleteWithError:(NSError *)error {
    fprintf(stdout, "%s -> %s\n", query.name.UTF8String, stringForError(error).UTF8String);
    self.finishedQueryCount += 1;
}

- (void)hostNameQuery:(QHostNameQuery *)query didCompleteWithNames:(NSArray<NSString *> *)names {
    NSString * addressString = numericStringForAddress(query.address);
    NSString * nameList = [names componentsJoinedByString:@", "];
    fprintf(stdout, "%s -> %s\n", addressString.UTF8String, nameList.UTF8String);
    self.finishedQueryCount += 1;
}

- (void)hostNameQuery:(QHostNameQuery *)query didCompleteWithError:(NSError *)error {
    NSString * addressString = numericStringForAddress(query.address);
    fprintf(stdout, "%s -> %s\n", addressString.UTF8String, stringForError(error).UTF8String);
    self.finishedQueryCount += 1;
}

@end

// MARK: - main function

static void usage() {
    fprintf(stderr, "usage: %s -h apple.com\n", getprogname());
    fprintf(stderr, "       %s -a 17.172.224.47\n", getprogname());
    exit(EXIT_FAILURE);
}

int main(int argc, char **argv) {

    // Parse any options.

    MainObj * m = [[MainObj alloc] init];
    int opt;
    
    do {
        opt = getopt(argc, argv, "h:a:");
        switch (opt) {
            case -1: {
                // do nothing
            } break;
            case 'h': {
                NSString * name = @(optarg);
                if (name.length == 0) {
                    usage();
                }
                [m.addressQueries addObject: [[QHostAddressQuery alloc] initWithName:name] ];
            } break;
            case 'a': {
                NSData * address = addressForNumericString(@(optarg));
                if (address == nil) {
                    usage();
                }
                [m.nameQueries addObject: [[QHostNameQuery alloc] initWithAddress:address] ];
            } break;
            default: {
                usage();
            } break;
        }
    } while (opt != -1);

    // Check for inconsistencies and then run.

    if (m.queryCount == 0) {
        usage();                    // nothing to do
    }
    if (optind != argc) {
        usage();                    // extra stuff an the command line
    }
    [m run];
}

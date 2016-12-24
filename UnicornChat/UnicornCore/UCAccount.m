/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The class that manages the current user account status, and sending/receiving messages.
*/

#import "UCAccount.h"

@implementation UCAccount

+ (instancetype)sharedAccount {
    UCAccount *shared = [[UCAccount alloc] init];
    [shared setHasValidAuthentication:YES];
    return shared;
}

- (BOOL)sendMessage:(NSString *)message toRecipients:(NSArray *)recipients {
    // Sending a message here...
    
    return YES;
}

@end

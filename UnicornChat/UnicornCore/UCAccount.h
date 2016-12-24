/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The class that manages the current user account status, and sending/receiving messages.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UCAccount : NSObject
@property (nonatomic) BOOL hasValidAuthentication;

+ (instancetype)sharedAccount;

- (BOOL)sendMessage:(nullable NSString *)message toRecipients:(nullable NSArray *)recipients;
@end

NS_ASSUME_NONNULL_END

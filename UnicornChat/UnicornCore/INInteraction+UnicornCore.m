/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Convinience category on INInteraction to get information relevant to UnicornCore.
*/

#import "INInteraction+UnicornCore.h"

@interface INIntent (UnicornCore)

- (BOOL)isSendMessageIntent;
- (INSendMessageIntent *)sendMessageIntent;

@end

@implementation INIntent (UnicornCore)

- (BOOL)isSendMessageIntent {
    return NO;
}

- (INSendMessageIntent *)sendMessageIntent {
    return nil;
}

@end

@implementation INSendMessageIntent (UnicornCore)

- (BOOL)isSendMessageIntent {
    return YES;
}

- (INSendMessageIntent *)sendMessageIntent {
    return self;
}

@end

@implementation INInteraction (UnicornCore)

- (BOOL)representsSendMessageIntent {
    return [[self intent] isSendMessageIntent];
}

- (NSString *)messageContent {
    return [[[self intent] sendMessageIntent] content];
}

- (NSString *)recipientName {
    return [[[[[self intent] sendMessageIntent] recipients] firstObject] displayName];
}

@end

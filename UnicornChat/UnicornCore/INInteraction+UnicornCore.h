/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Convinience category on INInteraction to get information relevant to UnicornCore.
*/

#import <Intents/Intents.h>

@interface INInteraction (UnicornCore)

@property (nonatomic, assign, readonly) BOOL representsSendMessageIntent;
@property (nonatomic, copy, readonly) NSString *recipientName;
@property (nonatomic, copy, readonly) NSString *messageContent;

@end

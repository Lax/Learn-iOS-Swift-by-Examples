/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view that displays messages in UnicornChat.
*/

#import <UIKit/UIKit.h>

@interface UCChatView : UIView

@property (nonatomic, copy) NSString *recipientName;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, assign, getter=isSent) BOOL sent;

@end

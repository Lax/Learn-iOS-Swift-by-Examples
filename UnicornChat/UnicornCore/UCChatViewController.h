/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view controller to display messages.
*/

#import <UIKit/UIKit.h>

@class NSString;
@class UCContact;

@interface UCChatViewController : UIViewController

@property (nonatomic, strong) UCContact *recipient;
@property (nonatomic, strong) NSString *messageContent;
@property (nonatomic, assign, getter=isSent) BOOL sent;

@end

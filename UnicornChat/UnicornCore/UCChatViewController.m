/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller to display messages.
*/

#import "UCChatViewController.h"

#import "UCChatView.h"
#import "UCContact.h"

#import <Foundation/Foundation.h>

@interface UCChatViewController ()

@property (null_resettable, nonatomic, strong) UCChatView *view;

@end

@implementation UCChatViewController

@dynamic view;

- (void)loadView {
    UCChatView *chatView = [[UCChatView alloc] init];
    [self setView:chatView];
}

- (void)setRecipient:(UCContact *)recipient {
    if (![_recipient isEqual:recipient]) {
        _recipient = recipient;
        [[self view] setRecipientName:[recipient name]];
    }
}

- (NSString *)messageContent {
    return [[self view] content];
}

- (void)setMessageContent:(NSString *)messageContent {
    [[self view] setContent:messageContent];
}

- (void)setSent:(BOOL)sent {
    [[self view] setSent:sent];
}

- (BOOL)isSent {
    return [[self view] isSent];
}

@end

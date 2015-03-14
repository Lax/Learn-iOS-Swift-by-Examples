/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller demonstrates using the Text Input Controller.
 */

#import "AAPLTextInputController.h"


@implementation AAPLTextInputController

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    NSLog(@"%@ did deactivate", self);
}

- (IBAction)replyWithTextInputController {
    // Using the WKTextInputMode enum, you can specify which aspects of the Text Input Controller are shown when presented.
    [self presentTextInputControllerWithSuggestions:@[@"Yes", @"No", @"Maybe"] allowedInputMode:WKTextInputModeAllowEmoji completion:^(NSArray *results) {
        NSLog(@"Text Input Results: %@", results);
        
        if (results[0] != nil) {
            // Sends a non-nil result to the parent iOS application.
            BOOL didOpenParent = [WKInterfaceController openParentApplication:@{@"TextInput" : results[0]} reply:^(NSDictionary *replyInfo, NSError *error) {
                NSLog(@"Reply Info: %@", replyInfo);
                NSLog(@"Error: %@", [error localizedDescription]);
            }];
            
            NSLog(@"Did open parent application? %i", didOpenParent);
        }
    }];
}

@end




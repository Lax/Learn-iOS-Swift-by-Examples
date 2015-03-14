/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller represents a single page of the modal page-based navigation controller, presented in AAPLControllerDetailController.
 */

#import "AAPLPageController.h"

@interface AAPLPageController()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *pageLabel;

@end


@implementation AAPLPageController

- (void)awakeWithContext:(id)context {
    [self.pageLabel setText:[NSString stringWithFormat:@"%@ Page", context]];
}

- (void)willActivate {
    // This method is called when the controller is about to be visible to the wearer.
    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when the controller is no longer visible.
    NSLog(@"%@ did deactivate", self);
}

@end

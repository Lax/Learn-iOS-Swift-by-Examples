/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller demonstrates how to present a modal controller with a page-based navigation style. By performing a Force Touch gesture on the controller (click-and-hold in the iOS Simulator), you can present a menu.
 */

#import "AAPLControllerDetailController.h"

@implementation AAPLControllerDetailController

- (instancetype)init {
    self = [super init];

    if (self) {
        // Initialize variables here.
        // Configure interface objects here.
    }
    
    return self;
}

- (void)willActivate {
    // This method is called when the controller is about to be visible to the wearer.
    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when the controller is no longer visible.
    NSLog(@"%@ did deactivate", self);
}

- (IBAction)presentPages {
    NSArray *controllerNames = @[@"pageController", @"pageController", @"pageController", @"pageController", @"pageController"];
    NSArray *contexts = @[@"First", @"Second", @"Third", @"Fourth", @"Fifth"];
    [self presentControllerWithNames:controllerNames contexts:contexts];
}

- (IBAction)menuItemTapped {
    NSLog(@"A menu item was tapped.");
}

@end

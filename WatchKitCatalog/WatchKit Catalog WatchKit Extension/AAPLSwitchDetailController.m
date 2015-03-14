/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays switches and their various configurations.
 */

#import "AAPLSwitchDetailController.h"

@interface AAPLSwitchDetailController()

@property (weak, nonatomic) IBOutlet WKInterfaceSwitch *offSwitch;
@property (weak, nonatomic) IBOutlet WKInterfaceSwitch *coloredSwitch;

@end


@implementation AAPLSwitchDetailController

- (instancetype)init {
    self = [super init];

    if (self) {
        // Initialize variables here.
        // Configure interface objects here.
        
        [self.offSwitch setOn:NO];
        
        [self.coloredSwitch setColor:[UIColor blueColor]];
        [self.coloredSwitch setTitle:@"Blue Switch"];
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

- (IBAction)switchAction:(BOOL)on {
    NSLog(@"Switch value changed to %i.", on);
}

@end


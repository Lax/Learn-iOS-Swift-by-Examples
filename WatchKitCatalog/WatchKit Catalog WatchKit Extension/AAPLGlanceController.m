/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays the Glance. It demonstrates passing information, via Handoff, to the WatchKit app to route the wearer to the appropriate controller once the app is launched. Tapping on the Glance will launch the WatchKit app.
 */

#import "AAPLGlanceController.h"

@interface AAPLGlanceController()

@property (weak, nonatomic) IBOutlet WKInterfaceImage *glanceImage;

@end


@implementation AAPLGlanceController

- (void)awakeWithContext:(id)context {
    // Load image from WatchKit Extension.
    [self.glanceImage setImage:[UIImage imageNamed:@"Walkway"]];
}

- (void)willActivate {
    // This method is called when the controller is about to be visible to the wearer.
    NSLog(@"%@ will activate", self);
    
    // Use Handoff to route the wearer to the image detail controller when the Glance is tapped.
    [self updateUserActivity:@"com.example.apple-samplecode.WatchKit-Catalog" userInfo:@{@"controllerName": @"imageDetailController", @"detailInfo": @"This is some more detailed information to pass."} webpageURL:nil];
}

- (void)didDeactivate {
    // This method is called when the controller is no longer visible.
    NSLog(@"%@ did deactivate", self);
}

@end

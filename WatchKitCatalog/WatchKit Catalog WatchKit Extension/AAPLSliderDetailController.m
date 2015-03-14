/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays sliders and their various configurations.
 */

#import "AAPLSliderDetailController.h"

@interface AAPLSliderDetailController()

@property (weak, nonatomic) IBOutlet WKInterfaceSlider *coloredSlider;

@end


@implementation AAPLSliderDetailController

- (instancetype)init {
    self = [super init];

    if (self) {
        // Initialize variables here.
        // Configure interface objects here.
        
        [self.coloredSlider setColor:[UIColor redColor]];
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

- (IBAction)sliderAction:(float)value {
    NSLog(@"Slider value is now: %f", value);
}

@end

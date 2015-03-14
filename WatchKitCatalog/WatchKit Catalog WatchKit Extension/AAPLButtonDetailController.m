/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays buttons and shows use of groups within buttons. This also demonstrates how to hide and show UI elements at runtime.
 */

#import "AAPLButtonDetailController.h"

@interface AAPLButtonDetailController()

@property (weak, nonatomic) IBOutlet WKInterfaceButton *defaultButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *hiddenButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *placeholderButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *alphaButton;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic) CGFloat placeholderAlpha;

@end


@implementation AAPLButtonDetailController

- (instancetype)init {
    self = [super init];

    if (self) {
        // Initialize variables here.
        // Configure interface objects here.
        
        _hidden = NO;
        _placeholderAlpha = 1.0;
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

- (IBAction)hideAndShow {
    [self.placeholderButton setHidden:!self.isHidden];
    
    self.hidden = !self.isHidden;
}

- (IBAction)changeAlpha {
    [self.placeholderButton setAlpha:(self.placeholderAlpha == 1.0 ? 0.0 : 1.0)];
    
    self.placeholderAlpha = (self.placeholderAlpha == 1.0 ? 0.0 : 1.0);
}

@end

/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays labels and specialized labels (Date and Timer).
 */

#import "AAPLLabelDetailController.h"

@interface AAPLLabelDetailController()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *coloredLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *ultralightLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceTimer *timer;

@end


@implementation AAPLLabelDetailController

- (instancetype)init {
    self = [super init];

    if (self) {
        // Initialize variables here.
        // Configure interface objects here.

        [self.coloredLabel setTextColor:[UIColor purpleColor]];
        
        UIFont *font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightUltraLight];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:@"Ultralight Label" attributes:attrsDictionary];
        [self.ultralightLabel setAttributedText:attrString];
        
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setDay:10];
        [components setMonth:12];
        [components setYear:2015];
        [self.timer setDate:[[NSCalendar currentCalendar] dateFromComponents:components]];
        [self.timer start];
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

@end
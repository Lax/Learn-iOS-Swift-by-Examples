/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UISwitch.
*/

#import "AAPLSwitchViewController.h"

@interface AAPLSwitchViewController ()

@property (nonatomic, weak) IBOutlet UISwitch *defaultSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *tintedSwitch;

@end


#pragma mark -

@implementation AAPLSwitchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureDefaultSwitch];
    [self configureTintedSwitch];
}


#pragma mark - Configuration

- (void)configureDefaultSwitch {
    [self.defaultSwitch setOn:YES animated:YES];

    [self.defaultSwitch addTarget:self action:@selector(switchValueDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureTintedSwitch {
    self.tintedSwitch.tintColor = [UIColor aapl_applicationBlueColor];
    self.tintedSwitch.onTintColor = [UIColor aapl_applicationGreenColor];
    self.tintedSwitch.thumbTintColor = [UIColor aapl_applicationPurpleColor];

    [self.tintedSwitch addTarget:self action:@selector(switchValueDidChange:) forControlEvents:UIControlEventValueChanged];
}


#pragma mark - Actions

- (void)switchValueDidChange:(UISwitch *)aSwitch {
    NSLog(@"A switch changed its value: %@.", aSwitch);
}

@end

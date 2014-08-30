/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UISlider.
*/

#import "AAPLSliderViewController.h"

@interface AAPLSliderViewController ()

@property (nonatomic, weak) IBOutlet UISlider *defaultSlider;
@property (nonatomic, weak) IBOutlet UISlider *tintedSlider;
@property (nonatomic, weak) IBOutlet UISlider *customSlider;

@end


#pragma mark -

@implementation AAPLSliderViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureDefaultSlider];
    [self configureTintedSlider];
    [self configureCustomSlider];
}


#pragma mark - Configuration

- (void)configureDefaultSlider {
    self.defaultSlider.minimumValue = 0;
    self.defaultSlider.maximumValue = 100;
    self.defaultSlider.value = 42;
    self.defaultSlider.continuous = YES;
    
    [self.defaultSlider addTarget:self action:@selector(sliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureTintedSlider {
    self.tintedSlider.minimumTrackTintColor = [UIColor aapl_applicationBlueColor];
    self.tintedSlider.maximumTrackTintColor = [UIColor aapl_applicationPurpleColor];

    [self.tintedSlider addTarget:self action:@selector(sliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureCustomSlider {
    UIImage *leftTrackImage = [UIImage imageNamed:@"slider_blue_track"];
    [self.customSlider setMinimumTrackImage:leftTrackImage forState:UIControlStateNormal];
    
    UIImage *rightTrackImage = [UIImage imageNamed:@"slider_green_track"];
    [self.customSlider setMaximumTrackImage:rightTrackImage forState:UIControlStateNormal];
    
    UIImage *thumbImage = [UIImage imageNamed:@"slider_thumb"];
    [self.customSlider setThumbImage:thumbImage forState:UIControlStateNormal];
    
    self.customSlider.minimumValue = 0;
    self.customSlider.maximumValue = 100;
    self.customSlider.continuous = NO;
    self.customSlider.value = 84;

    [self.customSlider addTarget:self action:@selector(sliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
}


#pragma mark - Actions

- (void)sliderValueDidChange:(UISlider *)slider {
    NSLog(@"A slider changed its value: %@", slider);
}

@end

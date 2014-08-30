/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UISegmentedControl.
*/

#import "AAPLSegmentedControlViewController.h"

@interface AAPLSegmentedControlViewController()

@property (nonatomic, weak) IBOutlet UISegmentedControl *defaultSegmentedControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *tintedSegmentedControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *customSegmentsSegmentedControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *customBackgroundSegmentedControl;

@end


#pragma mark -

@implementation AAPLSegmentedControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureDefaultSegmentedControl];
    [self configureTintedSegmentedControl];
    [self configureCustomSegmentsSegmentedControl];
    [self configureCustomBackgroundSegmentedControl];
}


#pragma mark - Configuration

- (void)configureDefaultSegmentedControl {
    self.defaultSegmentedControl.momentary = YES;

    [self.defaultSegmentedControl setEnabled:NO forSegmentAtIndex:0];

    [self.defaultSegmentedControl addTarget:self action:@selector(selectedSegmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureTintedSegmentedControl {
    self.tintedSegmentedControl.tintColor = [UIColor aapl_applicationBlueColor];

    self.tintedSegmentedControl.selectedSegmentIndex = 1;

    [self.tintedSegmentedControl addTarget:self action:@selector(selectedSegmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureCustomSegmentsSegmentedControl {
    NSDictionary *imageToAccesssibilityLabelMappings = @{
        @"checkmark_icon": NSLocalizedString(@"Done", nil),
        @"search_icon": NSLocalizedString(@"Search", nil),
        @"tools_icon": NSLocalizedString(@"Settings", nil)
    };
    
    // Guarantee that the segments show up in the same order.
    NSArray *sortedSegmentImageNames = [[imageToAccesssibilityLabelMappings allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    [sortedSegmentImageNames enumerateObjectsUsingBlock:^(NSString *segmentImageName, NSUInteger idx, BOOL *stop) {
        UIImage *image = [UIImage imageNamed:segmentImageName];
        
        image.accessibilityLabel = imageToAccesssibilityLabelMappings[segmentImageName];
        
        [self.customSegmentsSegmentedControl setImage:image forSegmentAtIndex:idx];
    }];
    
    self.customSegmentsSegmentedControl.selectedSegmentIndex = 0;
    
    [self.customSegmentsSegmentedControl addTarget:self action:@selector(selectedSegmentDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)configureCustomBackgroundSegmentedControl {
    self.customBackgroundSegmentedControl.selectedSegmentIndex = 2;
    
    // Set the background images for each control state.
    UIImage *normalSegmentBackgroundImage = [UIImage imageNamed:@"stepper_and_segment_background"];
    [self.customBackgroundSegmentedControl setBackgroundImage:normalSegmentBackgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    UIImage *disabledSegmentBackgroundImage = [UIImage imageNamed:@"stepper_and_segment_background_disabled"];
    [self.customBackgroundSegmentedControl setBackgroundImage:disabledSegmentBackgroundImage forState:UIControlStateDisabled barMetrics:UIBarMetricsDefault];

    UIImage *highlightedSegmentBackgroundImage = [UIImage imageNamed:@"stepper_and_segment_background_highlighted"];
    [self.customBackgroundSegmentedControl setBackgroundImage:highlightedSegmentBackgroundImage forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    
    // Set the divider image.
    UIImage *segmentDividerImage = [UIImage imageNamed:@"stepper_and_segment_segment_divider"];
    [self.customBackgroundSegmentedControl setDividerImage:segmentDividerImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    // Create a font to use for the attributed title (both normal and highlighted states).
    UIFontDescriptor *captionFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1];
    UIFont *font = [UIFont fontWithDescriptor:captionFontDescriptor size:0];

    NSDictionary *normalTextAttributes = @{
        NSForegroundColorAttributeName:[UIColor aapl_applicationPurpleColor],
        NSFontAttributeName:font
    };
    [self.customBackgroundSegmentedControl setTitleTextAttributes:normalTextAttributes forState:UIControlStateNormal];

    NSDictionary *highlightedTextAttributes = @{
        NSForegroundColorAttributeName:[UIColor aapl_applicationGreenColor],
        NSFontAttributeName:font
    };
    [self.customBackgroundSegmentedControl setTitleTextAttributes:highlightedTextAttributes forState:UIControlStateHighlighted];
    
    [self.customBackgroundSegmentedControl addTarget:self action:@selector(selectedSegmentDidChange:) forControlEvents:UIControlEventValueChanged];
}


#pragma mark - Actions

- (void)selectedSegmentDidChange:(UISegmentedControl *)segmentedControl {
    NSLog(@"The selected segment changed for: %@.", segmentedControl);
}

@end

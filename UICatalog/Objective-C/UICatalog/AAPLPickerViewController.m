/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UIPickerView.
*/

#import "AAPLPickerViewController.h"

typedef NS_ENUM(NSInteger, AAPLPickerViewControllerColorComponent) {
    AAPLColorComponentRed = 0,
    AAPLColorComponentGreen,
    AAPLColorComponentBlue,
    AAPLColorComponentCount
};

/// The maximum RGB color
#define AAPL_RGB_MAX 255.0

/// The offset of each color value (from 0 to 255) for red, green, and blue.
#define AAPL_COLOR_VALUE_OFFSET 5

/// The number of colors within a color component.
#define AAPL_NUMBER_OF_COLOR_VALUES_PER_COMPONENT ((NSInteger)ceil(AAPL_RGB_MAX / AAPL_COLOR_VALUE_OFFSET) + 1)

@interface AAPLPickerViewController()<UIPickerViewDataSource, UIPickerViewDelegate, UIPickerViewAccessibilityDelegate>

@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, weak) IBOutlet UIView *colorSwatchView;

@property (nonatomic) CGFloat redColorComponent;
@property (nonatomic) CGFloat greenColorComponent;
@property (nonatomic) CGFloat blueColorComponent;

@end


#pragma mark -

@implementation AAPLPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Show that a given row is selected. This is off by default.
    self.pickerView.showsSelectionIndicator = YES;

    [self configurePickerView];
}

- (void)updateColorSwatchViewBackgroundColor {
    self.colorSwatchView.backgroundColor = [UIColor colorWithRed:self.redColorComponent green:self.greenColorComponent blue:self.blueColorComponent alpha:1];
}


#pragma mark - Configuration

- (void)configurePickerView {
    // Set the default selected rows (the desired rows to initially select will vary by use case).
    [self selectRowInPickerView:13 withColorComponent:AAPLColorComponentRed];
    [self selectRowInPickerView:41 withColorComponent:AAPLColorComponentGreen];
    [self selectRowInPickerView:24 withColorComponent:AAPLColorComponentBlue];
}

- (void)selectRowInPickerView:(NSInteger)row withColorComponent:(AAPLPickerViewControllerColorComponent)colorComponent {
    // Note that the delegate method on UIPickerViewDelegate is not triggered when manually calling -[UIPickerView selectRow:inComponent:animated:].
    // To do this, we fire off the delegate method manually.
    [self.pickerView selectRow:row inComponent:(NSInteger)colorComponent animated:YES];
    [self pickerView:self.pickerView didSelectRow:row inComponent:(NSInteger)colorComponent];
}


#pragma mark - RGB Color Setter Overrides

- (void)setRedColorComponent:(CGFloat)redColorComponent {
    if (_redColorComponent != redColorComponent) {
        _redColorComponent = redColorComponent;

        [self updateColorSwatchViewBackgroundColor];
    }
}

- (void)setGreenColorComponent:(CGFloat)greenColorComponent {
    if (_greenColorComponent != greenColorComponent) {
        _greenColorComponent = greenColorComponent;

        [self updateColorSwatchViewBackgroundColor];
    }
}

- (void)setBlueColorComponent:(CGFloat)blueColorComponent {
    if (_blueColorComponent != blueColorComponent) {
        _blueColorComponent = blueColorComponent;

        [self updateColorSwatchViewBackgroundColor];
    }
}


#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return AAPLColorComponentCount;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return AAPL_NUMBER_OF_COLOR_VALUES_PER_COMPONENT;
}


#pragma mark - UIPickerViewDelegate

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSInteger colorValue = row * AAPL_COLOR_VALUE_OFFSET;

    CGFloat colorComponent = (CGFloat)colorValue / AAPL_RGB_MAX;
    CGFloat redColorComponent = 0;
    CGFloat greenColorComponent = 0;
    CGFloat blueColorComponent = 0;

    switch (component) {
        case AAPLColorComponentRed:
            redColorComponent = colorComponent;
            break;
        case AAPLColorComponentGreen:
            greenColorComponent = colorComponent;
            break;
        case AAPLColorComponentBlue:
            blueColorComponent = colorComponent;
            break;
        default:
            NSLog(@"Invalid row/component combination for picker view.");
            break;
    }

    UIColor *foregroundColor = [UIColor colorWithRed:redColorComponent green:greenColorComponent blue:blueColorComponent alpha:1];

    NSString *titleText = [NSString stringWithFormat:@"%ld", (long)colorValue];

    // Set the foreground color for the attributed string.
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: foregroundColor
    };
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:titleText attributes:attributes];

    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    CGFloat colorComponentValue = (AAPL_COLOR_VALUE_OFFSET * row) / AAPL_RGB_MAX;

    switch (component) {
        case AAPLColorComponentRed:
            self.redColorComponent = colorComponentValue;
            break;

        case AAPLColorComponentGreen:
            self.greenColorComponent = colorComponentValue;
            break;

        case AAPLColorComponentBlue:
            self.blueColorComponent = colorComponentValue;
            break;
            
        default:
            NSLog(@"Invalid row/component combination selected for picker view.");
            break;
    }
}


#pragma mark - UIPickerViewAccessibilityDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView accessibilityLabelForComponent:(NSInteger)component {
    NSString *accessibilityLabel;

    switch (component) {
        case AAPLColorComponentRed:
            accessibilityLabel = NSLocalizedString(@"Red color component value", nil);
            break;
            
        case AAPLColorComponentGreen:
            accessibilityLabel = NSLocalizedString(@"Green color component value", nil);
            break;
            
        case AAPLColorComponentBlue:
            accessibilityLabel = NSLocalizedString(@"Blue color component value", nil);
            break;
            
        default:
            NSLog(@"Invalid row/component combination for picker view.");
            break;
    }

    return accessibilityLabel;
}

@end

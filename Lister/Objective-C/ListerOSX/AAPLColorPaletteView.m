/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A color palette view that allows the user to select a color defined in the \c AAPLListColor enumeration.
*/

#import "AAPLColorPaletteView.h"
@import QuartzCore;

@interface AAPLColorPaletteView()

@property (weak) IBOutlet NSButton *grayButton;
@property (weak) IBOutlet NSButton *blueButton;
@property (weak) IBOutlet NSButton *greenButton;
@property (weak) IBOutlet NSButton *yellowButton;
@property (weak) IBOutlet NSButton *orangeButton;
@property (weak) IBOutlet NSButton *redButton;

@property (weak) IBOutlet NSButton *overlayButton;

@property (weak) IBOutlet NSView *overlayView;
@property (weak) IBOutlet NSLayoutConstraint *overlayLayoutConstraint;

// Set in IB and saved to use for showing / hiding the overlay.
@property CGFloat initialLayoutConstraintConstant;

// The overlay is expanded initially in the storyboard.
@property (getter=isOverlayExpanded) BOOL overlayExpanded;


@end

@implementation AAPLColorPaletteView
@synthesize selectedColor = _selectedColor;

#pragma mark - View Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Make the background of the color palette view white.
    self.layer = [CALayer layer];
    self.layer.backgroundColor = [NSColor whiteColor].CGColor;
    
    // Make the overlay view color (i.e. selectedColor gray by default.
    self.overlayView.layer = [CALayer layer];
    self.selectedColor = AAPLListColorGray;

    self.initialLayoutConstraintConstant = self.overlayLayoutConstraint.constant;

    [self hideOverlayWithSelectedColor:self.selectedColor animated:NO];
    
    // Set the background color for each button.
    NSArray *buttons = @[self.grayButton, self.blueButton, self.greenButton, self.yellowButton, self.orangeButton, self.redButton];
    [buttons enumerateObjectsUsingBlock:^(NSButton *button, NSUInteger idx, BOOL *stop) {
        button.layer = [CALayer layer];

        AAPLListColor listColor = (AAPLListColor)button.tag;
        button.layer.backgroundColor = AAPLColorFromListColor(listColor).CGColor;
    }];
}

#pragma mark - IBActions

- (IBAction)colorButtonClicked:(NSButton *)sender {
    AAPLListColor listColor = (AAPLListColor)sender.tag;

    [self hideOverlayWithSelectedColor:listColor animated:YES];
}

- (IBAction)colorToggleButtonClicked:(NSButton *)sender {
    if (self.overlayExpanded) {
        [self hideOverlayWithSelectedColor:self.selectedColor animated:YES];
    }
    else {
        [self showOverlayAnimated:YES];
    }
}

#pragma mark - Property Overrides

- (void)setSelectedColor:(AAPLListColor)selectedColor {
    _selectedColor = selectedColor;
    
    self.overlayView.layer.backgroundColor = AAPLColorFromListColor(selectedColor).CGColor;
}

#pragma mark - Convenience

- (void)showOverlayAnimated:(BOOL)animated {
    [self setOverlayConstant:self.initialLayoutConstraintConstant buttonTitle:self.expandedTitle newSelectedColor:self.selectedColor animated:animated expanded:YES];
}

- (void)hideOverlayWithSelectedColor:(AAPLListColor)selectedColor animated:(BOOL)animated {
    [self setOverlayConstant:0 buttonTitle:[self unexpandedTitle] newSelectedColor:selectedColor animated:animated expanded:NO];
}

- (void)setOverlayConstant:(CGFloat)layoutConstant buttonTitle:(NSString *)buttonTitle newSelectedColor:(AAPLListColor)newSelectedColor animated:(BOOL)animated expanded:(BOOL)expanded {
    // Check to see if the selected colors are different. We only want to trigger the -colorPaletteViewDidChangeSelectedColor:
    // delegate call if the colors have changed.
    BOOL colorsAreDifferent = newSelectedColor != self.selectedColor;
    
    self.overlayExpanded = expanded;

    if (animated) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            // Customize the animation parameters.
            context.duration = 0.25;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

            self.overlayLayoutConstraint.animator.constant = layoutConstant;
            self.overlayButton.animator.title = buttonTitle;
            self.selectedColor = newSelectedColor;
        } completionHandler:^{
            if (colorsAreDifferent) {
                [self.delegate colorPaletteViewDidChangeSelectedColor:self];
            }
        }];
    }
    else {
        self.overlayLayoutConstraint.constant = layoutConstant;
        self.overlayButton.title = buttonTitle;
        self.selectedColor = newSelectedColor;
        
        if (colorsAreDifferent) {
            [self.delegate colorPaletteViewDidChangeSelectedColor:self];
        }
    }
}

- (NSString *)expandedTitle {
    return @"▶";
}

- (NSString *)unexpandedTitle {
    return @"◀";
}

@end

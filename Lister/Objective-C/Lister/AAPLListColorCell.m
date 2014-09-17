/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A custom cell that allows the user to select between 6 different colors.
            
*/

#import "AAPLListColorCell.h"

@interface AAPLListColorCell()

@property (nonatomic, weak) IBOutlet UIView *gray;
@property (nonatomic, weak) IBOutlet UIView *blue;
@property (nonatomic, weak) IBOutlet UIView *green;
@property (nonatomic, weak) IBOutlet UIView *yellow;
@property (nonatomic, weak) IBOutlet UIView *orange;
@property (nonatomic, weak) IBOutlet UIView *red;

@end

@implementation AAPLListColorCell

#pragma mark - Configuration

- (void)configure {
    UITapGestureRecognizer *colorTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(colorTap:)];
    colorTapGestureRecognizer.numberOfTapsRequired = 1;
    colorTapGestureRecognizer.numberOfTouchesRequired = 1;
    
    [self addGestureRecognizer:colorTapGestureRecognizer];
}

#pragma mark - UITapGestureRecognizer Handling

- (void)colorTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (tapGestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    CGPoint tapLocation = [tapGestureRecognizer locationInView:self.contentView];
    UIView *view = [self.contentView hitTest:tapLocation withEvent:nil];
    
    // If the user tapped on a color (identified by its tag), notify the delegate.
    if (view) {
        AAPLListColor color = (AAPLListColor)view.tag;
        
        switch (color) {
            case AAPLListColorGray:
            case AAPLListColorBlue:
            case AAPLListColorGreen:
            case AAPLListColorYellow:
            case AAPLListColorOrange:
            case AAPLListColorRed:
                self.selectedColor = color;
                [self.delegate listColorCellDidChangeSelectedColor:self];
                break;
        }
    }
}

@end

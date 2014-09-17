/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A custom cell used for displaying list documents.
            
*/

#import "AAPLListCell.h"

@implementation AAPLListCell

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    UIColor *color = self.listColorView.backgroundColor;
    
    [super setHighlighted:highlighted animated:animated];
    
    // Reset the background color for the list color; the default implementation makes it clear.
    self.listColorView.backgroundColor = color;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *color = self.listColorView.backgroundColor;
    
    [super setSelected:selected animated:animated];
    
    // Reset the background color for the list color; the default implementation makes it clear.
    self.listColorView.backgroundColor = color;
    
    // Ensure that tapping on a selected cell doesn't re-trigger the display of the document.
    self.userInteractionEnabled = !selected;
}

@end

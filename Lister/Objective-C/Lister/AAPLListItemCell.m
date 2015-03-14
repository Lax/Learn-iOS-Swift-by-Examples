/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom cell used to display a list item or the row used to create a new item.
*/

#import "AAPLListItemCell.h"

@implementation AAPLListItemCell

#pragma mark - Setter Overrides

- (void)setComplete:(BOOL)complete {
    _complete = complete;
    
    self.textField.enabled = !complete;
    self.checkBox.checked = complete;
    
    self.textField.textColor = complete ? [UIColor lightGrayColor] : [UIColor darkTextColor];
}

@end

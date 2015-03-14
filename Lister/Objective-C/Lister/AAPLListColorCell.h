/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom cell that allows the user to select a color.
*/

@import UIKit;
@import ListerKit;

@class AAPLListColorCell;

// Delegate protocol to let other objects know that the cell's color has changed.
@protocol AAPLListColorCellDelegate <NSObject>
- (void)listColorCellDidChangeSelectedColor:(AAPLListColorCell *)listColorCell;
@end

@interface AAPLListColorCell : UITableViewCell

@property (weak) id<AAPLListColorCellDelegate> delegate;

@property AAPLListColor selectedColor;

- (void)configure;

@end

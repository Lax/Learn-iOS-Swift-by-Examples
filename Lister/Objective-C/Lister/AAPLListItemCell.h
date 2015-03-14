/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom cell used to display a list item or the row used to create a new item.
*/

@import UIKit;
@import ListerKit;

@interface AAPLListItemCell : UITableViewCell

@property (nonatomic, weak) IBOutlet AAPLCheckBox *checkBox;
@property (nonatomic, weak) IBOutlet UITextField *textField;

@property (nonatomic, getter=isComplete) BOOL complete;

@end

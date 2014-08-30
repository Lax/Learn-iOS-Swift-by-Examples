/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  A check box cell for the Today view.
              
 */

@import UIKit;
@import ListerKit;

@interface AAPLCheckBoxCell : UITableViewCell

@property (weak) IBOutlet UILabel *label;
@property (weak) IBOutlet AAPLCheckBox *checkBox;

@end

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Implements LocalAuthentication framework demo.
*/

@import UIKit;

#import "AAPLTest.h"
#import"AAPLBasicTestViewController.h"

@interface AAPLLocalAuthenticationTestsViewController : AAPLBasicTestViewController

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *dynamicViewHeight;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

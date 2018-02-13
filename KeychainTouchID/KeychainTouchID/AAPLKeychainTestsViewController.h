/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Keychain with Touch ID demo implementation.
*/

@import UIKit;

#import "AAPLBasicTestViewController.h"

@interface AAPLKeychainTestsViewController : AAPLBasicTestViewController

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *dynamicViewHeight;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

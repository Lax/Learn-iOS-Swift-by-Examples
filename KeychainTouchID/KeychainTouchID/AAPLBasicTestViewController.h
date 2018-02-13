/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Test view controller parent for implementing test pages in the test application.
*/

@import UIKit;
#import "AAPLTest.h"


@interface AAPLBasicTestViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSArray<AAPLTest *> *tests;

- (void)printMessage:(NSString *)message inTextView:(UITextView *)textView;

@end

/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  Controls the logic for displaying the UI for creating a new list item for the table view.
              
 */

#import "AAPLAddItemViewController.h"
@import ListerKitOSX;

@implementation AAPLAddItemViewController

#pragma mark - IBActions

- (IBAction)textChanged:(NSTextField *)textField {
    NSString *cleansedString = [textField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (cleansedString.length > 0) {
        [self.delegate addItemViewController:self didCreateNewItemWithText:cleansedString];
    }

    // Tell the presenting view controller to dismiss the popover.
    [self.presentingViewController dismissViewController:self];
}

@end

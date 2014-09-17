/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                 The AAPLListRowViewController class is an NSViewController subclass that displays list items in a NCWidgetListViewController. Bindings are used to link the represented object to the view controller.
             
 */

#import "AAPLListRowViewController.h"
@import ListerKitOSX;

@interface AAPLListRowViewController()
@property (weak) IBOutlet AAPLCheckBox *checkBox;
@end

@implementation AAPLListRowViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // -representedObject is an AAPLListRowRepresentedObject instance.
    [self.checkBox bind:@"checked" toObject:self withKeyPath:@"self.representedObject.item.isComplete" options:nil];
    [self.checkBox bind:@"tintColor" toObject:self withKeyPath:@"self.representedObject.color" options:nil];
}

#pragma mark - IBActions

- (IBAction)checkBoxClicked:(AAPLCheckBox *)sender {
    [self.delegate listRowViewControllerDidChangeRepresentedObjectState:self];
}

@end

/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListRowViewController class is an \c NSViewController subclass that displays list items in a \c NCWidgetListViewController. Bindings are used to link the represented object to the view controller.
*/

#import "AAPLListRowViewController.h"
@import ListerKit;

@interface AAPLListRowViewController()

@property (weak) IBOutlet AAPLCheckBox *checkBox;

@end

@implementation AAPLListRowViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // -representedObject is an AAPLListRowRepresentedObject instance.
    [self.checkBox bind:@"checked" toObject:self withKeyPath:@"self.representedObject.listItem.isComplete" options:nil];
    [self.checkBox bind:@"tintColor" toObject:self withKeyPath:@"self.representedObject.color" options:nil];
}

#pragma mark - IBActions

- (IBAction)checkBoxClicked:(AAPLCheckBox *)sender {
    [self.delegate listRowViewControllerDidChangeRepresentedObjectState:self];
}

@end

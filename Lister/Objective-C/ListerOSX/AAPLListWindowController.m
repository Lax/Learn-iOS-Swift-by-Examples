/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  A window controller that displays a single list document. Handles interaction with the "share" button and the "plus" button (for creating a new item).
              
 */

#import "AAPLListWindowController.h"
#import "AAPLListViewController.h"
#import "AAPLAddItemViewController.h"
@import ListerKitOSX;

@interface AAPLListWindowController()

@property (weak) IBOutlet NSButton *shareButton;

@end

NSString *const AAPLListWindowControllerShowAddItemViewControllerSegueIdentifier = @"AAPLListWindowControllerShowAddItemViewControllerSegueIdentifier";

@implementation AAPLListWindowController

#pragma mark - Overrides

- (void)awakeFromNib {
    [super awakeFromNib];

    [self.shareButton sendActionOn:NSLeftMouseDownMask];
}

// Ensure that the content view controller actually knows about the document.
- (void)setDocument:(AAPLListDocument *)document {
    [super setDocument:document];

    AAPLListViewController *listViewController = (AAPLListViewController *)self.window.contentViewController;
    listViewController.document = document;
}

#pragma mark - IBActions

- (IBAction)shareDocument:(NSButton *)sender {
    AAPLListDocument *document = self.document;
    NSString *listContents = [AAPLListFormatting stringFromListItems:document.list.allItems];

    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:@[listContents]];
    
    [sharingServicePicker showRelativeToRect:NSZeroRect ofView:sender preferredEdge:NSMinYEdge];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:AAPLListWindowControllerShowAddItemViewControllerSegueIdentifier]) {
        AAPLListViewController *listViewController = (AAPLListViewController *)self.window.contentViewController;
        
        AAPLAddItemViewController *addItemViewController = segue.destinationController;
        
        addItemViewController.delegate = listViewController;
    }
}

@end

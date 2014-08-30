/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Controls the logic for displaying the UI for creating a new list item for the table view.
            
*/

@import Cocoa;

@class AAPLAddItemViewController;

// A protocol that allows a delegate of AddItemViewController to be aware of any new items that should be created.
@protocol AAPLAddItemViewControllerDelegate <NSObject>
- (void)addItemViewController:(AAPLAddItemViewController *)addItemViewController didCreateNewItemWithText:(NSString *)text;
@end

@interface AAPLAddItemViewController : NSViewController

@property (weak) id<AAPLAddItemViewControllerDelegate> delegate;

@end

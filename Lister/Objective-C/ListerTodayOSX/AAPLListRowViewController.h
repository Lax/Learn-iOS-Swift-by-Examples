/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                 The AAPLListRowViewController class is an NSViewController subclass that displays list items in a NCWidgetListViewController. Bindings are used to link the represented object to the view controller.
              
 */

@import Cocoa;

@class AAPLListRowRepresentedObject;
@class AAPLListRowViewController;

// Protocol that enables notifying other objects of changes to the represented object.
@protocol AAPLListRowViewControllerDelegate <NSObject>
- (void)listRowViewControllerDidChangeRepresentedObjectState:(AAPLListRowViewController *)listRowViewController;
@end

@interface AAPLListRowViewController : NSViewController

@property (strong) AAPLListRowRepresentedObject *representedObject;
@property (weak) id<AAPLListRowViewControllerDelegate> delegate;

@end

/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListRowViewController class is an \c NSViewController subclass that displays list items in a \c NCWidgetListViewController. Bindings are used to link the represented object to the view controller.
*/

@import Cocoa;

@class AAPLListRowRepresentedObject;
@class AAPLListRowViewController;

/// Protocol that enables notifying other objects of changes to the represented object.
@protocol AAPLListRowViewControllerDelegate <NSObject>

- (void)listRowViewControllerDidChangeRepresentedObjectState:(AAPLListRowViewController *)listRowViewController;

@end

@interface AAPLListRowViewController : NSViewController

@property (strong) AAPLListRowRepresentedObject *representedObject;
@property (weak) id<AAPLListRowViewControllerDelegate> delegate;

@end

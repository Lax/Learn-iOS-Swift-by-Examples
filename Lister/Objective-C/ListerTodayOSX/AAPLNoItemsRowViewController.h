/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An \c NSViewController subclass responsible for displaying the "No Items" row in the app extension.
*/

@import Cocoa;

@class AAPLListRowRepresentedObject;

@interface AAPLNoItemsRowViewController : NSViewController

@property (strong) AAPLListRowRepresentedObject *representedObject;

@end

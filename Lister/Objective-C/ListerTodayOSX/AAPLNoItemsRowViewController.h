/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
              An NSViewController subclass responsible for displaying the "No Items" row in the app extension.
           
 */

@import Cocoa;
#import "AAPLListRowRepresentedObject.h"

@interface AAPLNoItemsRowViewController : NSViewController

@property (strong) AAPLListRowRepresentedObject *representedObject;

@end

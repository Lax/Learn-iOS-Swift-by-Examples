/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Provides an abstraction suitable for adapting the details of a list item to the requirements of \c NCWidgetListViewController. It is composed of an item's text and list color.
*/

@import Foundation;
@import ListerKit;

@interface AAPLListRowRepresentedObject : NSObject

@property AAPLListItem *listItem;
@property NSColor *color;

@end

/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLColoredTextRowController class defines a simple interface that the \c AAPLListsInterfaceController uses to represent an \c AAPLList object in the table.
*/

@import UIKit;

/*!
 * A lightweight controller object that is responsible for displaying the content in a group within the
 * \c AAPLListsInterfaceController controller's \c WKInterfaceTable property.
 */
@interface AAPLColoredTextRowController : NSObject

- (void)setText:(NSString *)text;
- (void)setColor:(UIColor *)color;

@end

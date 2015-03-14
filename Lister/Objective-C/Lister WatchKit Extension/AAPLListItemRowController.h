/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Defines the row controllers used in the \c AAPLListInterfaceController class.
*/

@import WatchKit;

/// An empty row controller that is displayed when there are no list items in a list.
@interface AAPLNoItemsRowController : NSObject
@end

/*!
 * A row controller that represents a \c AAPLListItem object. The \c AAPLListItemRowController is used by the
 * \c AAPLListInterfaceController.
 */
@interface AAPLListItemRowController : NSObject

- (void)setText:(NSString *)text;
- (void)setTextColor:(UIColor *)color;
- (void)setCheckBoxImageNamed:(NSString *)imageName;

@end

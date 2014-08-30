/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  An NSTableCellView subclass that has a few controls that represent the state of a ListItem object.
              
 */

@import Cocoa;

@class AAPLListItemView;

@protocol AAPLListItemViewDelegate <NSObject>
- (void)listItemViewDidToggleCompletionState:(AAPLListItemView *)listItemView;
- (void)listItemViewTextDidEndEditing:(AAPLListItemView *)listItemView;
@end


@interface AAPLListItemView : NSTableCellView

@property (weak) id<AAPLListItemViewDelegate> delegate;

@property (getter=isComplete) BOOL completed;

@property NSColor *tintColor;

@property (copy) NSString *stringValue;

@end

/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A controller used by the ATColorTableController to edit the color property.
 */

@import Cocoa;

@protocol ATColorTableControllerDelegate;

@interface ATColorTableController : NSViewController {

    id <ATColorTableControllerDelegate> __unsafe_unretained _delegate;
}

+ (ATColorTableController *)sharedColorTableController;

- (void)editColor:(NSColor *)color withPositioningView:(NSView *)view;

@property (weak, readonly) NSColor *selectedColor;
@property (weak, readonly) NSString *selectedColorName;

@property(unsafe_unretained) id <ATColorTableControllerDelegate> delegate;

@end


#pragma mark -

@protocol ATColorTableControllerDelegate <NSObject>

@optional
- (void)colorTableController:(ATColorTableController *)controller didChooseColor:(NSColor *)color named:(NSString *)colorName;
@end


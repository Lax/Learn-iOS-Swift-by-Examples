/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A color palette view that allows the user to select a color defined in the \c AAPLListColor enumeration.
*/

@import Cocoa;
@import ListerKit;

@class AAPLColorPaletteView;

// Delegate protocol to let other objects know about changes to the selected color.
@protocol AAPLColorPaletteViewDelegate <NSObject>
- (void)colorPaletteViewDidChangeSelectedColor:(AAPLColorPaletteView *)colorPaletteView;
@end

@interface AAPLColorPaletteView : NSView

@property (weak) IBOutlet id<AAPLColorPaletteViewDelegate> delegate;

@property (nonatomic) AAPLListColor selectedColor;

@end

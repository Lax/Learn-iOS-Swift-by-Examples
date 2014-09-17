/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  A layer-backed custom check box that is IBDesignable and IBInspectable.
              
 */

#import "AAPLCheckBox.h"
#import "AAPLCheckBoxLayer.h"

@interface AAPLCheckBox()

@property (readonly) AAPLCheckBoxLayer *checkBoxLayer;

@end

@implementation AAPLCheckBox
@synthesize checked = _checked;
@synthesize tintColor = _tintColor;

#pragma mark - View Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];

    self.wantsLayer = YES;

    self.layer = [AAPLCheckBoxLayer layer];

    [self.layer setNeedsDisplay];
}

- (AAPLCheckBoxLayer *)checkBoxLayer {
    return (AAPLCheckBoxLayer *)self.layer;
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(40, 40);
}

#pragma mark - Events

- (void)mouseDown:(NSEvent *)event {
    self.checked = !self.checked;
    
    [self.cell performClick:self];
}

- (void)viewDidChangeBackingProperties {
    [super viewDidChangeBackingProperties];
    
    if (self.window) {
        self.layer.contentsScale = self.window.backingScaleFactor;
    }
}

#pragma mark - AAPLCheckBox Property Overrides

- (void)setChecked:(BOOL)checked {
    self.checkBoxLayer.checked = checked;
}

- (BOOL)isChecked {
    return self.checkBoxLayer.checked;
}

- (void)setTintColor:(NSColor *)tintColor {
    self.checkBoxLayer.tintColor = tintColor.CGColor;
}

- (NSColor *)tintColor {
    return [NSColor colorWithCGColor:self.checkBoxLayer.tintColor];
}

@end

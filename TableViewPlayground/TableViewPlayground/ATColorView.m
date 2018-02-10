/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A basic NSView subclass that supports having an animatable background color (NOTE: the animation only works when the view is layer backed).
 */

#import "ATColorView.h"

@import Quartz; // for CABasicAnimation

@implementation ATColorView

+ (id)defaultAnimationForKey:(NSString *)key {
    if ([key isEqualToString:@"backgroundColor"]) {
        return [CABasicAnimation animation];
    }
    return [super defaultAnimationForKey:key];
}

- (void)setBackgroundColor:(NSColor *)value {
    if (_backgroundColor != value) {
        _backgroundColor = value;
        self.layer.backgroundColor = _backgroundColor.CGColor;
        [self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)r {
    NSColor *color = self.backgroundColor;
    if (color) {
        [color set];
        NSRectFill(r);
    }
    if (self.drawBorder) {
        [[NSColor lightGrayColor] set];
        NSFrameRectWithWidth(self.bounds, 1.0);
    }
    if (self.window.firstResponder == self) {
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill(self.bounds);
    }
}

+ (Class)cellClass {
    // The cell is a container for the target/action
    return [NSActionCell class];
}

@end

/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Custom `SKNode` based slider.
 */

#import <SpriteKit/SpriteKit.h>


@interface AAPLSlider : SKNode {
    void (*_action)(id, SEL);
}

+ (AAPLSlider*)sliderWithWidth:(int)width height:(int)height text:(NSString*)txt;
- (id)initWithWidth:(int)width height:(int)height text:(NSString*)txt;

@property (nonatomic) CGFloat value;

- (CGFloat) width;
- (CGFloat) height;

- (void)setBackgroundColor:(SKColor*)col;
- (void)setClickedTarget:(id)target action:(SEL)action;

@end

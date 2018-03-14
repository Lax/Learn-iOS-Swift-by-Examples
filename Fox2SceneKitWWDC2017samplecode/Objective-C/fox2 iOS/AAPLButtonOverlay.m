/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Support class for action buttons.
 */

#import "AAPLButtonOverlay.h"

@implementation AAPLButtonOverlay {
    UITouch* _trackingTouch;
    SKShapeNode* _inner;
    SKShapeNode* _background;
    SKLabelNode* _label;
}

- (instancetype)initWithText:(NSString*)text {
    self = [super init];
    if (self) {
        _size = CGSizeMake(40, 40);
        self.alpha = 0.7;
        self.userInteractionEnabled = YES;
        [self buildButtonWithText:text];
    }
    return self;
}

- (void)setSize:(CGSize)size {
    if (!CGSizeEqualToSize(_size, size)) {
        _size = size;
        [self updateForSizeChange];
    }
}

- (void)buildButtonWithText:(NSString*)text {
    CGRect backgroundRect = CGRectMake(0, 0, _size.width, _size.height);
    _background = [[SKShapeNode alloc] init];
    _background.path = CGPathCreateWithEllipseInRect(backgroundRect, NULL);
    _background.strokeColor = [SKColor blackColor];
    _background.lineWidth = 3.0;
    [self addChild:_background];

    CGRect innerSize = CGRectZero;
    innerSize.size = self.innerSize;

    _inner = [[SKShapeNode alloc] init];
    _inner.path = CGPathCreateWithEllipseInRect(innerSize, NULL);
    _inner.lineWidth = 1.0;
    _inner.fillColor = [SKColor whiteColor];
    _inner.strokeColor = [SKColor grayColor];
    [self addChild:_inner];

    _label = [[SKLabelNode alloc] init];
    _label.fontName = [UIFont boldSystemFontOfSize:24].fontName;
    _label.fontSize = 24;
    _label.fontColor = [SKColor blackColor];
    _label.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    _label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    _label.position = CGPointMake(_size.width / 2.0, _size.height / 2.0 + 1.0f);
    _label.text = text;
    [self addChild:_label];
}

- (void)updateForSizeChange {
    CGRect backgroundRect = CGRectMake(0, 0, _size.width, _size.height);
    _background.path = CGPathCreateWithEllipseInRect(backgroundRect, NULL);
    CGRect innerRect = CGRectMake(0, 0, _size.width / 3.0,  _size.height / 3.0);
    _inner.path = CGPathCreateWithEllipseInRect(innerRect, NULL);
    _label.position = CGPointMake(_size.width / 2.0 - _label.frame.size.width / 2.0, _size.height / 2.0 - _label.frame.size.height / 2.0);
}

- (CGSize)innerSize {
    return CGSizeMake(_size.width,  _size.height);
}

- (void)resetInteraction {
    _trackingTouch = nil;
    _inner.fillColor = [SKColor whiteColor];

    if ([self.delegate respondsToSelector:@selector(didPressButtonOverlay:)]) {
        [self.delegate didPressButtonOverlay:self];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    _trackingTouch = [touches anyObject];
    _inner.fillColor = [SKColor blackColor];
    if ([self.delegate respondsToSelector:@selector(willPressButtonOverlay:)]) {
        [self.delegate willPressButtonOverlay:self];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    if ([touches containsObject:_trackingTouch]) {
        [self resetInteraction];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    if ([touches containsObject:_trackingTouch]) {
        [self resetInteraction];
    }
}


@end

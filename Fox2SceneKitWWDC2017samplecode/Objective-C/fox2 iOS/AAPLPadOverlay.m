/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Exposes D-Pad game controller type functionality with screen-rendered buttons.
 */

#import "AAPLPadOverlay.h"

@implementation AAPLPadOverlay {
    UITouch* _trackingTouch;
    CGPoint _startLocation;

    SKShapeNode* _stick;
    SKShapeNode* _background;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _size = CGSizeMake(150, 150);
        self.alpha = 0.7;
        self.userInteractionEnabled = YES;
        [self buildPad];
    }
    return self;
}

- (void)setSize:(CGSize)size {
    if (!CGSizeEqualToSize(_size, size)) {
        _size = size;
        [self updateForSizeChange];
    }
}

- (void)buildPad {
    CGRect backgroundRect = CGRectMake(0, 0, _size.width, _size.height);
    _background = [[SKShapeNode alloc] init];
    _background.path = CGPathCreateWithEllipseInRect(backgroundRect, NULL);
    _background.strokeColor = [SKColor blackColor];
    _background.lineWidth = 3.0;
    [self addChild:_background];

    CGRect stickRect = CGRectZero;
    stickRect.size = self.stickSize;

    _stick = [[SKShapeNode alloc] init];
    _stick.path = CGPathCreateWithEllipseInRect(stickRect, NULL);
    _stick.lineWidth = 2.0;
//#if TARGET_OS_OSX
    _stick.fillColor = [SKColor whiteColor];
//#endif
    _stick.strokeColor = [SKColor blackColor];
    [self addChild:_stick];

    [self updateStickPosition];
}

- (void)updateForSizeChange {
    CGRect backgroundRect = CGRectMake(0, 0, _size.width, _size.height);
    _background.path = CGPathCreateWithEllipseInRect(backgroundRect, NULL);
    CGRect stickRect = CGRectMake(0, 0, _size.width / 3.0,  _size.height / 3.0);
    _stick.path = CGPathCreateWithEllipseInRect(stickRect, NULL);
}

- (CGSize)stickSize {
    return CGSizeMake(_size.width / 3.0,  _size.height / 3.0);
}

- (void)updateStickPosition {
    const CGSize stickSize = self.stickSize;
    _stick.position =
        CGPointMake(_size.width / 2.0 - stickSize.width / 2.0 + _size.width / 2.0 * self.stickPosition.x,
                    _size.height / 2.0 - stickSize.height / 2.0 + _size.width / 2.0 * self.stickPosition.y);
}

- (void)setStickPosition:(CGPoint)stickPosition {
    _stickPosition = stickPosition;
    [self updateStickPosition];
}

- (void)updateStickPositionForTouchLocation:(CGPoint)location {
    vector_float2 l_vec = {location.x - _startLocation.x, location.y - _startLocation.y};
    l_vec.x = (l_vec.x / _size.width   - 0.5) * 2.0;
    l_vec.y = (l_vec.y / _size.height  - 0.5) * 2.0;
    if (vector_length_squared(l_vec) > 1)
        l_vec = vector_normalize(l_vec);
    location.x = l_vec.x;
    location.y = l_vec.y;
    self.stickPosition = location;
}

- (void)resetInteraction {
    self.stickPosition = CGPointZero;
    _trackingTouch = nil;
    _startLocation = CGPointZero;
    if ([self.delegate respondsToSelector:@selector(padOverlayVirtualStickInteractionDidEnd:)]) {
        [self.delegate padOverlayVirtualStickInteractionDidEnd:self];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    _trackingTouch = [touches anyObject];
    _startLocation = [_trackingTouch locationInNode:self];
    // Center start location
    _startLocation.x -= _size.width / 2.0;
    _startLocation.y -= _size.height / 2.0;
    [self updateStickPositionForTouchLocation:[_trackingTouch locationInNode:self]];
    if ([self.delegate respondsToSelector:@selector(padOverlayVirtualStickInteractionDidStart:)]) {
        [self.delegate padOverlayVirtualStickInteractionDidStart:self];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    if ([touches containsObject:_trackingTouch]) {
        [self updateStickPositionForTouchLocation:[_trackingTouch locationInNode:self]];
        if ([self.delegate respondsToSelector:@selector(padOverlayVirtualStickInteractionDidChange:)]) {
            [self.delegate padOverlayVirtualStickInteractionDidChange:self];
        }
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


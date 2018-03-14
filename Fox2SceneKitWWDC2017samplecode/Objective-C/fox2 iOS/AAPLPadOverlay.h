/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Exposes D-Pad game controller type functionality with screen-rendered buttons.
 */

#import <SpriteKit/SpriteKit.h>

@class AAPLPadOverlay;

@protocol AAPLPadOverlayDelegate <NSObject>

- (void)padOverlayVirtualStickInteractionDidStart:(AAPLPadOverlay*)padNode;
- (void)padOverlayVirtualStickInteractionDidChange:(AAPLPadOverlay*)padNode;
- (void)padOverlayVirtualStickInteractionDidEnd:(AAPLPadOverlay*)padNode;

@end

@interface AAPLPadOverlay : SKNode

// Default 100, 100
@property (nonatomic, assign) CGSize size;
// Range [-1, 1]
@property (nonatomic, assign) CGPoint stickPosition;
@property (nonatomic, readonly) CGSize stickSize;
@property (nonatomic, weak) id<AAPLPadOverlayDelegate> delegate;

@end

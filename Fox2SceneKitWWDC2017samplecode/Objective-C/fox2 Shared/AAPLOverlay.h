/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the 2D overlay (score).
*/

@import Foundation;
@import SpriteKit;

@class AAPLControlOverlay;
@class AAPLGameController;

@interface AAPLOverlay : SKScene

- (void)setupWithController:(AAPLGameController *)controller;
- (void)layout2DOverlay;

@property (nonatomic) NSUInteger collectedGemsCount;
@property (nonatomic, readonly) AAPLControlOverlay* controlOverlay;

- (void)didCollectKey;
- (void)showEndScreen;

#if TARGET_OS_IOS
- (void)showVirtualPad;
- (void)hideVirtualPad;
#endif

@end


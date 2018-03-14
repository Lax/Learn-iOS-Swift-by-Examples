/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class serves as the app's source of control flow.
 */

#import <SceneKit/SceneKit.h>

#if TARGET_OS_IPHONE
#import "AAPLPadOverlay.h"
#import "AAPLButtonOverlay.h"
#endif
#import "AAPLMenu.h"

#if TARGET_OS_IOS
@class AAPLControlOverlay;
#endif

// Collision bit masks
typedef NS_OPTIONS(NSUInteger, AAPLBitmask) {
    AAPLBitmaskCharacter        = 1UL << 0, // the main character
    AAPLBitmaskCollision        = 1UL << 1, // the ground and walls
    AAPLBitmaskEnemy            = 1UL << 2, // the enemies
    AAPLBitmaskTrigger          = 1UL << 3, // the box that triggers camera changes and other actions
    AAPLBitmaskCollectable      = 1UL << 4, // the collectables (gems and key)
};

#if TARGET_OS_IPHONE
@interface AAPLGameController : NSObject <SCNSceneRendererDelegate, AAPLMenuDelegate, AAPLPadOverlayDelegate, AAPLButtonOverlayDelegate>
#else
@interface AAPLGameController : NSObject <SCNSceneRendererDelegate, AAPLMenuDelegate>
#endif

- (instancetype)initWithSCNView:(SCNView *)view;

@property (strong, readonly) SCNScene *scene;
@property (strong, readonly) id <SCNSceneRenderer> sceneRenderer;

// reset the game
- (void)resetPlayerPosition;

// the character and camera direction driven by the controller
@property vector_float2 characterDirection;
@property vector_float2 cameraDirection;

// actions driven by the controller
- (void)controllerJump:(BOOL)jump;
- (void)controllerAttack;

@end

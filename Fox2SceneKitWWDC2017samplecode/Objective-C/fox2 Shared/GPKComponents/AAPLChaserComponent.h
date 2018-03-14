/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This is a simple behavior for enemies to chase the character when the player is detected.
 */

#import <GameplayKit/GameplayKit.h>
#import "AAPLBaseComponent.h"
#import "AAPLPlayerComponent.h"

@interface AAPLChaserComponent : AAPLBaseComponent
@property AAPLPlayerComponent *player;
@property GKInspectable float hitDistance;
@property GKInspectable float chaseDistance;
@property GKInspectable float chaseSpeed;
@property GKInspectable float wanderSpeed;
@property GKInspectable float mass;
@property GKInspectable float maxAcceleration;
@end


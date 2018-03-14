/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Behavior that is used by enemies when they become frightened by the player.
 */

#import <GameplayKit/GameplayKit.h>
#import "AAPLBaseComponent.h"
#import "AAPLPlayerComponent.h"

@interface AAPLScaredComponent : AAPLBaseComponent
@property AAPLPlayerComponent *player;
@property GKInspectable float fleeDistance;
@property GKInspectable float fleeSpeed;
@property GKInspectable float wanderSpeed;
@property GKInspectable float mass;
@property GKInspectable float maxAcceleration;
@end

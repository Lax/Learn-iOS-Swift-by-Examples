/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 GKComponent subclass that defines behaviors of the main character.
 */

#import <GameplayKit/GameplayKit.h>
#import "AAPLBaseComponent.h"

@class AAPLCharacter;

@interface AAPLPlayerComponent : AAPLBaseComponent
@property AAPLCharacter *character;
@end

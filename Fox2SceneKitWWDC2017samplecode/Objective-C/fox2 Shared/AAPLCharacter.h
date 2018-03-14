/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the main character, including its animations, sounds and direction.
 */

@import Foundation;

@interface AAPLCharacter : NSObject

- (instancetype)initWithScene:(SCNScene*)scene;

@property(nonatomic, readonly) SCNNode *node; //the top level node of the character
@property(nonatomic, readonly) float baseAltitude; //the altitude of the character, ignoring jumps

// actions
@property(nonatomic) BOOL jump;
@property vector_float2 direction;
@property(nonatomic) BOOL burning;

// attack
- (void)attack;
- (bool)isAttacking;

// updating the character
- (void)updateAtTime:(NSTimeInterval)time withRenderer:(id <SCNSceneRenderer>)renderer;
- (void)resetCharacterPosition;

// contact with enemy
- (void)wasTouchedByEnemy;
- (void)didHitEnemy;

@property(nonatomic) SCNPhysicsWorld* physicsWorld;

// utils
+ (SCNAnimationPlayer *)loadAnimationFromSceneNamed:(NSString *)sceneName;

@end


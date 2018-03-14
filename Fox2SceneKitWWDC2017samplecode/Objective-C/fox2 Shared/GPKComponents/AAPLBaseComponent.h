/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 GKComponent subclass that encapsulates code shared by other custom components.
 */

#import <GameplayKit/GameplayKit.h>


@interface GKAgent2D (AAPL_Scenekit)
@property matrix_float4x4 transform;
@end

@interface AAPLBaseComponent : GKComponent

@property (readonly) GKAgent2D*agent;
@property BOOL autoMoveNode;

- (void)positionAgentFromNode;
- (void)positionNodeFromAgent;
- (BOOL)isDead; 

@end



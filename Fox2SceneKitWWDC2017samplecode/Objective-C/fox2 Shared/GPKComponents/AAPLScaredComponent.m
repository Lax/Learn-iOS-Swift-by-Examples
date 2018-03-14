/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Behavior that is used by enemies when they become frightened by the player.
 */

#import "AAPLScaredComponent.h"

#import "AAPLPlayerComponent.h"
#import "AAPLScaredComponent.h"
#import "AAPLCharacter.h"

typedef enum
{
    Wander,
    Flee,
    Dead
} ScaredState;

@implementation AAPLScaredComponent
{
    ScaredState _state;
    AAPLPlayerComponent *_player;
    GKGoal *_fleeGoal;
    GKGoal *_wanderGoal;
    GKGoal *_centerGoal;
    GKBehavior *_behavior;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder])
    {
    }
    
    return self;
}

- (AAPLPlayerComponent *)player
{
    return _player;
}

- (BOOL)isDead
{
    return _state == Dead;
}

- (void)startWandering
{
    [_behavior setWeight:1 forGoal:_wanderGoal];
    [_behavior setWeight:0 forGoal:_fleeGoal];
    [_behavior setWeight:.3 forGoal:_centerGoal];
    _state = Wander;
}

- (void)startFleeing
{
    [_behavior setWeight:0 forGoal:_wanderGoal];
    [_behavior setWeight:1 forGoal:_fleeGoal];
    [_behavior setWeight:.4 forGoal:_centerGoal];
    _state = Flee;
}

- (void) setPlayer:(AAPLPlayerComponent *)player
{
    self.agent.mass = self.mass;
    self.agent.maxAcceleration = self.maxAcceleration;
    _player = player;
    _fleeGoal = [GKGoal goalToFleeAgent:self.player.agent];
    _wanderGoal = [GKGoal goalToWander:self.wanderSpeed];
    simd_float2 center[] = { {-1, 9}, {1, 9}, {1, 11}, {-1, 11} };
    GKPath * p = [GKPath pathWithPoints:center count:4 radius:.5 cyclical:YES];
    _centerGoal = [GKGoal goalToStayOnPath:p maxPredictionTime:1];
    _behavior = [GKBehavior behaviorWithGoals:@[_fleeGoal, _wanderGoal, _centerGoal]];
    self.agent.behavior = _behavior;
    [self startWandering];
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds
{
    if(_state == Dead)
        return;
    
    GKSCNNodeComponent *playerComponent = (GKSCNNodeComponent *)[self.player.entity componentForClass:GKSCNNodeComponent.class];
    SCNNode *player = playerComponent.node;
    
    GKSCNNodeComponent *nodeComponent = (GKSCNNodeComponent *)[self.entity componentForClass:GKSCNNodeComponent.class];
    SCNNode *enemyNode = nodeComponent.node;
    
    vector_float3 direction = enemyNode.simdWorldPosition - player.simdWorldPosition;
    float distance = vector_length(direction);
    
    switch (_state)
    {
        case Wander:
        {
            if (distance < self.fleeDistance) {
                [self startFleeing];
            }
        } break;
            
        case Flee:
        {
            if (distance > self.fleeDistance) {
                [self startWandering];
            }
        } break;
        case Dead:
            break;
    }
    
    //collision
    if (distance < 0.5) {
        if(_player.character.isAttacking){
            //let's die
            _state = Dead;
            
            [_player.character didHitEnemy];
            
            SCNScene *explosionScene = [SCNScene sceneNamed:@"Art.scnassets/enemy/enemy_explosion.scn"];
            
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.4];
            [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            [SCNTransaction setCompletionBlock:^{
                
                [explosionScene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
                    for(SCNParticleSystem *ps in node.particleSystems){
                        [enemyNode addParticleSystem:ps];
                    }
                }];
                
                //hide
                enemyNode.childNodes[0].opacity = 0.0;
            }];
            
            direction.y = 0;
            [enemyNode removeAllAnimations];
            enemyNode.eulerAngles = SCNVector3Make(enemyNode.eulerAngles.x,enemyNode.eulerAngles.y +  M_PI * 4.f, enemyNode.eulerAngles.z);
            enemyNode.simdWorldPosition = enemyNode.simdWorldPosition + vector_normalize(direction) * 1.5;
            
            [self positionAgentFromNode];
            
            [SCNTransaction commit];
        }
        else{
            [_player.character wasTouchedByEnemy];
        }
    }
    
    
    [super updateWithDeltaTime:seconds];
}


@end


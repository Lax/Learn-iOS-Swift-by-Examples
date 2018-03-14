/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This is a simple behavior for enemies to chase the character when the player is detected.
 */

#import "AAPLPlayerComponent.h"
#import "AAPLChaserComponent.h"
#import "AAPLCharacter.h"

typedef enum
{
    Wander,
    Chase,
    Dead
} ChaserState;

@implementation AAPLChaserComponent
{
    ChaserState _state;
    AAPLPlayerComponent *_player;
    GKGoal *_chaseGoal;
    GKGoal *_wanderGoal;
    GKGoal *_centerGoal;
    float _speed;
    BOOL _hitting;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder])
    {
        _speed = self.chaseSpeed;
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
    self.agent.maxSpeed = self.wanderSpeed;
    [self.agent.behavior setWeight:1 forGoal:_wanderGoal];
    [self.agent.behavior setWeight:0 forGoal:_chaseGoal];
    [self.agent.behavior setWeight:.4 forGoal:_centerGoal];
    _state = Wander;
}

- (void)startChasing
{
    self.agent.maxSpeed = _speed;
    [self.agent.behavior setWeight:0 forGoal:_wanderGoal];
    [self.agent.behavior setWeight:1 forGoal:_chaseGoal];
    [self.agent.behavior setWeight:.1 forGoal:_centerGoal];
    _state = Chase;
}

- (void) setPlayer:(AAPLPlayerComponent *)player
{
    _player = player;
    self.agent.mass = self.mass;
    self.agent.maxAcceleration = self.maxAcceleration;
    _chaseGoal = [GKGoal goalToSeekAgent:self.player.agent];
    _wanderGoal = [GKGoal goalToWander:self.wanderSpeed];
    simd_float2 center[] = { {-1, 9}, {1, 9}, {1, 11}, {-1, 11} };
    GKPath * p = [GKPath pathWithPoints:center count:4 radius:.5 cyclical:YES];
    _centerGoal = [GKGoal goalToStayOnPath:p maxPredictionTime:1];
    self.agent.behavior = [GKBehavior behaviorWithGoals:@[_chaseGoal, _wanderGoal, _centerGoal]];
    [self startWandering];
}

- (void)updateWithDeltaTime:(NSTimeInterval)seconds
{
    if(_state == Dead){
        return;
    }
    
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
            if (distance < self.chaseDistance) {
                [self startChasing];
            }
        } break;
            
        case Chase:
        {
            if (distance > self.chaseDistance) {
                [self startWandering];
            }
        } break;
        case Dead:
            break;
    }
    
    //update speed
    _speed = MIN(self.chaseSpeed, distance);
    
    if (distance < self.hitDistance) {
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

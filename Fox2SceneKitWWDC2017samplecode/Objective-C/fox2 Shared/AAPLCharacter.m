/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the main character, including its animations, sounds and direction.
 */

@import SceneKit;

#import "AAPLCharacter.h"
#import "AAPLGameController.h"

static CGFloat const AAPLCharacterSpeedFactor = 2.0;
static NSUInteger const AAPLCharacterStepsCount = 10;

static const vector_float3 characterInitialPosition = (vector_float3){0.1, -0.2, 0};

// some constants
#define Gravity 0.004
#define JumpImpulse 0.1
#define MinAltitude (-10)
#define EnableFootStepSound 0
#define CollisionMargin 0.04
#define ModelOffset (vector_float3){0, -(CollisionMargin), 0}
#define CollisionMeshBitMask 8



// Jump state
typedef enum
{
    AAPLJumpStateCanJump,
    AAPLJumpStateJumping,
    AAPLJumpStateFalling,
    AAPLJumpStateEnded,
}AAPLJumpState;

// Returns plane / ray intersection distance from ray origin.
float planeIntersect(vector_float3 planeNormal, float planeDist, vector_float3 rayOrigin, vector_float3 rayDirection) {
    return (planeDist - vector_dot(planeNormal, rayOrigin)) / vector_dot(planeNormal, rayDirection);
}

@implementation AAPLCharacter {
    // Character handle
    SCNNode *_characterNode; // top level node
    SCNNode *_characterOrientation;// the node to rotate to orient the character
    SCNNode *_model; // the model loaded from the character file
    
    // Physics
    SCNPhysicsShape* _characterCollisionShape;
    vector_float3 _collisionShapeOffsetFromModel;
    float _gravity;
    
    // Jumping
    BOOL _controllerJump;
    AAPLJumpState _jumpState;
    SCNNode *_groundNode;
    vector_float3 _groundNodeLastPosition;
    float _baseAltitude;
    float _targetAltitude;

    // avoid playing the step sound too often
    int _lastStepFrame;
    int _frameCounter;
    
    // Direction
    NSTimeInterval _previousUpdateTime;
    vector_float2 _controllerDirection;
    
    // walk
    BOOL _isWalking;
    CGFloat _walkSpeed;
    CGFloat _directionAngle;
    
    // states
    BOOL _isBurning;
    int _isAttacking;
    CFTimeInterval _lastHitTime;

    BOOL _shouldResetCharacterPosition;
    
    // Particle systems
    SCNParticleSystem *_jumpDustParticle;
    SCNParticleSystem *_fireParticles;
    SCNParticleSystem *_smokeParticles;
    SCNParticleSystem *_whiteSmokeParticles;
    SCNParticleSystem *_spinParticle;
    SCNParticleSystem *_spinCircleParticle;
    CGFloat _fireParticlesBirthRate;
    CGFloat _smokeParticlesBirthRate;
    CGFloat _whiteSmokeParticlesBirthRate;
    SCNNode *_spinParticleAttach;
    
    // Sound effects
    SCNAudioSource *_aahSound;
    SCNAudioSource *_ouchSound;
    SCNAudioSource *_hitSound;
    SCNAudioSource *_hitEnemySound;
    SCNAudioSource *_explodeEnemySound;
    SCNAudioSource *_catchFireSound;
    SCNAudioSource *_jumpSound;
    SCNAudioSource *_attackSound;
    SCNAudioSource *_steps[AAPLCharacterStepsCount];
    
    CFTimeInterval _lastOuchTime;
}

@synthesize jump;
@synthesize direction;

#pragma mark - Initialization

- (instancetype)initWithScene:(SCNScene*)scene {
    if (self = [super init]) {
        /// Load character from external file
        SCNScene *scene = [SCNScene sceneNamed:@"Art.scnassets/character/max.scn"];
        _model = [scene.rootNode childNodeWithName:@"Max_rootNode" recursively:YES];
        _model.simdPosition = ModelOffset;

        /* setup character hierarchy
         character
             |_orientationNode
                 |_model
         */
        _characterNode = [SCNNode node];
        _characterNode.name = @"character";
        _characterNode.simdPosition = characterInitialPosition;

        _characterOrientation = [SCNNode node];

        [_characterNode addChildNode:_characterOrientation];
        [_characterOrientation addChildNode:_model];

        //animations
        SCNAnimationPlayer *idleAnimation = [AAPLCharacter loadAnimationFromSceneNamed:@"Art.scnassets/character/max_idle.scn"];
        [_model addAnimationPlayer:idleAnimation forKey:@"idle"];
        [idleAnimation play];
        
        SCNAnimationPlayer *walkAnimation = [AAPLCharacter loadAnimationFromSceneNamed:@"Art.scnassets/character/max_walk.scn"];
        walkAnimation.speed = AAPLCharacterSpeedFactor;
        [walkAnimation stop];
#if EnableFootStepSound
        walkAnimation.animation.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0.1 block:^(CAAnimation *animation, id animatedObject, BOOL playingBackward) { [self playFootStep]; }],
                                           [SCNAnimationEvent animationEventWithKeyTime:0.6 block:^(CAAnimation *animation, id animatedObject, BOOL playingBackward) { [self playFootStep]; }]];
#endif
        [_model addAnimationPlayer:walkAnimation forKey:@"walk"];
        
        SCNAnimationPlayer *jumpAnimation = [AAPLCharacter loadAnimationFromSceneNamed:@"Art.scnassets/character/max_jump.scn"];
        jumpAnimation.animation.removedOnCompletion = NO;
        [jumpAnimation stop];
        jumpAnimation.animation.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0 block:^(CAAnimation *animation, id animatedObject, BOOL playingBackward) { [self playJumpSound]; }]];
        [_model addAnimationPlayer:jumpAnimation forKey:@"jump"];
        
        SCNAnimationPlayer *spinAnimation = [AAPLCharacter loadAnimationFromSceneNamed:@"Art.scnassets/character/max_spin.scn"];
        spinAnimation.animation.removedOnCompletion = NO;
        spinAnimation.speed = 1.5;
        [spinAnimation stop];
        spinAnimation.animation.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0 block:^(CAAnimation *animation, id animatedObject, BOOL playingBackward) { [self playAttackSound]; }]];
        [_model addAnimationPlayer:spinAnimation forKey:@"spin"];
        
        SCNNode *collider = [_model childNodeWithName:@"collider" recursively:YES];
        collider.physicsBody.collisionBitMask = AAPLBitmaskEnemy | AAPLBitmaskTrigger | AAPLBitmaskCollectable;

        // Setup collision shape
        SCNVector3 min, max;
        [_model getBoundingBoxMin:&min max:&max];

        CGFloat collisionCapsuleRadius = (max.x - min.x) * 0.4;
        CGFloat collisionCapsuleHeight = (max.y - min.y);

        SCNGeometry* collisionGeometry = [SCNCapsule capsuleWithCapRadius:collisionCapsuleRadius height:collisionCapsuleHeight];
        _characterCollisionShape = [SCNPhysicsShape shapeWithGeometry:collisionGeometry options:@{SCNPhysicsShapeOptionCollisionMargin: @(CollisionMargin)}];
        _collisionShapeOffsetFromModel = (vector_float3){0, collisionCapsuleHeight * 0.50f, 0.0};

        // Load particle systems
        SCNScene *particleScene = [SCNScene sceneNamed:@"Art.scnassets/character/jump_dust.scn"];
        SCNNode *particleNode = [particleScene.rootNode childNodeWithName:@"particle" recursively:YES];
        _jumpDustParticle = particleNode.particleSystems.firstObject;

        particleScene = [SCNScene sceneNamed:@"Art.scnassets/particles/burn.scn"];
        SCNNode *burnParticleNode = [particleScene.rootNode childNodeWithName:@"particles" recursively:YES];
        
        SCNNode *particleEmitter = [SCNNode node];
        [_characterOrientation addChildNode:particleEmitter];
        
        _fireParticles = [burnParticleNode childNodeWithName:@"fire" recursively:YES].particleSystems[0];
        _fireParticlesBirthRate = _fireParticles.birthRate;
        _fireParticles.birthRate = 0;
        
        _smokeParticles = [burnParticleNode childNodeWithName:@"smoke" recursively:YES].particleSystems[0];
        _smokeParticlesBirthRate = _smokeParticles.birthRate;
        _smokeParticles.birthRate = 0;
        
        _whiteSmokeParticles = [burnParticleNode childNodeWithName:@"whiteSmoke" recursively:YES].particleSystems[0];
        _whiteSmokeParticlesBirthRate = _whiteSmokeParticles.birthRate;
        _whiteSmokeParticles.birthRate = 0;
        
        particleScene = [SCNScene sceneNamed:@"Art.scnassets/particles/particles_spin.scn"];
        _spinParticle = [particleScene.rootNode childNodeWithName:@"particles_spin" recursively:YES].particleSystems.firstObject;
        _spinCircleParticle = [particleScene.rootNode childNodeWithName:@"particles_spin_circle" recursively:YES].particleSystems.firstObject;
        
        particleEmitter.position = SCNVector3Make(0, 0.05, 0);
        [particleEmitter addParticleSystem:_fireParticles];
        [particleEmitter addParticleSystem:_smokeParticles];
        [particleEmitter addParticleSystem:_whiteSmokeParticles];
        
        _spinParticleAttach = [_model childNodeWithName:@"particles_spin_circle" recursively:YES];
        
        // Load sound effects
        _aahSound = [SCNAudioSource audioSourceNamed:@"audio/aah_extinction.mp3"];
        _aahSound.volume = 0.3;
        _aahSound.positional = NO;
        [_aahSound load];
        
        _catchFireSound = [SCNAudioSource audioSourceNamed:@"audio/panda_catch_fire.mp3"];
        _catchFireSound.volume = 5.0;
        _catchFireSound.positional = NO;
        [_catchFireSound load];
        
        _ouchSound = [SCNAudioSource audioSourceNamed:@"audio/ouch_firehit.mp3"];
        _ouchSound.volume = 2.0;
        _ouchSound.positional = NO;
        [_ouchSound load];
        
        _hitSound = [SCNAudioSource audioSourceNamed:@"audio/hit.mp3"];
        _hitSound.volume = 2.0;
        _hitSound.positional = NO;
        [_hitSound load];
        
        _hitEnemySound = [SCNAudioSource audioSourceNamed:@"audio/Explosion1.m4a"];
        _hitEnemySound.volume = 0.2;
        _hitEnemySound.positional = NO;
        [_hitEnemySound load];
        
        _explodeEnemySound = [SCNAudioSource audioSourceNamed:@"audio/Explosion2.m4a"];
        _explodeEnemySound.volume = 0.2;
        _explodeEnemySound.positional = NO;
        [_explodeEnemySound load];
        
        _jumpSound = [SCNAudioSource audioSourceNamed:@"audio/jump.m4a"];
        _jumpSound.volume = 0.4;
        _jumpSound.positional = NO;
        [_jumpSound load];
        
        _attackSound = [SCNAudioSource audioSourceNamed:@"audio/attack.mp3"];
        _attackSound.volume = 0.5;
        _attackSound.positional = NO;
        [_attackSound load];
        
        for (NSUInteger i = 0; i < AAPLCharacterStepsCount; i++) {
            _steps[i] = [SCNAudioSource audioSourceNamed:[NSString stringWithFormat:@"audio/Step_rock_0%d.mp3", (uint32_t)i]];
            _steps[i].volume = 0.2;
            _steps[i].positional = NO;
            [_steps[i] load];
        }
        
        // default speed
        _walkSpeed = 1.0;
    }
    
    return self;
}

#pragma mark - marks

- (SCNNode *)node
{
    return _characterNode;
}

- (float)baseAltitude
{
    return _baseAltitude;
}

- (void)_setupCharacterSliderConstraint {
    // Collisions are handled by the physics engine. The character is approximated by
    // a capsule that is configured to collide with collectables, enemies and walls
    SCNVector3 min, max;
    [_model getBoundingBoxMin:&min max:&max];
    CGFloat collisionCapsuleRadius = (max.x - min.x) * 0.5;

    SCNSliderConstraint *constraint = [SCNSliderConstraint sliderConstraint];
    constraint.collisionCategoryBitMask = 8;
    constraint.radius = collisionCapsuleRadius;
    constraint.offset = SCNVector3Make(0, collisionCapsuleRadius + 0.01, 0);

    _characterNode.constraints = @[constraint];
}

- (void)resetCharacterPosition {
    _shouldResetCharacterPosition = YES;
}

#pragma mark - Audio

- (void)playFootStep {
    if (_groundNode != nil && _isWalking) { // We are in the air, no sound to play.
        // Play a random step sound.
        NSInteger stepSoundIndex = MIN(AAPLCharacterStepsCount - 1, (rand() / (float)RAND_MAX) * AAPLCharacterStepsCount);
        
        [_characterNode runAction:[SCNAction playAudioSource:_steps[stepSoundIndex] waitForCompletion:NO]];
    }
}

- (void)playJumpSound {
    [_characterNode runAction:[SCNAction playAudioSource:_jumpSound waitForCompletion:NO]];
}
- (void)playAttackSound {
    [_characterNode runAction:[SCNAction playAudioSource:_attackSound waitForCompletion:NO]];
}


- (void)setBurning:(BOOL)burning
{
    if(burning != _isBurning){
        _isBurning = burning;
        
        //walk faster when burning
        [self setWalkSpeed:_walkSpeed];
        
        if(burning){
            _lastOuchTime = CFAbsoluteTimeGetCurrent();
            
            [_model runAction:
                 [SCNAction sequence:@[[SCNAction playAudioSource:_catchFireSound waitForCompletion:NO],
                                       [SCNAction playAudioSource:_ouchSound waitForCompletion:NO],
                 [SCNAction repeatActionForever:[SCNAction sequence:@[[SCNAction fadeOpacityTo:0.01 duration:0.1],
                                                   [SCNAction fadeOpacityTo:1.0 duration:0.1]]]]
                                                   ]]];
            
            _whiteSmokeParticles.birthRate = 0;
            _fireParticles.birthRate = _fireParticlesBirthRate;
            _smokeParticles.birthRate = _smokeParticlesBirthRate;
        }
        else{
            [_model removeAllActions];
            _model.opacity = 1.0;
            
            // audio
            CFTimeInterval endOuchTime = CFAbsoluteTimeGetCurrent();
            if(endOuchTime > _lastOuchTime + 0.5){
                [_model removeAllAudioPlayers];
                [_model runAction:[SCNAction playAudioSource:_aahSound waitForCompletion:NO]];
            }
            
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:0.0];
            _whiteSmokeParticles.birthRate = _whiteSmokeParticlesBirthRate;
            _fireParticles.birthRate = 0;
            _smokeParticles.birthRate = 0;
            [SCNTransaction commit];
            
            // progressively stop white smoke
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:5.0];
            _whiteSmokeParticles.birthRate = 0;
            [SCNTransaction commit];
        }
    }
}

#pragma mark - Controlling the character

- (void)setDirectionAngle:(CGFloat)directionAngle {
    _directionAngle = directionAngle;
    [_characterOrientation runAction:[SCNAction rotateToX:0.0 y:directionAngle z:0.0 duration:0.1 shortestUnitArc:YES]];
}

- (void)updateAtTime:(NSTimeInterval)time withRenderer:(id <SCNSceneRenderer>)renderer
{
    _frameCounter++;
    
    if (_shouldResetCharacterPosition) {
        _shouldResetCharacterPosition = NO;
        [self _resetCharacterPosition];
        return;
    }

    vector_float3 characterVelocity = 0;

    // setup
    vector_float3 groundMove = 0;
    
    // did the ground moved?
    if(_groundNode){
        vector_float3 groundPosition = [_groundNode simdWorldPosition];
        groundMove = groundPosition - _groundNodeLastPosition;
    }

    characterVelocity = (vector_float3){groundMove.x, 0, groundMove.z};
    
    vector_float3 direction = [self characterDirectionRelativeToPointOfView:renderer.pointOfView];
    
    if (_previousUpdateTime == 0.0) {
        _previousUpdateTime = time;
    }
    
    NSTimeInterval deltaTime = time - _previousUpdateTime;
    CGFloat characterSpeed = deltaTime * AAPLCharacterSpeedFactor * _walkSpeed;
    float virtualFrameCount = deltaTime / (1/60.);
    _previousUpdateTime = time;
    
    // move
    if (!vector_all(direction == 0.0f)) {
        characterVelocity = direction * characterSpeed;
#if TARGET_OS_OSX
        if ([NSEvent modifierFlags] & NSEventModifierFlagShift) {
            [self setWalkSpeed:2.0f * vector_length(direction)];
        } else
#endif
        {
            [self setWalkSpeed:vector_length(direction)];
        }
        
        // move character
        self.directionAngle = atan2(direction.x, direction.z);
        
        self.walking = YES;
    } else {
        self.walking = NO;
    }
    
    // put the character on the ground
    vector_float3 up = {0, 1, 0};
    SCNVector3 wPosition = [_characterNode worldPosition];
    
    // gravity
    _gravity -= Gravity;
    wPosition.y += _gravity;
    
#define HIT_RANGE 0.2
    SCNVector3 p0 = wPosition;
    SCNVector3 p1 = wPosition;
    p0.y = wPosition.y + up.y * HIT_RANGE;
    p1.y = wPosition.y - up.y * HIT_RANGE;
    
    SCNHitTestResult *hit = [[renderer.scene.rootNode hitTestWithSegmentFromPoint:p0 toPoint:p1 options:@{SCNHitTestBackFaceCullingKey : @(NO), SCNHitTestOptionCategoryBitMask: @(CollisionMeshBitMask), SCNHitTestIgnoreHiddenNodesKey: @NO}] firstObject];

    BOOL wasTouchingTheGroup = _groundNode != nil;
    _groundNode = nil;
    BOOL touchesTheGround = NO;
    BOOL wasBurning = _isBurning;
    
    if(hit){
        vector_float3 ground = SCNVector3ToFloat3(hit.worldCoordinates);
        if(wPosition.y <= ground.y + CollisionMargin){
            wPosition.y = ground.y + CollisionMargin;
            if(_gravity < 0)
                _gravity = 0;
            _groundNode = hit.node;
            touchesTheGround = YES;
            
            //touching lava?
            [self setBurning:[_groundNode.name isEqualToString:@"COLL_lava"]];
        }
    }
    else{
        if(wPosition.y < MinAltitude){
            wPosition.y = MinAltitude;
            //reset
            [self resetCharacterPosition];
        }
    }

    _groundNodeLastPosition = [_groundNode simdWorldPosition];
    
    //jump -------------------------------------------------------------
    if(_jumpState == AAPLJumpStateEnded || _jumpState == AAPLJumpStateCanJump){
        if(_jumpState == AAPLJumpStateCanJump && self.jump && touchesTheGround){
            _gravity += JumpImpulse;
            _jumpState = AAPLJumpStateJumping;
            
            [[_model animationPlayerForKey:@"jump"] play];
        }
        
        if(!self.jump)
            _jumpState = AAPLJumpStateCanJump;
    }
    else{
        if(_jumpState == AAPLJumpStateJumping && !self.jump){
            _jumpState = AAPLJumpStateFalling;
        }
        
        if(_gravity > 0){
            for(int step = 0; step < virtualFrameCount; step++){
                _gravity *= _jumpState == AAPLJumpStateJumping ? 0.99 : 0.2;
            }
        }
        
        if(touchesTheGround){
            if(!wasTouchingTheGroup){
                [[_model animationPlayerForKey:@"jump"] stopWithBlendOutDuration:0.1];
            
                // trigger jump particles if not touching lava
                if(!_isBurning){
                    [[_model childNodeWithName:@"dustEmitter" recursively:YES] addParticleSystem:_jumpDustParticle];
                    
#if !EnableFootStepSound
                    [_characterNode runAction:[SCNAction playAudioSource:_steps[0] waitForCompletion:NO]];
#endif
                    
                } else {
                    // jump in lava again
                    if(wasBurning){
                        [_characterNode runAction:[SCNAction sequence:@[
                                [SCNAction playAudioSource:_catchFireSound waitForCompletion:NO],
                                [SCNAction playAudioSource:_ouchSound waitForCompletion:NO]]]];
                    }
                }
            }
            
            // we are touching the ground, we can jump again only if we released the jump button
            if(!self.jump){
                _jumpState = AAPLJumpStateCanJump;
            }
            else{
                _jumpState = AAPLJumpStateEnded;
            }
        }
    }
    
#if EnableFootStepSound
    if(touchesTheGround && !wasTouchingTheGroup && !_isBurning && _lastStepFrame < _frameCounter-10){
        // sound
        _lastStepFrame = _frameCounter;
        [_characterNode runAction:[SCNAction playAudioSource:_steps[0] waitForCompletion:NO]];
    }
#endif
    
    if (wPosition.y < _characterNode.position.y) {
        wPosition.y = _characterNode.position.y;
    }
    //------------------------------------------------------------------
    
    /* progressibely update the elevation node when we touch the ground */
    if(touchesTheGround)
    {
        _targetAltitude = wPosition.y;
    }
    _baseAltitude = _baseAltitude * 0.95 + _targetAltitude * 0.05;

    characterVelocity.y += _gravity;
    if (vector_length_squared(characterVelocity) > 10E-4 * 10E-4) {
        vector_float3 startPosition = _characterNode.presentationNode.simdWorldPosition + _collisionShapeOffsetFromModel;
        [self _slideInWorldFromPosition:startPosition velocity:characterVelocity];
    }
}

#pragma mark - Animating the character

- (bool)isAttacking
{
    return _isAttacking > 0;
}

- (void)attack
{
    _isAttacking++;
    
    [[_model animationPlayerForKey:@"spin"] play];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _isAttacking--;
    });
    
    [_spinParticleAttach addParticleSystem:_spinCircleParticle];
}

- (void)setWalking:(BOOL)walking {
    if (_isWalking != walking) {
        _isWalking = walking;
        
        // Update node animation.
        if (_isWalking) {
            [[_model animationPlayerForKey:@"walk"] play];
        } else {
            [[_model animationPlayerForKey:@"walk"] stopWithBlendOutDuration:0.2];
        }
    }
}

- (void)setWalkSpeed:(CGFloat)walkSpeed {
    _walkSpeed = walkSpeed;
    
    float burningFactor = _isBurning ? 2 : 1;
    [_model animationPlayerForKey:@"walk"].speed = AAPLCharacterSpeedFactor * _walkSpeed * burningFactor;
}

- (vector_float3)characterDirectionRelativeToPointOfView:(SCNNode *)pov {
    const vector_float2 controllerDir = self.direction;
    if (vector_all(controllerDir == 0))
        return 0;

    const vector_float3 direction = {controllerDir.x, 0.0, controllerDir.y};

    vector_float3 directionWorld = 0;
    if (pov) {
        const vector_float3 p1 = [pov.presentationNode simdConvertPosition:direction toNode:nil];
        const vector_float3 p0 = [pov.presentationNode simdConvertPosition:0 toNode:nil];
        directionWorld = p1 - p0;
        directionWorld.y = 0;
        if (vector_any(directionWorld != 0.0f)) {
            const float minControllerSpeedFactor = 0.2f;
            const float maxControllerSpeedFactor = 1.0f;
            const float speed = vector_length(controllerDir) * (maxControllerSpeedFactor - minControllerSpeedFactor) + minControllerSpeedFactor;
            directionWorld = speed * vector_normalize(directionWorld);
        }
    }
    return directionWorld;
}

- (void)_resetCharacterPosition {
    _characterNode.simdPosition = characterInitialPosition;
    _gravity = 0;
}

#pragma mark - enemy

- (void)didHitEnemy
{
    [_model runAction:[SCNAction group:@[[SCNAction playAudioSource:_hitEnemySound waitForCompletion:NO],
                                         [SCNAction sequence:@[[SCNAction waitForDuration:.5],
                                                               [SCNAction playAudioSource:_explodeEnemySound waitForCompletion:NO]]]]]];
}


- (void)wasTouchedByEnemy
{
    CFTimeInterval time = CFAbsoluteTimeGetCurrent();
    
    if(time > _lastHitTime+1){
        _lastHitTime = time;
        
        //touched
        [_model runAction:
         [SCNAction sequence:@[[SCNAction playAudioSource:_hitSound waitForCompletion:NO],
                               [SCNAction repeatAction:[SCNAction sequence:@[[SCNAction fadeOpacityTo:0.01 duration:0.1],
                                                                             [SCNAction fadeOpacityTo:1.0 duration:0.1]]] count:4]]]];
    }
}

#pragma mark - Utils

+ (SCNAnimationPlayer *)loadAnimationFromSceneNamed:(NSString *)sceneName {
    SCNScene *scene = [SCNScene sceneNamed:sceneName];
    
    // find top level animation
    __block SCNAnimationPlayer *animationPlayer = nil;
    [scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
        if (child.animationKeys.count > 0) {
            animationPlayer = [child animationPlayerForKey:child.animationKeys[0]];
            *stop = YES;
        }
    }];
    
    return animationPlayer;
}

#pragma mark - physics contact

- (void)_slideInWorldFromPosition:(vector_float3)start velocity:(vector_float3)velocity {
    const int maxSlideIteration = 4;
    int iteration = 0;
    bool stop = false;

    vector_float3 replacementPoint = start;

    while(!stop) {
        matrix_float4x4 from = matrix_identity_float4x4;
        from.columns[3].xyz = start;

        matrix_float4x4 to = matrix_identity_float4x4;
        to.columns[3].xyz = start + velocity;

        NSArray<SCNPhysicsContact *> * contacts =
            [self.physicsWorld convexSweepTestWithShape:_characterCollisionShape
                                          fromTransform:SCNMatrix4FromMat4(from)
                                            toTransform:SCNMatrix4FromMat4(to)
                                                options:@{ SCNPhysicsTestCollisionBitMaskKey: @(AAPLBitmaskCollision),
                                                           SCNPhysicsTestSearchModeKey: SCNPhysicsTestSearchModeClosest }];

       if (contacts.count) {
            SCNPhysicsContact *closestContact = contacts.firstObject;
            const float originalDistance = vector_length(velocity);
            vector_float3 colliderPositionAtContact = start + closestContact.sweepTestFraction * velocity;

            // Compute the sliding plane.
            vector_float3 slidePlaneNormal = SCNVector3ToFloat3(closestContact.contactNormal);
            vector_float3 slidePlaneOrigin = SCNVector3ToFloat3(closestContact.contactPoint);
            vector_float3 centerOffset = slidePlaneOrigin - colliderPositionAtContact;

            // Compute destination relative to the point of contact.
            vector_float3 destinationPoint = slidePlaneOrigin + velocity;

            // We now project the destination point onto the sliding plane.
            const float distPlane = vector_dot(slidePlaneOrigin, slidePlaneNormal);

            // Project on plane
            float t = planeIntersect(slidePlaneNormal, distPlane, destinationPoint, slidePlaneNormal);

            vector_float3 normalizedVelocity = velocity / originalDistance;
            float angle = vector_dot(slidePlaneNormal, normalizedVelocity);
           float frictionCoeff = 0.3;
            if ( fabs(angle) < 0.9) {
                t += 10E-3;
                frictionCoeff = 1.0;
            }

            vector_float3 newDestinationPoint = (destinationPoint + t * slidePlaneNormal) - centerOffset;

            // Advance start position to nearest point without collision.
            velocity = frictionCoeff * (1.0f - closestContact.sweepTestFraction) * originalDistance * vector_normalize(newDestinationPoint- start);
            start = colliderPositionAtContact;
            ++iteration;

            if (vector_length_squared(velocity) <= 10E-3 * 10E-3 || iteration >= maxSlideIteration) {
                replacementPoint = start;
                stop = true;
            }
       } else {
           replacementPoint = start + velocity;
           stop = true;
       }
   }
    _characterNode.simdWorldPosition = replacementPoint - _collisionShapeOffsetFromModel;
}

@end

/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class serves as the app's source of control flow.
 */

#import "AAPLGameController.h"
#import "AAPLCharacter.h"
#import "AAPLOverlay.h"
#import "AAPLMenu.h"

#import <GameController/GameController.h>

#if TARGET_OS_IOS
#import "AAPLControlOverlay.h"
#endif

#import <GameplayKit/GameplayKit.h>
#import "AAPLPlayerComponent.h"
#import "AAPLChaserComponent.h"
#import "AAPLScaredComponent.h"

// Some settings
#define EnableGamePlayKit 1
#define DefaultCameraTransitionDuration 1.0
#define NumberOfFiends 100
#define CameraOrientationSensitivity 0.05f

// the scene and renderer are settable locally
@interface AAPLGameController ()
@property (strong, nonatomic) SCNScene *scene;
@property (strong, nonatomic) id <SCNSceneRenderer> sceneRenderer;
@end

// Particle identifiers
typedef enum
{
    AAPLParticleNameCollect,
    AAPLParticleNameCollectBig,
    AAPLParticleNameKeyApparition,
    AAPLParticleNameEnemyExplosion,
    AAPLParticleNameUnlockDoor,
    AAPLParticleNameCount,
}AAPLParticleName;

// Audio identifiers
typedef enum
{
    AAPLAudioSourceNameCollect,
    AAPLAudioSourceNameCollectBig,
    AAPLAudioSourceNameUnlockDoor,
    AAPLAudioSourceNameHitEnemy,
    AAPLAudioSourceNameCount,
}AAPLAudioSourceName;


@implementation AAPLGameController
{
    // Overlays
    AAPLOverlay *_overlay;
    
    //character
    AAPLCharacter *_character;
    
    //camera and targets
    SCNNode *_cameraNode;
    SCNNode *_lookAtTarget;
    SCNNode *_lastActiveCamera;
    SCNNode *_activeCamera;
    vector_float3 _lastCameraFrontDir;
    BOOL _playingCinematic;
    
    //triggers
    SCNNode *_lastTrigger;
    BOOL _firstTriggerDone;
    
    //enemies
    SCNNode *_enemy1;
    SCNNode *_enemy2;
    
    //friends
    SCNNode *_friends[NumberOfFiends];
    float _friendsSpeed[NumberOfFiends];
    NSUInteger _friendCount;
    BOOL _friendsAreFree;
    
    //collected objects
    NSUInteger _collectedKeys;
    NSUInteger _collectedGems;
    BOOL _keyIsVisible;

    // particles
    NSArray *_particleSystems[AAPLParticleNameCount];
    
    // audio
    SCNAudioSource *_audioSources[AAPLAudioSourceNameCount];
    
    // GameplayKit
    GKScene *_gkScene;
    
    //dPad
    vector_float2 _cameraDirection;
    
    // Game controller
    GCController* _gamePadCurrent;
    GCControllerDirectionPad* _gamePadLeft;
    GCControllerDirectionPad* _gamePadRight;
    
    // update delta time
    NSTimeInterval _lastUpdateTime;
}

#pragma mark -
#pragma mark Setup

- (void)setupGameController {
    if ([[GCController controllers] count]) {
        GCController* controller = [[GCController controllers] firstObject];
        [self registerGameController:controller];
    }
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(handleControllerDidConnectNotification:)
                                               name:GCControllerDidConnectNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                   selector:@selector(handleControllerDidDisconnectNotification:)
                                       name:GCControllerDidDisconnectNotification
                                     object:nil];
}

- (void)setupCharacter
{
    _character = [[AAPLCharacter alloc] initWithScene:self.scene];
    
    // keep a pointer to the physicsWorld from the character because we will need it when updating the character's position
    _character.physicsWorld = self.scene.physicsWorld;
    
    [self.scene.rootNode addChildNode:_character.node];
}

- (void)setupPhysics
{
    //make sure all objects only collide with the character
    [self.scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        node.physicsBody.collisionBitMask = AAPLBitmaskCharacter;
    }];
}


- (void)setupCollisions
{
    // load the collision mesh from another scene and merge into main scene
    SCNScene *collisionScene = [SCNScene sceneNamed:@"Art.scnassets/collision.scn"];
    
    [collisionScene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        child.opacity = 0.0f; // make the collision invisible
        [self.scene.rootNode addChildNode:child];
    }];
}

// the follow camera behavior make the camera to follow the character, with a constant distance, altitude and smoothed motion
- (void)setupFollowCamera:(SCNNode *)cameraNode
{
    // look at "lookAtTarget"
    SCNLookAtConstraint* lookAtConstraint = [SCNLookAtConstraint lookAtConstraintWithTarget:_lookAtTarget];
    lookAtConstraint.gimbalLockEnabled = YES; // keep horizon horizonal
    lookAtConstraint.influenceFactor = 0.07;

    // distance constraints
    SCNDistanceConstraint *follow = [SCNDistanceConstraint distanceConstraintWithTarget:_lookAtTarget];
    
    // configure distance
    const float distance = vector_length(cameraNode.simdPosition);
    follow.minimumDistance = distance;
    follow.maximumDistance = distance;
    
    // configure a constraint to maintain a constant altitude relative to the character
    const float desiredAltitude = fabs(cameraNode.worldPosition.y);
    __weak AAPLGameController* weakSelf = self;

    SCNTransformConstraint *keepAltitude = [SCNTransformConstraint positionConstraintInWorldSpace:YES withBlock:^SCNVector3(SCNNode * _Nonnull node, SCNVector3 position) {
        AAPLGameController* strongSelf = weakSelf;
        if (!strongSelf)
            return position;
        position.y = _character.baseAltitude + desiredAltitude;
        return position;
    }];
    
    // acceleration constraint to smooth the camera motion
    SCNAccelerationConstraint *accelerationConstraint = [SCNAccelerationConstraint accelerationConstraint];
    accelerationConstraint.maximumLinearVelocity = 1500.0;
    accelerationConstraint.maximumLinearAcceleration = 50.0;
    accelerationConstraint.damping = 0.05;
    
    // use a custom constraint to let the user orbit the camera around the character
    
    SCNNode* transformNode = [SCNNode node];
    SCNTransformConstraint* orientationUpdateConstraint = [SCNTransformConstraint transformConstraintInWorldSpace:YES withBlock:^SCNMatrix4(SCNNode * _Nonnull node, SCNMatrix4 transform) {
        AAPLGameController* strongSelf = weakSelf;

        // Slowly update the acceleration constraint influence factor to smoothly reenable the acceleration.
        accelerationConstraint.influenceFactor = MIN(1, accelerationConstraint.influenceFactor + 0.01);

        if (!strongSelf)
            return transform;

        if (strongSelf->_activeCamera != node)
            return transform;

        const vector_float3 targetPosition = strongSelf->_lookAtTarget.presentationNode.simdWorldPosition;
        const vector_float2 cameraDirection = strongSelf->_cameraDirection;
        if (vector_all(cameraDirection == 0)) {
            return transform;
        }

        // Disable the acceleration constraint.
        accelerationConstraint.influenceFactor = 0;

        const vector_float3 characterWorldUp = strongSelf->_character.node.presentationNode.simdWorldUp;

        transformNode.transform = transform;

        const simd_quatf q = simd_mul(
            simd_quaternion(CameraOrientationSensitivity * cameraDirection.x, characterWorldUp),
            simd_quaternion(CameraOrientationSensitivity * cameraDirection.y, transformNode.simdWorldRight));
        [transformNode simdRotateBy:q aroundTarget:targetPosition];
        return transformNode.transform;
    }];
    
    cameraNode.constraints = @[follow, keepAltitude, accelerationConstraint, orientationUpdateConstraint, lookAtConstraint];
}


// the axis aligned behavior look at the character but remains aligned using a specified axis
- (void)setupAxisAlignedCamera:(SCNNode *)cameraNode
{
    const float distance = vector_length(cameraNode.simdPosition);
    const vector_float3 originalAxisDirection = cameraNode.simdWorldFront;
    _lastCameraFrontDir = originalAxisDirection;
    const vector_float3 symetricAxisDirection = {-originalAxisDirection.x, originalAxisDirection.y, -originalAxisDirection.z};
    
    // define a custom constraint for the axis alignment
    __weak AAPLGameController* weakSelf = self;
    SCNTransformConstraint *axisAlignConstraint = [SCNTransformConstraint positionConstraintInWorldSpace:YES withBlock:^SCNVector3(SCNNode * _Nonnull node, SCNVector3 position) {
        AAPLGameController* strongSelf = weakSelf;
        if (!strongSelf)
            return position;

        vector_float3 axisOrigin = _lookAtTarget.presentationNode.simdWorldPosition;
        vector_float3 referenceFrontDirection =
            strongSelf->_activeCamera == node ? _lastCameraFrontDir : strongSelf->_activeCamera.presentationNode.simdWorldFront;
        vector_float3 axis = vector_dot(originalAxisDirection, referenceFrontDirection) > 0 ? originalAxisDirection : symetricAxisDirection;
        vector_float3 constrainedPosition = axisOrigin - distance * axis;
        
        return SCNVector3FromFloat3(constrainedPosition);
    }];
    
    SCNAccelerationConstraint* accelerationConstraint = [SCNAccelerationConstraint accelerationConstraint];
    accelerationConstraint.maximumLinearAcceleration = 20;
    accelerationConstraint.decelerationDistance = .5;
    accelerationConstraint.damping = 0.05;
    
    // look at constraint
    SCNLookAtConstraint* lookAtConstraint = [SCNLookAtConstraint lookAtConstraintWithTarget:_lookAtTarget];
    lookAtConstraint.gimbalLockEnabled = YES; // keep horizon horizontal
    
    cameraNode.constraints = @[axisAlignConstraint, lookAtConstraint, accelerationConstraint];
}

- (void) setupCameraNode:(SCNNode *)node
{
    NSString *cameraName = node.name;
    
    if([cameraName hasPrefix:@"camTrav"]){
        [self setupAxisAlignedCamera:node];
    }
    else if([cameraName hasPrefix:@"camLookAt"]){
        [self setupFollowCamera:node];
    }
}

- (void)setupCamera
{
    //create a node that we will use as the lookAt target
    //it will be placed slighlty above the character
    _lookAtTarget = [SCNNode node];
    
    __weak AAPLGameController* weakSelf = self;
    _lookAtTarget.constraints = @[[SCNTransformConstraint positionConstraintInWorldSpace:YES withBlock:^SCNVector3(SCNNode *node, SCNVector3 position) {
        AAPLGameController* strongSelf = weakSelf;
        if (!strongSelf)
            return position;

        position = strongSelf->_character.node.worldPosition;
        position.y = strongSelf->_character.baseAltitude + 0.5;
        return position;
    }]];
    
    [self.scene.rootNode addChildNode:_lookAtTarget];
    
    [self.scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if(node.camera){
            [self setupCameraNode:node];
        }
    }];
    
    // create our main camera
    // the one we will use during the game
    _cameraNode = [SCNNode node];
    _cameraNode.camera = [SCNCamera camera];
    _cameraNode.name = @"mainCamera";
    _cameraNode.camera.zNear = 0.1;
    [self.scene.rootNode addChildNode:_cameraNode];
    
    // start with this camera
    [self setActiveCamera:@"camLookAt_cameraGame" animationDuration:0.0];
}

- (void)setupEnemies
{
#if EnableGamePlayKit
    _gkScene = [GKScene sceneWithFileNamed:@"Art.scnassets/scene.gks" rootNode:_scene];
#endif
    
    _enemy1 = [_scene.rootNode childNodeWithName:@"enemy1" recursively:YES];
    _enemy2 = [_scene.rootNode childNodeWithName:@"enemy2" recursively:YES];
    
    // animate enemies (move up and down)
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fromValue = [NSValue valueWithSCNVector3:SCNVector3Make(0, 0.1, 0)];
    anim.toValue = [NSValue valueWithSCNVector3:SCNVector3Make(0, -0.1, 0)];
    anim.additive = YES;
    anim.repeatCount = INFINITY;
    anim.autoreverses = YES;
    anim.duration = 1.2;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [_enemy1 addAnimation:anim forKey:nil];
    [_enemy2 addAnimation:anim forKey:nil];
    
    // setup GameplayKit
#if EnableGamePlayKit
    GKEntity *playerEntity = [GKEntity entity];
    [_gkScene addEntity:playerEntity];
    [playerEntity addComponent:[GKSCNNodeComponent componentWithNode:_character.node]];
    AAPLPlayerComponent *playerComponent = [[AAPLPlayerComponent alloc] init];
    playerComponent.autoMoveNode = NO;
    playerComponent.character = _character;
    [playerEntity addComponent:playerComponent];
    [playerComponent positionAgentFromNode];
    
    for (GKEntity *entity in _gkScene.entities)
    {
        AAPLChaserComponent *chaser = (AAPLChaserComponent *)[entity componentForClass:AAPLChaserComponent.class];
        if (chaser){
            chaser.player = playerComponent;
            [chaser positionAgentFromNode];
        }
        
        AAPLScaredComponent *scared = (AAPLScaredComponent *)[entity componentForClass:AAPLScaredComponent.class];
        if (scared){
            scared.player = playerComponent;
            [scared positionAgentFromNode];
        }
    }
#endif
    
}

- (NSArray *)loadParticleSystemsAtPath:(NSString *)path
{
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSString *fileName = [path lastPathComponent];
    NSString *ext = [path pathExtension];
    if([ext isEqualToString:@"scnp"]){
        return @[[SCNParticleSystem particleSystemNamed:fileName inDirectory:directory]];
    }
    else{
        NSMutableArray *particles = [NSMutableArray array];
        SCNScene *scene = [SCNScene sceneNamed:fileName inDirectory:directory options:nil];
        [scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
            if(node.particleSystems){
                [particles addObjectsFromArray:node.particleSystems];
            }
        }];
        
        
        return particles;
    }
                 
     return nil;
}

- (void)setupParticleSystems
{
    _particleSystems[AAPLParticleNameCollect] = [self loadParticleSystemsAtPath:@"Art.scnassets/particles/collect.scnp"];
    _particleSystems[AAPLParticleNameCollectBig] = [self loadParticleSystemsAtPath:@"Art.scnassets/particles/key_apparition.scn"];
    _particleSystems[AAPLParticleNameEnemyExplosion] = [self loadParticleSystemsAtPath:@"Art.scnassets/particles/enemy_explosion.scn"];
    _particleSystems[AAPLParticleNameKeyApparition] = [self loadParticleSystemsAtPath:@"Art.scnassets/particles/key_apparition.scn"];
    _particleSystems[AAPLParticleNameUnlockDoor] = [self loadParticleSystemsAtPath:@"Art.scnassets/particles/unlock_door.scn"];
}

- (void)setupPlatforms
{
#define PLATFORM_MOVE_OFFSET 1.5
#define PLATFORM_MOVE_SPEED  0.5
    
    __block float alternate = 1;
    
    // animate the platforms
    [self.scene.rootNode enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        if([node.name isEqualToString:@"mobilePlatform"] && node.childNodes.count > 0){
            node.position = SCNVector3Make(node.position.x - (alternate * PLATFORM_MOVE_OFFSET/2), node.position.y, node.position.z);
            
            SCNAction *moveAction = [SCNAction moveBy:SCNVector3Make(alternate * PLATFORM_MOVE_OFFSET, 0, 0) duration:1/PLATFORM_MOVE_SPEED];
            moveAction.timingMode = SCNActionTimingModeEaseInEaseOut;
            [node runAction:[SCNAction repeatActionForever:[SCNAction sequence:@[moveAction, moveAction.reversedAction]]]];
            
            alternate = -alternate; // alternate movement of platforms to unsynchronize them
            
            // tweak platform particles
            [node enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
                if([child.name isEqualToString:@"particles_platform"]){
                    child.particleSystems[0].orientationDirection = SCNVector3Make(0, 1, 0);
                }
            }];
        }
    }];
}



#pragma mark -
#pragma mark Camera transitions


// transition to the specified camera
// this method will reparent the main camera under the camera named "cameraNamed"
// and trigger the animation to smoothly move from the current position to the new position
- (void)setActiveCamera:(NSString *)cameraName animationDuration:(CFTimeInterval)duration
{
    SCNNode *camera = [_scene.rootNode childNodeWithName:cameraName recursively:YES];
    
    if(!camera || _activeCamera == camera)
        return;
    
    _lastActiveCamera = _activeCamera;
    _lastCameraFrontDir = _activeCamera.presentationNode.simdWorldFront;
    _activeCamera = camera;
    
    // save old transform in world space
    SCNMatrix4 oldTransform = _cameraNode.presentationNode.worldTransform;
    
    // re-parent
    [camera addChildNode:_cameraNode];
    
    // compute the old transform relative to our new parent node (yeah this is the complex part)
    SCNMatrix4 parentTransform = camera.presentationNode.worldTransform;
    SCNMatrix4 parentInv = SCNMatrix4Invert(parentTransform);
    
    // with this new transform our position is unchanged in workd space (i.e we did re-parent but didn't move).
    _cameraNode.transform = SCNMatrix4Mult(oldTransform, parentInv);
    
    // now animate the transform to identity to smoothly move to the new desired position
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:duration];
    [SCNTransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    _cameraNode.transform = SCNMatrix4Identity; // anim
    
    // use the parameters described by the target camera and that was configured by the artist
    SCNCamera *cameraTemplate = camera.camera;
    if(cameraTemplate){
        _cameraNode.camera.fieldOfView = cameraTemplate.fieldOfView;
        _cameraNode.camera.wantsDepthOfField = cameraTemplate.wantsDepthOfField;
        _cameraNode.camera.sensorHeight = cameraTemplate.sensorHeight;
        _cameraNode.camera.fStop = cameraTemplate.fStop;
        _cameraNode.camera.focusDistance = cameraTemplate.focusDistance;
        _cameraNode.camera.bloomIntensity = cameraTemplate.bloomIntensity;
        _cameraNode.camera.bloomThreshold = cameraTemplate.bloomThreshold;
        _cameraNode.camera.bloomBlurRadius = cameraTemplate.bloomBlurRadius;
        _cameraNode.camera.wantsHDR = cameraTemplate.wantsHDR;
        _cameraNode.camera.wantsExposureAdaptation = cameraTemplate.wantsExposureAdaptation;
        _cameraNode.camera.vignettingPower = cameraTemplate.vignettingPower;
        _cameraNode.camera.vignettingIntensity = cameraTemplate.vignettingIntensity;
    }
    
    [SCNTransaction commit];
}

- (void)setActiveCamera:(NSString *)cameraName
{
    [self setActiveCamera:cameraName animationDuration:DefaultCameraTransitionDuration];
}


#pragma mark -
#pragma mark Audio

- (void)playSound:(AAPLAudioSourceName)audioName
{
    [self.scene.rootNode addAudioPlayer:[SCNAudioPlayer audioPlayerWithSource:_audioSources[audioName]]];
}

- (void)setupAudio
{
    // Get an arbitrary node to attach the sounds to.
    SCNNode *node = self.scene.rootNode;
    
    // ambience
    SCNAudioSource *audioSource = [SCNAudioSource audioSourceNamed:@"audio/ambience.mp3"];
    audioSource.loops = YES;
    audioSource.volume = 0.8;
    audioSource.positional = NO;
    audioSource.shouldStream = YES;
    [node addAudioPlayer:[SCNAudioPlayer audioPlayerWithSource:audioSource]];
    
    // volcano
    SCNNode *volcanoNode = [self.scene.rootNode childNodeWithName:@"particles_volcanoSmoke_v2" recursively:YES];
    audioSource = [SCNAudioSource audioSourceNamed:@"audio/volcano.mp3"];
    audioSource.loops = YES;
    audioSource.volume = 5.0;
    [volcanoNode addAudioPlayer:[SCNAudioPlayer audioPlayerWithSource:audioSource]];
    
    
    // other sounds
    _audioSources[AAPLAudioSourceNameCollect] = [SCNAudioSource audioSourceNamed:@"audio/collect.mp3"];
    _audioSources[AAPLAudioSourceNameCollectBig] = [SCNAudioSource audioSourceNamed:@"audio/collectBig.mp3"];
    _audioSources[AAPLAudioSourceNameUnlockDoor] = [SCNAudioSource audioSourceNamed:@"audio/unlockTheDoor.m4a"];
    _audioSources[AAPLAudioSourceNameHitEnemy] = [SCNAudioSource audioSourceNamed:@"audio/hitEnemy.wav"];
    
    // adjust volumes
    _audioSources[AAPLAudioSourceNameUnlockDoor].positional = NO;
    _audioSources[AAPLAudioSourceNameCollect].positional = NO;
    _audioSources[AAPLAudioSourceNameCollectBig].positional = NO;
    _audioSources[AAPLAudioSourceNameHitEnemy].positional = NO;
    
    _audioSources[AAPLAudioSourceNameUnlockDoor].volume = 0.5;
    _audioSources[AAPLAudioSourceNameCollect].volume = 4.0;
    _audioSources[AAPLAudioSourceNameCollectBig].volume = 4.0;
}

#pragma mark -
#pragma mark Init

- (instancetype)initWithSCNView:(SCNView *)scnView {
    self = [super init];
    if (self) {
        self.sceneRenderer = scnView;
        self.sceneRenderer.delegate = self;
        
        // Uncomment to show statistics such as fps and timing information
        // scnView.showsStatistics = YES;
        
        // setup overlay
        _overlay = [AAPLOverlay sceneWithSize:scnView.bounds.size];
        [_overlay setupWithController:self];
        scnView.overlaySKScene = _overlay;
        
        //load the main scene
        self.scene = [SCNScene sceneNamed:@"Art.scnassets/scene.scn"];
        
        //setup physics
        [self setupPhysics];
        
        //setup collisions
        [self setupCollisions];
        
        //load the character
        [self setupCharacter];

        //setup enemies
        [self setupEnemies];
        
        //setup friends
        [self addFriends:3];
        
        //setup platforms
        [self setupPlatforms];
        
        //setup particles
        [self setupParticleSystems];
        
        //configure the lighting
        SCNLight *light = [self.scene.rootNode childNodeWithName:@"DirectLight" recursively:YES].light;
        light.shadowCascadeCount = 3; // turn on cascade shadows
        light.shadowCascadeSplittingFactor = 0.5;
        light.maximumShadowDistance = 20.0;
        light.shadowMapSize = CGSizeMake(512,512);
        
        //setup camera
        [self setupCamera];
        
        //setup game controller
        [self setupGameController];
        
        //configure quality
        [self configureRenderingQuality:scnView];
        
        //assign the scene to the view
        self.sceneRenderer.scene = self.scene;
        
        //select the point of view to use
        self.sceneRenderer.pointOfView = _cameraNode;
        
        //register ourself as the physics contact delegate to receive contact notifications
        self.sceneRenderer.scene.physicsWorld.contactDelegate = (id <SCNPhysicsContactDelegate>) self;
        
        //setup audio
        [self setupAudio];
        
        //preload everything
        [self.sceneRenderer prepareObject:self.scene shouldAbortBlock:nil];
    }
    return self;
}

- (void)resetPlayerPosition {
    [_character resetCharacterPosition];
}

#pragma mark - cinematic

- (void)startCinematic
{
    _playingCinematic = YES;
    _character.node.paused = YES;
}

- (void)stopCinematic
{
    _playingCinematic = NO;
    _character.node.paused = NO;
}


#pragma mark - particles

- (NSArray *)particleSystemsWithName:(AAPLParticleName)name
{
    return _particleSystems[name];
}

- (void)addParticlesWithName:(AAPLParticleName)name withTransform:(SCNMatrix4)transform
{
    NSArray *particles = [self particleSystemsWithName:name];
    for(SCNParticleSystem *ps in particles){
        [self.scene addParticleSystem:ps withTransform:transform];
    }
}

#pragma mark - Triggers

// "triggers" are triggered when a character enter a box with the collision mask AAPLBitmaskTrigger

- (void)execTrigger:(SCNNode *)triggerNode animationDuration:(CFTimeInterval)duration
{
    //exec trigger
    if([triggerNode.name hasPrefix:@"trigCam_"]){
        NSString *cameraName = [triggerNode.name substringFromIndex:8];
        //NSLog(@"switch to camera :%@", cameraName);
        [self setActiveCamera:cameraName animationDuration:duration];
    }
    
    //action
    if([triggerNode.name hasPrefix:@"trigAction_"]){
        if(_collectedKeys > 0){
            NSString *actionName = [triggerNode.name substringFromIndex:11];
            //NSLog(@"trigger action :%@", actionName);
        
            if([actionName isEqualToString:@"unlockDoor"]){
                [self unlockDoor];
            }
        }
    }
}

- (void)trigger:(SCNNode *)triggerNode
{
    if(_playingCinematic)
        return;
    
    if(_lastTrigger != triggerNode){
        _lastTrigger = triggerNode;
        
        // the very first trigger should not animate (initial camera position)
        [self execTrigger:triggerNode animationDuration:_firstTriggerDone ? DefaultCameraTransitionDuration : 0];
        _firstTriggerDone = YES;
    }
}

#pragma mark - Friends

- (void)updateFriendsWithDeltaTime:(CFTimeInterval)deltaTime
{
    float pathCurve = 0.4f;
    
    // update pandas
    for (NSInteger i = 0; i < _friendCount; i++) {
        SCNNode *friend = _friends[i];
        
        vector_float3 pos = SCNVector3ToFloat3(friend.position);
        float offsetx = pos.x - sinf(pathCurve * pos.z);
        
        pos.z += _friendsSpeed[i] * deltaTime * 0.5;
        pos.x = sinf(pathCurve * pos.z) + offsetx;
        
        friend.position = SCNVector3FromFloat3(pos);
        
        [self ensureNoPenetrationOfIndex:i];
    }
}

- (void)animateFriends
{
    //animations
    SCNAnimationPlayer *walkAnimation = [AAPLCharacter loadAnimationFromSceneNamed:@"Art.scnassets/character/max_walk.scn"];

    [SCNTransaction begin];

    for(int i=0; i < _friendCount; i++){
        //unsynchronize
        walkAnimation = [walkAnimation copy];
        walkAnimation.speed = _friendsSpeed[i];
        [_friends[i] addAnimationPlayer:walkAnimation forKey:@"walk"];
        [walkAnimation play];
    }

    [SCNTransaction commit];
}

- (void)addFriends:(NSUInteger)count
{
    if(count + _friendCount > NumberOfFiends){
        count = NumberOfFiends - _friendCount;
    }
    
    SCNScene *friendScene = [SCNScene sceneNamed:@"Art.scnassets/character/max.scn"];
    SCNNode *friendModel = [friendScene.rootNode childNodeWithName:@"Max_rootNode" recursively:YES];
    friendModel.name = @"friend";

    // prepare 3 different geometries with different colors
    SCNGeometry *geometries[3];
    SCNNode *geometryNode = [friendModel childNodeWithName:@"Max" recursively:YES];
    geometryNode.geometry.firstMaterial.diffuse.intensity = 0.5;

    geometries[0] = [geometryNode.geometry copy];
    geometries[1] = [geometryNode.geometry copy];
    geometries[2] = [geometryNode.geometry copy];

    geometries[0].firstMaterial = [geometries[0].firstMaterial copy];
    geometryNode.geometry.firstMaterial.diffuse.contents = @"Art.scnassets/character/max_diffuseB.png";

    geometries[1].firstMaterial = [geometries[1].firstMaterial copy];
    geometryNode.geometry.firstMaterial.diffuse.contents = @"Art.scnassets/character/max_diffuseC.png";

    geometries[2].firstMaterial = [geometries[2].firstMaterial copy];
    geometryNode.geometry.firstMaterial.diffuse.contents = @"Art.scnassets/character/max_diffuseD.png";

    //remove physics from our friends
    [friendModel enumerateHierarchyUsingBlock:^(SCNNode * _Nonnull node, BOOL * _Nonnull stop) {
        node.physicsBody = nil;
    }];
    
    //todo: use a marker
    SCNVector3 friendPosition = SCNVector3Make(-5.84, -0.75, 3.354);
#define FRIEND_AREA_WIDTH 1.4
#define FRIEND_AREA_LENGTH 5.0
    
    // group them
    SCNNode *friends = [self.scene.rootNode childNodeWithName:@"friends" recursively:NO];
    if(!friends){
        friends = [SCNNode node];
        friends.name = @"friends";
        [self.scene.rootNode addChildNode:friends];
    }
    
    //animations
    SCNAnimationPlayer *idleAnimation = [AAPLCharacter loadAnimationFromSceneNamed:@"Art.scnassets/character/max_idle.scn"];

    for(int i=0; i < count; i++){
        SCNNode* friend = [friendModel clone];

        //replace texture
        int textureIndex = (int)(3.0 * (rand()/(float)RAND_MAX));
        SCNNode *geometryNode = [friend childNodeWithName:@"Max" recursively:YES];
        geometryNode.geometry = geometries[textureIndex];

        //place our friend
        friend.position = SCNVector3Make(friendPosition.x + (1.4 * (rand()/(float)RAND_MAX)-0.5),friendPosition.y, friendPosition.z - (FRIEND_AREA_LENGTH * (rand()/(float)RAND_MAX)));
        
        //unsynchronize
        idleAnimation = [idleAnimation copy];
        idleAnimation.speed = 1.5 + 1.5 * rand()/(float)RAND_MAX;
        [friend addAnimationPlayer:idleAnimation forKey:@"idle"];
        [idleAnimation play];
        
        [friends addChildNode:friend];
        
        _friendsSpeed[_friendCount] = idleAnimation.speed;
        _friends[_friendCount++] = friend;
    }
    
    
    for (NSInteger i = 0; i < _friendCount; i++) {
        [self ensureNoPenetrationOfIndex:i];
    }
}

// iterates on every friend and move them if they intersect friend at index i
- (void)ensureNoPenetrationOfIndex:(NSInteger)i
{
    vector_float3 pos = SCNVector3ToFloat3(_friends[i].position);
    
    // ensure no penetration
    float pandaRadius = 0.15f;
    float pandaDiameter = pandaRadius * 2.f;
    for (NSInteger j = 0; j < _friendCount; ++j) {
        if (j == i)
            continue;
        if (!_friends[j])
            continue;
        
        vector_float3 otherPos = SCNVector3ToFloat3(_friends[j].position);
        vector_float3 v = otherPos - pos;
        float dist = vector_length(v);
        if (dist < pandaDiameter) { // penetration
            float pen = pandaDiameter - dist;
            pos -= vector_normalize(v) * pen;
        }
        
    }
    
    //ensure within the box X[-6.662 -4.8] Z<3.354
    if(_friends[i].position.z <= 3.354){
        pos.x = MAX(pos.x, -6.662);
        pos.x = MIN(pos.x, -4.8);
    }
    
    _friends[i].position = SCNVector3FromFloat3(pos);
}


#pragma mark - Game actions

- (void)unlockDoor
{
    if(_friendsAreFree) //already unlocked
        return;
    
    [self startCinematic]; //pause the scene
    
    //play sound
    [self playSound:AAPLAudioSourceNameUnlockDoor];
    
    //cinematic02
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.0];
    [SCNTransaction setCompletionBlock:^{
        //trigger particles
        SCNNode *door = [self.scene.rootNode childNodeWithName:@"door" recursively:YES];
        SCNNode *particle_door = [self.scene.rootNode childNodeWithName:@"particles_door" recursively:YES];
        [self addParticlesWithName:AAPLParticleNameUnlockDoor withTransform:particle_door.worldTransform];
        
        //audio
        [self playSound:AAPLAudioSourceNameCollectBig];
        
        //add friends
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.0];
        [self addFriends:NumberOfFiends];
        [SCNTransaction commit];
        
        //open the door
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.0];
        [SCNTransaction setCompletionBlock:^{
            //animate characters
            [self animateFriends];
            
            // update state
            _friendsAreFree = YES;
            
            // show end screen
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showEndScreen];
            });
            
            // this is the END!
        }];
        
        door.opacity = 0.0;
        [SCNTransaction commit];
        
    }];
    
    // change the point of view
    [self setActiveCamera:@"CameraCinematic02" animationDuration:1.0];
    
    [SCNTransaction commit];
}

- (void)showKey
{
    _keyIsVisible = YES;
    
    // get the key node
    SCNNode *key = [self.scene.rootNode childNodeWithName:@"key" recursively:YES];
    
    //sound fx
    [self playSound:AAPLAudioSourceNameCollectBig];
    
    //particles
    [self addParticlesWithName:AAPLParticleNameKeyApparition withTransform:key.worldTransform];
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:1.0];
    [SCNTransaction setCompletionBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self keyDidAppear];
        });
    }];
    
    key.opacity = 1.0; // show the key
    
    [SCNTransaction commit];
}


- (void)keyDidAppear
{
    [self execTrigger:_lastTrigger animationDuration:0.75]; //revert to previous camera
    [self stopCinematic];
}

- (void)keyShouldAppear
{
    [self startCinematic];
    
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.0];
    [SCNTransaction setCompletionBlock:^{
        [self showKey];
    }];
    
    [self setActiveCamera:@"CameraCinematic01" animationDuration:3.0];
    
    [SCNTransaction commit];
}


- (void)collect:(SCNNode *)collectable
{
    if(collectable.physicsBody != nil){
        
        //the Key
        if([collectable.name isEqualToString:@"key"]){
            if(!_keyIsVisible){ //key not visible yet
                return;
            }
            
            // play sound
            [self playSound:AAPLAudioSourceNameCollect];
            [_overlay didCollectKey];
            
            _collectedKeys++;
        }
        
        //the gems
        else if([collectable.name isEqualToString:@"CollectableBig"]){
            _collectedGems++;
            
            // play sound
            [self playSound:AAPLAudioSourceNameCollect];
            
            // update the overlay
            [_overlay setCollectedGemsCount:_collectedGems];
            
            if(_collectedGems == 1) {
                //we collect a gem, show the key after 1 second
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self keyShouldAppear];
                });
            }
        }
        
        collectable.physicsBody = nil; //not collectable anymore
        
        // particles
        [self addParticlesWithName:AAPLParticleNameKeyApparition withTransform:collectable.worldTransform];
        
        [collectable removeFromParentNode];
    }
}

#pragma mark - Controlling the character

- (void)controllerJump:(BOOL)controllerJump
{
    _character.jump = controllerJump;
}

- (void)controllerAttack
{
    if (!_character.isAttacking) {
        [_character attack];
    }
}

- (void)setCharacterDirection:(vector_float2)characterDirection
{
    float l = vector_length(characterDirection);
    if( l > 1.0f ) {
        characterDirection = characterDirection / l;
    }
    _character.direction = characterDirection;
}

- (vector_float2)characterDirection
{
    return _character.direction;
}

- (vector_float2)cameraDirection {
    return _cameraDirection;
}

- (void)setCameraDirection:(vector_float2)direction {
    float l = vector_length(direction);
    if( l > 1.0f ) {
        direction = direction / l;
    }
    direction.y = 0;
    _cameraDirection = direction;
}

#pragma mark - Update

- (void)renderer:(id <SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    // compute delta time
    if (_lastUpdateTime == 0)
        _lastUpdateTime = time;
    NSTimeInterval deltaTime = time - _lastUpdateTime;
    _lastUpdateTime = time;
    
    // Update Friends
    if(_friendsAreFree)
        [self updateFriendsWithDeltaTime:deltaTime];
    
    // stop here if cinematic
    if(_playingCinematic == YES)
        return;

    // update characters
    [_character updateAtTime:time withRenderer:renderer];
    
    
#if EnableGamePlayKit
    // update enemies
    for (GKEntity *entity in _gkScene.entities) {
        [entity updateWithDeltaTime:deltaTime];
    }
#endif
}

#pragma mark - contact delegate

- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact
{
    // triggers
    if(contact.nodeA.physicsBody.categoryBitMask == AAPLBitmaskTrigger){
        [self trigger:contact.nodeA];
    }
    if(contact.nodeB.physicsBody.categoryBitMask == AAPLBitmaskTrigger){
        [self trigger:contact.nodeB];
    }
    
    // collectables
    if(contact.nodeA.physicsBody.categoryBitMask == AAPLBitmaskCollectable){
        [self collect:contact.nodeA];
    }
    if(contact.nodeB.physicsBody.categoryBitMask == AAPLBitmaskCollectable){
        [self collect:contact.nodeB];
    }
}

#pragma mark - Congratulating the Player

- (void)showEndScreen {
    // Play the congrat sound.
    SCNAudioSource *victoryMusic = [SCNAudioSource audioSourceNamed:@"audio/Music_victory.mp3"];
    victoryMusic.volume = 0.5;
    
    [self.scene.rootNode addAudioPlayer:[SCNAudioPlayer audioPlayerWithSource:victoryMusic]];
    
    [_overlay showEndScreen];
}


#pragma mark - Configure rendering quality

- (void)turnOffPhysicallyBasedMaterials
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        for(SCNMaterial *material in child.geometry.materials){
            material.lightingModelName = SCNLightingModelBlinn;
            
            material.roughness.contents = nil;
            material.metalness.contents = nil;
        }
    }];
    
    // IBL is useless...
    self.scene.lightingEnvironment.contents = nil;
    
    //... so add an ambient light to compensate
    SCNNode *ambient = [SCNNode node];
    ambient.light = [SCNLight light];
    ambient.light.type = SCNLightTypeAmbient;
    ambient.light.intensity = 600;
    
    [self.scene.rootNode addChildNode:ambient];
}

- (void)turnOffDepthOfField
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        child.camera.wantsDepthOfField = false;
    }];
}

- (void)turnOffHDR
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        child.camera.wantsHDR = false;
    }];
}

- (void)turnOffSoftShadows
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        child.light.shadowSampleCount = MIN(child.light.shadowSampleCount, 1);
    }];
}

- (void)turnOffCascadeShadows
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        child.light.shadowCascadeCount = 0;
        child.light.shadowMapSize = CGSizeMake(1024, 1024);
    }];
}

- (void)turnOffPostProcess
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        child.camera.bloomIntensity = 0;
        child.camera.wantsExposureAdaptation = NO;
        child.camera.vignettingIntensity = 0;
    }];
}

- (void)turnOffShadow
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        child.light.castsShadow = NO;
    }];
}

- (void)turnOffOverlays
{
    self.sceneRenderer.overlaySKScene = nil;
}

- (void)turnOffDiffuse
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        for(SCNMaterial *material in child.geometry.materials){
            // material.lightingModelName = SCNLightingModelBlinn;
            material.diffuse.contents = [SCNColor whiteColor];
        }
    }];
}


- (void)turnOffNormalMaps
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        for(SCNMaterial *material in child.geometry.materials){
            material.normal.contents = [SCNColor blackColor];
        }
    }];
}

- (void)turnOffLightMaps
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        for(SCNMaterial *material in child.geometry.materials){
            material.selfIllumination.contents = [SCNColor blackColor];
            material.ambientOcclusion.contents = [SCNColor whiteColor];
        }
    }];
}

- (void)turnOffSpecularMaps
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        for(SCNMaterial *material in child.geometry.materials){
            material.specular.contents = [SCNColor blackColor];
        }
    }];
}

- (void)turnOffVertexShaderModifiers
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        NSMutableDictionary *sm = [child.geometry.shaderModifiers mutableCopy];
        [sm setValue:nil forKey:SCNShaderModifierEntryPointGeometry];
        child.geometry.shaderModifiers = sm;
        
        for(SCNMaterial *material in child.geometry.materials){
            NSMutableDictionary *sm = [material.shaderModifiers mutableCopy];
            [sm setValue:nil forKey:SCNShaderModifierEntryPointGeometry];
            material.shaderModifiers = sm;
        }
    }];
}

- (void)turnOffLighting
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        if(child.light && child.light.type != SCNLightTypeAmbient)
            child.hidden = YES;
    }];
}

- (void)turnOffEXRForMaterialProperty:(SCNMaterialProperty *)property
{
    if([property.contents isKindOfClass:NSString.class]){
        NSString *path = property.contents;
        
        if([path.pathExtension isEqualToString:@"exr"]){
            path = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
            property.contents = path;
        }
    }
}

- (void)turnOffEXR
{
    [self turnOffEXRForMaterialProperty:self.scene.background];
    [self turnOffEXRForMaterialProperty:self.scene.lightingEnvironment];
    
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        for(SCNMaterial *material in child.geometry.materials){
            [self turnOffEXRForMaterialProperty:material.selfIllumination];
        }
    }];
}

- (void)turnOffShaderModifiers
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        child.geometry.shaderModifiers = nil;
        for(SCNMaterial *material in child.geometry.materials){
            material.shaderModifiers = nil;
        }
    }];
}

- (void)turnOffVegetation
{
    [self.scene.rootNode enumerateChildNodesUsingBlock:^(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        if ([child.geometry.firstMaterial.name hasPrefix:@"plante"]){
            child.hidden = YES;
        }
    }];
}

- (void)configureRenderingQuality:(SCNView*)scnView
{
    BOOL isLowPowerDevice = false;
    
#if TARGET_OS_TV
    isLowPowerDevice = YES;
#elif !TARGET_OS_IPHONE
    isLowPowerDevice = [scnView.device isLowPower];
#endif
    
    if(isLowPowerDevice){
        [self turnOffEXR]; //tvOS doesn't support exr maps
        [self turnOffNormalMaps];
        [self turnOffSpecularMaps];
        [self turnOffHDR];
        [self turnOffDepthOfField];
        [self turnOffSoftShadows];
        [self turnOffPostProcess];
        [self turnOffOverlays];
        [self turnOffVertexShaderModifiers];
        [self turnOffVegetation];        
        scnView.preferredFramesPerSecond = 30.0;
    }
}

#pragma mark - Debug menu

- (void)fStopChanged:(CGFloat)value
{
    self.sceneRenderer.pointOfView.camera.fStop = value;
}

- (void)focusDistanceChanged:(CGFloat)value
{
    self.sceneRenderer.pointOfView.camera.focusDistance = value;
}

- (void)debugMenuSelectCameraAtIndex:(NSUInteger)index
{
    if(index == 0)
    {
        SCNNode *key = [self.scene.rootNode childNodeWithName:@"key" recursively:YES];
        key.opacity = 1.0;
    }
    [self setActiveCamera:[NSString stringWithFormat:@"CameraDof%lu",(unsigned long)index]];
}

#pragma mark - GameController

- (void)handleControllerDidConnectNotification:(NSNotification*)notification {
    if (_gamePadCurrent)
        return;
    
    GCController *gameController = notification.object;
    [self registerGameController:gameController];
}

- (void)handleControllerDidDisconnectNotification:(NSNotification*)notification {
    GCController *gameController = notification.object;
    if (gameController != _gamePadCurrent)
        return;
    [self unregisterGameController];
    for (GCController* controller in [GCController controllers]) {
        if (gameController != controller && controller.extendedGamepad)
            [self registerGameController:controller];
    }
}

- (void)registerGameController:(GCController *)gameController {
    
    GCControllerButtonInput *buttonA = nil;
    GCControllerButtonInput *buttonB = nil;
    
    if( gameController.extendedGamepad != nil ) {
        _gamePadLeft = gameController.extendedGamepad.leftThumbstick;
        _gamePadRight = gameController.extendedGamepad.rightThumbstick;
        buttonA = gameController.extendedGamepad.buttonA;
        buttonB = gameController.extendedGamepad.buttonB;
    } else if( gameController.gamepad != nil ) {
        _gamePadLeft = gameController.gamepad.dpad;
        buttonA = gameController.gamepad.buttonA;
        buttonB = gameController.gamepad.buttonB;
    } else if( gameController.microGamepad != nil ) {
        _gamePadLeft = gameController.microGamepad.dpad;
        buttonA = gameController.microGamepad.buttonA;
        buttonB = gameController.microGamepad.buttonX;
    }

    __weak AAPLGameController* weakController = self;
    [_gamePadLeft setValueChangedHandler:^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        [weakController setCharacterDirection:(vector_float2){xValue, -yValue}];
    }];

    [_gamePadRight setValueChangedHandler:^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        [weakController setCameraDirection:(vector_float2){-xValue, yValue}];
    }];

    [buttonA setValueChangedHandler:^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [weakController controllerJump:pressed];
    }];

    [buttonB setValueChangedHandler:^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        if (pressed) {
            [weakController controllerAttack];
        }
    }];

#if TARGET_OS_IOS
    if (_gamePadLeft && _gamePadRight) {
        [_overlay hideVirtualPad];
    }
#endif
}

- (void)unregisterGameController {
    _gamePadLeft = nil;
    _gamePadRight = nil;
    _gamePadCurrent = nil;
#if TARGET_OS_IOS
    [_overlay showVirtualPad];
#endif
}

#if TARGET_OS_IOS

#pragma mark - AAPLPadOverlayDelegate

- (void)padOverlayVirtualStickInteractionDidStart:(AAPLPadOverlay*)padNode {
    if (padNode == _overlay.controlOverlay.leftPad) {
        [self setCharacterDirection:(vector_float2){padNode.stickPosition.x, -padNode.stickPosition.y}];
    }
    if (padNode == _overlay.controlOverlay.rightPad) {
        [self setCameraDirection:(vector_float2){-padNode.stickPosition.x, padNode.stickPosition.y}];
    }
}

- (void)padOverlayVirtualStickInteractionDidChange:(AAPLPadOverlay*)padNode {
    if (padNode == _overlay.controlOverlay.leftPad) {
        [self setCharacterDirection:(vector_float2){padNode.stickPosition.x, -padNode.stickPosition.y}];
    }
    if (padNode == _overlay.controlOverlay.rightPad) {
        [self setCameraDirection:(vector_float2){-padNode.stickPosition.x, padNode.stickPosition.y}];
    }
}

- (void)padOverlayVirtualStickInteractionDidEnd:(AAPLPadOverlay*)padNode {
    if (padNode == _overlay.controlOverlay.leftPad) {
        [self setCharacterDirection:(vector_float2){0, 0}];
    }
    if (padNode == _overlay.controlOverlay.rightPad) {
        [self setCameraDirection:(vector_float2){0, 0}];
    }
}

- (void)willPressButtonOverlay:(AAPLButtonOverlay*_Nonnull)button {
    if (button == _overlay.controlOverlay.buttonA) {
        [self controllerJump:YES];
    }
    if (button == _overlay.controlOverlay.buttonB) {
        [self controllerAttack];
    }
}

- (void)didPressButtonOverlay:(AAPLButtonOverlay*_Nonnull)button {
    if (button == _overlay.controlOverlay.buttonA) {
        [self controllerJump:NO];
    }
}

#endif // TARGET_OS_IOS

#if TARGET_OS_TV
// Stubs for missing delegate callabacks
- (void) padOverlayVirtualStickInteractionDidChange:(AAPLPadOverlay *)padNode {
    
}

- (void) padOverlayVirtualStickInteractionDidEnd:(AAPLPadOverlay *)padNode {
    
}

- (void) padOverlayVirtualStickInteractionDidStart:(AAPLPadOverlay *)padNode {
    
}

- (void) didPressButtonOverlay:(nonnull AAPLButtonOverlay *)button {
    
}

- (void) willPressButtonOverlay:(nonnull AAPLButtonOverlay *)button {
    
}
#endif

@end


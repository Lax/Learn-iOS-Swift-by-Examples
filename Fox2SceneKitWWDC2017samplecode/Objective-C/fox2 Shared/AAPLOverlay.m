/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the 2D overlay (score).
 */

@import SceneKit;

#import "AAPLOverlay.h"
#import "AAPLGameController.h"
#import "AAPLMenu.h"

#if TARGET_OS_IOS
#import "AAPLControlOverlay.h"
#import "AAPLButtonOverlay.h"
#endif

@implementation AAPLOverlay {
    SKNode *_overlayNode;
    SKNode *_congratulationsGroupNode;
    SKSpriteNode *_collectedKeySprite;
    NSMutableArray<SKSpriteNode *> *_collectedGemsSprites;
    NSUInteger _collectedGemCount;
    
    // demo UI
    AAPLMenu *_demoMenu;

#if TARGET_OS_IOS
    AAPLControlOverlay* _controlOverlay;
#endif
}

#pragma mark - Initialization

- (void)layout2DOverlay {
    _overlayNode.position = CGPointMake(0.0, self.size.height);
    
    _congratulationsGroupNode.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
    
    _congratulationsGroupNode.xScale = 1.0;
    _congratulationsGroupNode.yScale = 1.0;
    CGRect currentBbox = [_congratulationsGroupNode calculateAccumulatedFrame];
    
    CGFloat margin = 25.0;
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    CGRect maximumAllowedBbox = CGRectInset(bounds, margin, margin);
    
    CGFloat top = CGRectGetMaxY(currentBbox) - _congratulationsGroupNode.position.y;
    CGFloat bottom = _congratulationsGroupNode.position.y - CGRectGetMinY(currentBbox);
    CGFloat maxTopAllowed = CGRectGetMaxY(maximumAllowedBbox) - _congratulationsGroupNode.position.y;
    CGFloat maxBottomAllowed = _congratulationsGroupNode.position.y - CGRectGetMinY(maximumAllowedBbox);
    
    CGFloat left = _congratulationsGroupNode.position.x - CGRectGetMinX(currentBbox);
    CGFloat right = CGRectGetMaxX(currentBbox) - _congratulationsGroupNode.position.x;
    CGFloat maxLeftAllowed = _congratulationsGroupNode.position.x - CGRectGetMinX(maximumAllowedBbox);
    CGFloat maxRightAllowed = CGRectGetMaxX(maximumAllowedBbox) - _congratulationsGroupNode.position.x;
    
    CGFloat topScale = top > maxTopAllowed ? maxTopAllowed / top : 1;
    CGFloat bottomScale = bottom > maxBottomAllowed ? maxBottomAllowed / bottom : 1;
    CGFloat leftScale = left > maxLeftAllowed ? maxLeftAllowed / left : 1;
    CGFloat rightScale = right > maxRightAllowed ? maxRightAllowed / right : 1;
    
    CGFloat scale = MIN(topScale, MIN(bottomScale, MIN(leftScale, rightScale)));
    
    _congratulationsGroupNode.xScale = scale;
    _congratulationsGroupNode.yScale = scale;
}

- (void)setupWithController:(AAPLGameController *)controller {
    const CGFloat h = self.size.height;
    
    _overlayNode = [[SKNode alloc] init];
    _collectedGemsSprites = [[NSMutableArray alloc] init];
    
    // Setup the game overlays using SpriteKit.
    self.scaleMode = SKSceneScaleModeResizeFill;
    
    [self addChild:_overlayNode];
    _overlayNode.position = CGPointMake(0.0, h);
    
    // The Max icon.
    SKSpriteNode *characterNode = [SKSpriteNode spriteNodeWithImageNamed:@"MaxIcon.png"];
    AAPLButton *menuButton = [AAPLButton buttonWithSKNode:characterNode];
    menuButton.position = CGPointMake(50, -50);
    menuButton.xScale = 0.5;
    menuButton.yScale = 0.5;
    [_overlayNode addChild:menuButton];
    [menuButton setClickedTarget:self action:@selector(toggleMenu:)];

    // The Gem
    SKSpriteNode *gemNode = [SKSpriteNode spriteNodeWithImageNamed:@"collectableBIG_empty.png"];
    gemNode.position = CGPointMake(125, -50);
    gemNode.xScale = 0.3;
    gemNode.yScale = 0.3;
    [_overlayNode addChild:gemNode];
    [_collectedGemsSprites addObject:gemNode];
    
    // The key.
    _collectedKeySprite = [SKSpriteNode spriteNodeWithImageNamed:@"key_empty.png"];
    _collectedKeySprite.position = CGPointMake(182, -50);
    _collectedKeySprite.xScale = 0.3;
    _collectedKeySprite.yScale = 0.3;
    
    [_overlayNode addChild:_collectedKeySprite];
    
    // The virtual D-pad
#if TARGET_OS_IOS
    const CGFloat w = self.size.width;
    _controlOverlay = [[AAPLControlOverlay alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    _controlOverlay.leftPad.delegate = controller;
    _controlOverlay.rightPad.delegate = controller;
    _controlOverlay.buttonA.delegate = controller;
    _controlOverlay.buttonB.delegate = controller;
    [self addChild:_controlOverlay];
#endif

    // the demo UI
    _demoMenu = [[AAPLMenu alloc] initWithSize:self.size];
    _demoMenu.delegate = controller;
    _demoMenu.hidden = YES;
    [_overlayNode addChild:_demoMenu];
    
    // Assign the SpriteKit overlay to the SceneKit view.
    self.userInteractionEnabled = NO;
}

- (void)setCollectedGemsCount:(NSUInteger)collectedGemsCount {
    _collectedGemsSprites[collectedGemsCount - 1].texture = [SKTexture textureWithImageNamed:@"collectableBIG_full.png"];
    
    [_collectedGemsSprites[collectedGemsCount - 1] runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5], [SKAction scaleBy:1.5 duration:0.2], [SKAction scaleBy:1/1.5 duration:0.2]]]];
    
}

- (void)didCollectKey
{
    _collectedKeySprite.texture = [SKTexture textureWithImageNamed:@"key_full.png"];
    [_collectedKeySprite runAction:[SKAction sequence:@[ [SKAction waitForDuration:0.5],[SKAction scaleBy:1.5 duration:0.2], [SKAction scaleBy:1/1.5 duration:0.2]]]];
}


#if TARGET_OS_IOS
- (void)showVirtualPad {
    _controlOverlay.hidden = NO;
}

- (void)hideVirtualPad {
    _controlOverlay.hidden = YES;
}
#endif

#pragma mark - Congratulating the Player

- (void)showEndScreen {
    // Congratulation title
    SKSpriteNode *congratulationsNode = [SKSpriteNode spriteNodeWithImageNamed:@"congratulations.png"];
    
    // Max image
    SKSpriteNode *characterNode = [SKSpriteNode spriteNodeWithImageNamed:@"congratulations_pandaMax.png"];
    characterNode.position = CGPointMake(0.0, -220.0);
    characterNode.anchorPoint = CGPointMake(0.5, 0.0);
    
    _congratulationsGroupNode = [[SKNode alloc] init];
    
    [_congratulationsGroupNode addChild:characterNode];
    [_congratulationsGroupNode addChild:congratulationsNode];
    
    [self addChild:_congratulationsGroupNode];
    
    // Layout the overlay
    [self layout2DOverlay];
    
    // Animate
    congratulationsNode.alpha = 0.0;
    congratulationsNode.xScale = 0.0;
    congratulationsNode.yScale = 0.0;
    [congratulationsNode runAction:[SKAction group:@[[SKAction fadeInWithDuration:0.25],
                                                     [SKAction sequence:@[[SKAction scaleTo:1.22 duration:0.25], [SKAction scaleTo:1.0 duration:0.1]]]]]];
    
    
    characterNode.alpha = 0.0;
    characterNode.xScale = 0.0;
    characterNode.yScale = 0.0;
    [characterNode runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5], [SKAction group:@[[SKAction fadeInWithDuration:0.5],
                                                                                                    [SKAction sequence:@[[SKAction scaleTo:1.22 duration:0.25], [SKAction scaleTo:1.0 duration:0.1]]]]]]]];
}

- (void)toggleMenu:(AAPLButton *)sender
{
    _demoMenu.hidden = !_demoMenu.hidden;
}

@end

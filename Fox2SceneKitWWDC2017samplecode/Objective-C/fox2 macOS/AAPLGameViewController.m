/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The app's main view controller.
 */


#import <SceneKit/SceneKit.h>

#import "AAPLGameViewController.h"
#import "AAPLGameController.h"
#import "AAPLOverlay.h"
#import "AAPLMenu.h"

@interface AAPLGameViewController ()

@property (readonly) SCNView *gameView;
@property (strong, nonatomic) AAPLGameController *gameController;

@end


@interface AAPLGameView : SCNView

@property (weak) AAPLGameViewController *viewController;

@end


@implementation AAPLGameViewController

- (AAPLGameView *)gameView {
    return (AAPLGameView *)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.gameController = [[AAPLGameController alloc] initWithSCNView:self.gameView];
    
    // Configure the view
    self.gameView.backgroundColor = [NSColor blackColor];
    
    // Link view and controller
    ((AAPLGameView*)self.gameView).viewController = self;
}

- (BOOL)keyDown:(NSView *)view event:(NSEvent *)theEvent
{
    vector_float2 characterDirection = self.gameController.characterDirection;
    vector_float2 cameraDirection = self.gameController.cameraDirection;

    bool updateCamera = false;
    bool updateCharacter = false;

    switch (theEvent.keyCode) {
        case 126: // Up
            if (!theEvent.isARepeat) {
                characterDirection.y = -1;
                updateCharacter = true;
            }
            break;
        case 125: // Down
            if (!theEvent.isARepeat) {
                characterDirection.y = 1;
                updateCharacter = true;
            }
            break;
        case 123: // Left
            if (!theEvent.isARepeat) {
                characterDirection.x = -1;
                updateCharacter = true;
            }
            break;
        case 124: // Right
            if (!theEvent.isARepeat) {
                characterDirection.x = 1;
                updateCharacter = true;
            }
            break;
        case 13: // Camera up
            if (!theEvent.isARepeat) {
                cameraDirection.y = -1;
                updateCamera = true;
            }
            break;
        case 1: // Camera down
            if (!theEvent.isARepeat) {
                cameraDirection.y = 1;
                updateCamera = true;
            }
            break;
        case 0: // Left
            if (!theEvent.isARepeat) {
                cameraDirection.x = -1;
                updateCamera = true;
            }
            break;
        case 2: // Camera right
            if (!theEvent.isARepeat) {
                cameraDirection.x = 1;
                updateCamera = true;
            }
            break;
        case 49: // Space
            if (!theEvent.isARepeat) {
                [self.gameController controllerJump:YES];
            }
            return YES;
        case 8: // c
            if (!theEvent.isARepeat) {
                [self.gameController controllerAttack];
            }
            return YES;
        default:
            return NO;
        }

    if (updateCharacter) {
        self.gameController.characterDirection = vector_all(characterDirection == 0.0f) ? characterDirection : vector_normalize(characterDirection);
        return YES;
    }
    if (updateCamera) {
        self.gameController.cameraDirection = vector_all(cameraDirection == 0.0f) ? cameraDirection : vector_normalize(cameraDirection);
        return YES;
    }

    return YES;
}

- (BOOL)keyUp:(NSView *)view event:(NSEvent *)theEvent {
    vector_float2 characterDirection = self.gameController.characterDirection;
    vector_float2 cameraDirection = self.gameController.cameraDirection;

    bool updateCamera = false;
    bool updateCharacter = false;

    switch (theEvent.keyCode) {
        case 36: {
            if (!theEvent.isARepeat) {
                [self.gameController resetPlayerPosition];
            }
            }
            return YES;
        case 126: // Up
            if (!theEvent.isARepeat && characterDirection.y < 0) {
                characterDirection.y = 0;
                updateCharacter = true;
            }
            break;
        case 125: // Down
            if (!theEvent.isARepeat && characterDirection.y > 0) {
                characterDirection.y = 0;
                updateCharacter = true;
            }
            break;
        case 123: // Left
            if (!theEvent.isARepeat && characterDirection.x < 0) {
                characterDirection.x = 0;
                updateCharacter = true;
            }
            break;
        case 124: // Right
            if (!theEvent.isARepeat && characterDirection.x > 0) {
                characterDirection.x = 0;
                updateCharacter = true;
            }
            break;
        case 13: // Camera up
            if (!theEvent.isARepeat && cameraDirection.y < 0) {
                cameraDirection.y = 0;
                updateCamera = true;
            }
            break;
        case 1: // Camera down
            if (!theEvent.isARepeat && cameraDirection.y > 0) {
                cameraDirection.y = 0;
                updateCamera = true;
            }
            break;
        case 0: // Left
            if (!theEvent.isARepeat && cameraDirection.x < 0) {
                cameraDirection.x = 0;
                updateCamera = true;
            }
            break;
        case 2: // Camera right
            if (!theEvent.isARepeat && cameraDirection.x > 0) {
                cameraDirection.x = 0;
                updateCamera = true;
            }
            break;
        case 49: // Space
            if (!theEvent.isARepeat) {
                [self.gameController controllerJump:NO];
            }
            return YES;
    }

    if (updateCharacter) {
        self.gameController.characterDirection = vector_all(characterDirection == 0.0f) ? characterDirection : vector_normalize(characterDirection);
        return YES;
    }

    if (updateCamera) {
        self.gameController.cameraDirection = vector_all(cameraDirection == 0.0f) ? cameraDirection : vector_normalize(cameraDirection);
        return YES;
    }

    return NO;
}

@end


@implementation AAPLGameView

#pragma mark - EventHandler

- (void)keyDown:(NSEvent *)theEvent {
    if (!self.viewController || [self.viewController keyDown:self event:theEvent] == NO) {
        [super keyDown:theEvent];
    }
}

- (void)keyUp:(NSEvent *)theEvent {
    if (!self.viewController || [self.viewController keyUp:self event:theEvent] == NO) {
        [super keyUp:theEvent];
    }
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [(AAPLOverlay *)[self overlaySKScene] layout2DOverlay];
}

- (void)viewDidMoveToWindow
{
    //disable retina
    self.layer.contentsScale = 1;
}

@end

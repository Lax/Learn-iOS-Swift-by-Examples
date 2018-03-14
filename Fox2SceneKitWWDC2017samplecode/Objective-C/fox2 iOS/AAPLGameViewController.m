/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The app's main view controller.
 */

#import <SceneKit/SceneKit.h>
#import "AAPLGameViewController.h"
#import "AAPLGameController.h"

@interface AAPLGameViewController ()

@property (readonly) SCNView *gameView;
@property (strong, nonatomic) AAPLGameController *gameController;

@end

@implementation AAPLGameViewController

- (SCNView *)gameView {
    return (SCNView *)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1.3x on iPads
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.gameView.contentScaleFactor = MIN(1.3, self.gameView.contentScaleFactor);
        self.gameView.preferredFramesPerSecond = 60.0;
    }
    
    
    self.gameController = [[AAPLGameController alloc] initWithSCNView:self.gameView];
    
    // Configure the view
    self.gameView.backgroundColor = [UIColor blackColor];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end

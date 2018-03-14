/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The app's main view controller.
 */

#import "AAPLGameViewController.h"
#import <SceneKit/SceneKit.h>
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
    
    self.gameController = [[AAPLGameController alloc] initWithSCNView:self.gameView];
    
    // Configure the view
    self.gameView.backgroundColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

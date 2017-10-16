/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This view controller manages the display of a set of view controllers by way of implementing the UIPageViewControllerDelegate protocol.
*/



#import <UIKit/UIKit.h>



@class ModelController;



@interface RootViewController: UIViewController <UIPageViewControllerDelegate>


@property (strong, nonatomic) UIPageViewController *pageViewController;

@property (strong, nonatomic) ModelController *modelController;


- (void)viewDidLoad;

- (ModelController *)modelController;

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end

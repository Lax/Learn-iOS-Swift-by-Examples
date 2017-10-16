/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This view controller manages the display of a set of view controllers by way of implementing the UIPageViewControllerDataSource protocol.
 */


#import <UIKit/UIKit.h>



@class DataViewController;


@interface ModelController: NSObject <UIPageViewControllerDataSource>


@property CGPDFDocumentRef pdf;

@property int numberOfPages; 


- (id)init;

- (void)dealloc;

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;

- (NSUInteger)indexOfViewController:(DataViewController *)viewController;

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController;

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController;

@end

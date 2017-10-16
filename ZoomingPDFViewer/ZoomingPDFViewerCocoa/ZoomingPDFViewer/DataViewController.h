/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The app's view controller which presents viewable content.
*/



#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>



@class TiledPDFScrollView;



@interface DataViewController: UIViewController


@property (strong) IBOutlet TiledPDFScrollView *scrollView;

@property CGPDFDocumentRef pdf;

@property CGPDFPageRef page;

@property int pageNumber;

@property CGFloat myScale;



- (void)dealloc;

- (void)viewDidLoad;

- (void)viewDidLayoutSubviews;

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator;

- (void)restoreScale;

@end




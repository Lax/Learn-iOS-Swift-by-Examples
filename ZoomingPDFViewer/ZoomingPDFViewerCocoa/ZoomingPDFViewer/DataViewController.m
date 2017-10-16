/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The app's view controller which presents viewable content.
*/


#import "DataViewController.h"
#import "PDFView.h"
#import "TiledPDFScrollView.h"
#import "TiledPDFView.h"



@implementation DataViewController



- (void)dealloc
{
    if ( self.page != NULL )
    {
        CGPDFPageRelease( self.page );
    }
}



- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
    self.page = CGPDFDocumentGetPage( self.pdf, self.pageNumber );
    if ( self.page != NULL ) CGPDFPageRetain( self.page );
    [self.scrollView setPDFPage:self.page];

    // Disable zooming if our pages are currently shown in landscape for new views
    [self.scrollView setUserInteractionEnabled:UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)];
}



- (void)viewDidLayoutSubviews
{
    [self restoreScale];
}



- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator
     animateAlongsideTransition:nil
     completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {

         // Disable zooming if our pages are currently shown in landscape after orientation changes
         [self.scrollView setUserInteractionEnabled:UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)];
    }];
}



- (void)restoreScale
{
    // Called on orientation change.
    // We need to zoom out and basically reset the scrollview to look right in two-page spline view.
    CGRect pageRect = CGPDFPageGetBoxRect( self.page, kCGPDFMediaBox );
    CGFloat yScale = self.view.frame.size.height / pageRect.size.height;
    CGFloat xScale = self.view.frame.size.width / pageRect.size.width;
    self.myScale = MIN( xScale, yScale );
    self.scrollView.bounds = self.view.bounds;
    self.scrollView.zoomScale = 1.0;
    self.scrollView.PDFScale = self.myScale;
    self.scrollView.tiledPDFView.bounds = self.view.bounds;
    self.scrollView.tiledPDFView.myScale = self.myScale;
    [self.scrollView.tiledPDFView.layer setNeedsDisplay];
}


@end

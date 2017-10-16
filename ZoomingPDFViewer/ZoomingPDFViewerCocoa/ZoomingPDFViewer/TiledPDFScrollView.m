/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UIScrollView subclass that handles the user input to zoom the PDF page.  This class handles swapping the TiledPDFViews when the zoom level changes.
 */


#import "TiledPDFScrollView.h"
#import "TiledPDFView.h"
#import <QuartzCore/QuartzCore.h>



@implementation TiledPDFScrollView



- (void)initialize
{
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.delegate = self;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 5;
    self.minimumZoomScale = .25;
    self.maximumZoomScale = 5;
}



- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if ( self ) {
        [self initialize];
    }
    return self;
}



- (id)initWithFrame:(CGRect)frame
{
    if ( self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}



- (void)setPDFPage:(CGPDFPageRef)newPDFPage
{
    if ( newPDFPage != NULL ) CGPDFPageRetain(newPDFPage);
    if ( self.tiledPDFPage != NULL ) CGPDFPageRelease(self.tiledPDFPage);

    self.tiledPDFPage = newPDFPage;
    
    // PDFPage is null if we're requested to draw a padded blank page by the parent UIPageViewController
    if ( self.tiledPDFPage == NULL )
    {
        self.pageRect = self.bounds;
    }
    else
    {
        self.pageRect = CGPDFPageGetBoxRect( self.tiledPDFPage, kCGPDFMediaBox );
        _PDFScale = self.frame.size.width / self.pageRect.size.width;
        self.pageRect = CGRectMake( self.pageRect.origin.x, self.pageRect.origin.y, self.pageRect.size.width*_PDFScale, self.pageRect.size.height*_PDFScale );
    }
    // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
    [self replaceTiledPDFViewWithFrame: self.pageRect];
}



- (void)dealloc
{
    // Clean up.
    if ( self.tiledPDFPage != NULL ) CGPDFPageRelease(self.tiledPDFPage);
}



#pragma mark -
#pragma mark Override layoutSubviews to center content



// Use layoutSubviews to center the PDF page in the view.
- (void)layoutSubviews
{
    [super layoutSubviews];

    // Center the image as it becomes smaller than the size of the screen.
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.tiledPDFView.frame;
    
    // Center horizontally.
    if ( frameToCenter.size.width < boundsSize.width )
    {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }
    else
    {
        frameToCenter.origin.x = 0;
    }

    // Center vertically.
    if ( frameToCenter.size.height < boundsSize.height )
    {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    } else {
        frameToCenter.origin.y = 0;
    }

    self.tiledPDFView.frame = frameToCenter;
    self.backgroundImageView.frame = frameToCenter;
    
    /*
     To handle the interaction between CATiledLayer and high resolution screens, set the tiling view's contentScaleFactor to 1.0.
     If this step were omitted, the content scale factor would be 2.0 on high resolution screens, which would cause the CATiledLayer to ask for tiles of the wrong scale.
     */
    self.tiledPDFView.contentScaleFactor = 1.0;
}



#pragma mark -
#pragma mark UIScrollView delegate methods



/*
 A UIScrollView delegate callback, called when the user starts zooming.
 Return the current TiledPDFView.
 */
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.tiledPDFView;
}



/*
 A UIScrollView delegate callback, called when the user begins zooming.
 When the user begins zooming, remove the old TiledPDFView and set the current TiledPDFView to be the old view so we can create a new TiledPDFView when the zooming ends.
 */
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    // Remove back tiled view.
    [self.oldTiledPDFView removeFromSuperview];
    
    // Set the current TiledPDFView to be the old view.
    self.oldTiledPDFView = self.tiledPDFView;
}



/*
 A UIScrollView delegate callback, called when the user stops zooming.
 When the user stops zooming, create a new TiledPDFView based on the new zoom level and draw it on top of the old TiledPDFView.
 */
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    // Set the new scale factor for the TiledPDFView.
    _PDFScale *= scale;

    // Create a new tiled PDF View at the new scale
    [self replaceTiledPDFViewWithFrame:self.oldTiledPDFView.frame];
}



-(void)replaceTiledPDFViewWithFrame:(CGRect)frame
{
    // Create a new tiled PDF View at the new scale
    TiledPDFView *newTiledPDFView = [[TiledPDFView alloc] initWithFrame:frame scale:_PDFScale];
    [newTiledPDFView setPage: self.tiledPDFPage];
    
    // Add the new TiledPDFView to the PDFScrollView.
    [self addSubview: newTiledPDFView];
    self.tiledPDFView = newTiledPDFView;
}


@end

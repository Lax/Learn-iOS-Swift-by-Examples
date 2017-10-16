/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
UIScrollView subclass that handles the user input to zoom the PDF page.  This class handles swapping the TiledPDFViews when the zoom level changes.
*/


#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class TiledPDFView;


@interface TiledPDFScrollView: UIScrollView <UIScrollViewDelegate>


// Frame of the PDF
@property (nonatomic) CGRect pageRect;

// A low resolution image of the PDF page that is displayed until the TiledPDFView renders its content.
@property (nonatomic, weak) UIView *backgroundImageView;

// The TiledPDFView that is currently front most.
@property (nonatomic, weak) TiledPDFView *tiledPDFView;

// The old TiledPDFView that we draw on top of when the zooming stops.
@property (nonatomic, weak) TiledPDFView *oldTiledPDFView;

// Current PDF zoom scale.
@property (nonatomic) CGFloat PDFScale;

// a reference to the page being drawn, we manage the storage ourselves for the cf type
@property (nonatomic, assign) CGPDFPageRef tiledPDFPage;


- (id)initWithCoder:(NSCoder *)coder;

- (id)initWithFrame:(CGRect)frame;

- (void)initialize;

- (void)setPDFPage:(CGPDFPageRef)PDFPage;

- (void)dealloc;

- (void)layoutSubviews;

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view;

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale;

- (void)replaceTiledPDFViewWithFrame:(CGRect)frame;

@end

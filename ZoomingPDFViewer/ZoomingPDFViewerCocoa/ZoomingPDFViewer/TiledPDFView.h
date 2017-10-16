/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This view is backed by a CATiledLayer into which the PDF page is rendered into.
*/


#import <UIKit/UIKit.h>


@interface TiledPDFView: UIView


@property CGPDFPageRef pdfPage;

@property CGFloat myScale;


- (id)initWithFrame:(CGRect)frame scale:(CGFloat)scale;
- (void)dealloc;
+ (Class)layerClass;
- (void)setPage:(CGPDFPageRef)newPage;
- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context;

@end

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class draws your AAPLFloorplanOverlay into an MKMapView. It is also capable of drawing diagnostic visuals to help with debugging, if needed.
*/

#import "AAPLFloorplanOverlayRenderer.h"
#import "AAPLFloorplanOverlay.h"

/*
    For additional debugging set AAPLFloorplanOverlayDebugEnabled to 1. This will
    highlight the floorplan's boundingMapRect in cyan.
*/
#define AAPLFloorplanOverlayDebugEnabled 0

@interface AAPLFloorplanOverlay ()

/**
    This draws directly in the PDF coordinate system.
    If drawing onto MapKit, the context object provided must already have the
    appropriate transforms applied.

    If you have the transform correct, you should see the following:
    [A] 1.0 m radius red square (50% alpha) centered on the 1st anchor point.
    [B] 1.0 m radius green square (50% alpha) centered on the 2nd anchor point.
    [C] a 1x1 point magenta square centered at the (0.0, 0.0) point of your PDF.
        This square is created by the precise overlap of the following two
        rectangles.
    [C.1] a 10x1 point  red rectangle (50% alpha) that covers the 1x1 point
            square centered at PDF coordinate (0.0, 0.0) through the 1x1 point
            square centered at PDF coordinate (10.0, 0.0).
    [C.2] a 1x10 point blue rectangle (50% alpha) that covers the 1x1 point
            square centered at PDF coordinate (0.0, 0.0) and the 1x1 point
            square centered at PDF coordinate (10.0, 1.0).

    Use [A] & [B] to verify that your anchor points have been set to the correct
    points on your PDF. If this does not match:
    + check your PDF reader and make sure it is giving you values in "points"
        and not "pixels" or some other unit of measure.
    + look for typos in the CGPoint values of your AAPLGeoAnchor structs.

    Use [C] to verify the location of (0.0, 0.0) on your PDF. If this does not
    match:
    + check your PDF reader and make sure it is showing you values of the
        underlying PDF coordinate system, and not its own internal display
        coordinate system. A proper PDF coordinate system should have +x be
        rightward and +y be upward.

    Use [C.1] & [C.2] to verify the sizes of "1.0 point" and "10.0 points" on
    your PDF. If this does not match:
    + check your PDF reader and make sure it is giving you values in "points"
        and not "pixels" or some other unit of measure.

*/
+ (void)drawDiagnosticVisuals:(CGContextRef)context floorplan:(AAPLFloorplanOverlay *)floorplanOverlay;

@end

@implementation AAPLFloorplanOverlayRenderer

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    NSAssert([self.overlay isKindOfClass:[AAPLFloorplanOverlay class]], @"Wrong overlay type.");

    AAPLFloorplanOverlay *floorplanOverlay = self.overlay;

    MKMapRect boundingMapRect = self.overlay.boundingMapRect;

    /*
        Mapkit converts to its own dynamic CGPoint frame, which we can read
        through rectForMapRect.
     */
    CGRect mapkitToGraphicsConversion = [self rectForMapRect:boundingMapRect];

    CGPoint graphicsFloorplanCenter = CGPointMake(
        CGRectGetMidX(mapkitToGraphicsConversion),
        CGRectGetMidY(mapkitToGraphicsConversion)
    );

    CGFloat graphicsFloorplanWidth = CGRectGetWidth(mapkitToGraphicsConversion);
    CGFloat graphicsFloorplanHeight = CGRectGetHeight(mapkitToGraphicsConversion);


    // Now, how does this compare to MapKit coordinates?
    MKMapPoint mapkitFloorplanCenter = (MKMapPoint) {
        .x = MKMapRectGetMidX(self.overlay.boundingMapRect),
        .y = MKMapRectGetMidY(self.overlay.boundingMapRect)
    };

    double mapkitFloorplanWidth = MKMapRectGetWidth(self.overlay.boundingMapRect);
    double mapkitFloorplanHeight = MKMapRectGetHeight(self.overlay.boundingMapRect);

    /*
        Create the transformation that converts to Graphics coordinates from
        MapKit coordinates.
        
        graphics.x = (mapkit.x - mapkitFloorplanCenter.x) * graphicsFloorplanWidth / mapkitFloorplanWidth + graphicsFloorplanCenter.x
     */
    CGAffineTransform fromMapKitToGraphics = CGAffineTransformIdentity;

    fromMapKitToGraphics = CGAffineTransformTranslate(fromMapKitToGraphics, -mapkitFloorplanCenter.x, -mapkitFloorplanCenter.y);
    
    fromMapKitToGraphics = CGAffineTransformScale(
        fromMapKitToGraphics,
        graphicsFloorplanWidth / mapkitFloorplanWidth,
        graphicsFloorplanHeight / mapkitFloorplanHeight
    );

    fromMapKitToGraphics = CGAffineTransformTranslate(fromMapKitToGraphics, graphicsFloorplanCenter.x, graphicsFloorplanCenter.y);

    /*
        Using this, we can send draw commands in MapKit coordinates and cause
        the equivalent drawing in (the correct) graphics coordinates.
     */

    /*
        Highlight the floorplan's boundingMapRect in cyan if AAPLFloorplanOverlayDebugEnabled
        is enabled.
    */
    #if AAPLFloorplanOverlayDebugEnabled
    CGContextSetRGBFillColor(context, 0.0, 1.0, 1.0, 0.5);
    CGContextFillRect(context, mapkitToGraphicsConversion);
    #endif

    /*
        However, we want to be able to send draw commands in the original PDF
        coordinates though, so we'll also need the transformations that convert
        to MapKit coordinates from PDF coordinates.
     */
    CGAffineTransform fromPdfToMapKit = floorplanOverlay.transformerFromPDFToMk;

    CGContextConcatCTM(context, CGAffineTransformConcat(fromPdfToMapKit, fromMapKitToGraphics));

    CGContextDrawPDFPage(context, floorplanOverlay.PDFPage);

    /*
        The following diagnostic visuals are provided for debugging only. In production, 
        you'll want to remove them.
    */
    #if AAPLFloorplanOverlayDebugEnabled
    [AAPLFloorplanOverlayRenderer drawDiagnosticVisuals:context floorplan:floorplanOverlay];
    #endif
}

+ (void)drawDiagnosticVisuals:(CGContextRef)context floorplan:(AAPLFloorplanOverlay *)floorplanOverlay {
    // Draw a 1.0 meter radius square around each anchor point.
    CGFloat radiusPDFPoints = 1.0 / floorplanOverlay.PDFPointSizeInMeters;
    CGSize anchorMarkerSize = CGSizeMake(radiusPDFPoints * 2.0, radiusPDFPoints * 2.0);

    CGRect fromAnchorMarker = (CGRect) {
        .origin = (CGPoint) {
            .x = floorplanOverlay.anchors.fromAnchor.PDFPoint.x - radiusPDFPoints,
            .y = floorplanOverlay.anchors.fromAnchor.PDFPoint.y - radiusPDFPoints,
        },
        .size = anchorMarkerSize
    };

    CGRect toAnchorMarker = (CGRect) {
        .origin = (CGPoint) {
            .x = floorplanOverlay.anchors.toAnchor.PDFPoint.x - radiusPDFPoints,
            .y = floorplanOverlay.anchors.toAnchor.PDFPoint.y - radiusPDFPoints,
        },
        .size = anchorMarkerSize
    };

    // Anchor 1: Red.
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.75);
    CGContextFillRect(context, fromAnchorMarker);

    // Anchor 2: Green.
    CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 0.75);
    CGContextFillRect(context, toAnchorMarker);

    /*
        Draw a 10pt x 1pt red rectangle that covers the square centered at
        (0.0, 0.0) through the square centered at (10.0, 0.0).
     */
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.5);
    CGContextFillRect(context, CGRectMake(-0.5, -0.5, 10.0, 1.0));

    /*
        Draw a 1pt x 10pt blue rectangle that covers the square centered at
        (0.0, 0.0) through the square centered at (0.0, 10.0).
     */
    CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.5);
    CGContextFillRect(context, CGRectMake(-0.5, -0.5, 1.0, 10.0));
}

@end

#undef AAPLFloorplanOverlayDebugEnabled

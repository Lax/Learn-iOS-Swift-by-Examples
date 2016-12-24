/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class draws your AAPLFloorplanOverlay into an MKMapView. It is also capable of drawing diagnostic visuals to help with debugging, if needed.
*/

@import MapKit;

/**
    This class draws your AAPLFloorplanOverlay into an MKMapView.
    It is also capable of drawing diagnostic visuals to help with debugging,
    if needed.
*/
@interface AAPLFloorplanOverlayRenderer : MKOverlayRenderer

/**
    @note Overrides the drawMapRect method for \c MKOverlayRenderer.
*/
- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context;

@end

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    In order to properly clamp the MKMapView (see AAPLVisibleMapRegionDelegate) to inside a floorplan (that may not be "North up", and therefore may not be aligned with the standard MKMapRect coordinate frames), we'll need a way to store and quickly compute whether a specific MKMapPoint is inside your floorplan or not, and the displacement to the nearest edge of the floorplan.
    
                Since all PDF bounding boxes are still PDFs, after all, in the case of this sample code we need only represent a "rotated" MKMapRect. If you have transparency in your PDF or need something fancier, consider an MKPolygon and some combination of CGPathContainsPoint(), etc.
*/

#pragma once

@import MapKit;

/**
    Represents a "direction vector" or a "unit vector" between \c MKMapPoints.

    It is intended to always have length 1.0, that is 
        \c hypot(eX, eY) === 1.0
    always.

    @param eX direction along x
    @param eY direction along y
 */
typedef struct {
    double eX;
    double eY;
} AAPLMKMapDirection;

/**
    In order to properly clamp the \c MKMapView (see 
    \c AAPLVisibleMapRegionDelegate) to inside a floorplan (that may not be 
    "North up", and therefore may not be aligned with the standard \c MKMapRect
    coordinate frames), we'll need a way to store and quickly compute whether a
    specific \c MKMapPoint is inside your floorplan or not, and the displacement
    to the nearest edge of the floorplan.

    Since all PDF bounding boxes are still PDFs, after all, in the case of this
    sample code we need only represent a "rotated" \c MKMapRect.
    If you have transparency in your PDF or need something fancier, consider an
    \c MKPolygon and some combination of \c CGPathContainsPoint(), etc.

    @param rectCenter The center of the rectangle in MK coordinates.

    @param rectSize The size of the original rectangle in MK coordinates.
    
    @param widthDirection The "direction vector" of the "width" dimension.
            This vector has length 1.0 and points in the direction of "width".
    
    @param heightDirection The "direction vector" of the "height" dimension.
            This vector has length 1.0 and points in the direction of "width".
 */
typedef struct {
    MKMapPoint rectCenter;
    MKMapSize rectSize;
    AAPLMKMapDirection widthDirection;
    AAPLMKMapDirection heightDirection;
} AAPLMKMapRectRotated;

/**
    @param corner1 First corner.
    @param corner2 Next corner.
    @param corner3 Corner after corner2.
    @param corner4 Last corner.

    @note The four corners MUST be in clockwise or counter-clockwise order (i.e.
        going around the rectangle, and not criss-crossing through it)!

    @return \c MKMapRect constructed from the four corners of a 
                (probably rotated) rectangle.
 */
AAPLMKMapRectRotated AAPLMKMapRectRotatedMake(MKMapPoint corner1,
                                              MKMapPoint corner2,
                                              MKMapPoint corner3,
                                              MKMapPoint corner4);

/**
    Return the nearest \c MKMapPoint that is inside the \c AAPLMKMapRectRotated
    For an "upright" rectangle, getting the nearest point is simple. Just clamp
    the value to width and height!

    We'd love to have that simplicity too, so our underlying main strategy is to
    simplify the problem. If we can answer the following two questions:
    1. how far away are you, from the rectangle, in the height direction?
    2. how far away are you, from the rectangle, in the width direction?

    Then we can use these values to take the exact same (simple) approach!

    @param mapRectRotated Your (likely rotated) \c AAPLMKMapRectRotated
    @param point An \c MKMapPoint

    @return The \c MKMapPoint inside \c mapRectRotated that is closest to 
            \c point
*/
MKMapPoint AAPLMKMapRectRotatedNearestPoint(AAPLMKMapRectRotated mapRectRotated, MKMapPoint point);

/*
     Copyright (C) 2016 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     In order to properly clamp the MKMapView (see AAPLVisibleMapRegionDelegate) to inside a floorplan (that may not be "North up", and therefore may not be aligned with the standard MKMapRect coordinate frames), we'll need a way to store and quickly compute whether a specific MKMapPoint is inside your floorplan or not, and the displacement to the nearest edge of the floorplan.
     
                 Since all PDF bounding boxes are still PDFs, after all, in the case of this sample code we need only represent a "rotated" MKMapRect. If you have transparency in your PDF or need something fancier, consider an MKPolygon and some combination of CGPathContainsPoint(), etc.
*/

#include "AAPLMKMapRectRotated.h"

/**
    Displacement from two MKMapPoints -- a direction and distance.

    @param direction The direction of displacement, a unit vector.
    @param distance The magnitude of the displacement.
 */
typedef struct {
    AAPLMKMapDirection direction;
    double distance;
} AAPLMKMapPointDisplacement;

/**
    @param val value to clamp.
    @param min least possible value.
    @param max greatest possible value.

    @return clamped version of \c val such that it falls between \c min and \c max
*/
static double clamp(double val, double min, double max) {
    return (val < min) ? min : ((val > max) ? max : val);
}

/**
    @param a Point A.
    @param b Point B.

    @return An \c MKMapPoint object representing the midpoints of \c a and \c b
*/
static MKMapPoint AAPLMKMapPointMidpoint(MKMapPoint a, MKMapPoint b) {
    return (MKMapPoint) {
        .x = (a.x + b.x) * 0.5,
        .y = (a.y + b.y) * 0.5
    };
}

/**
     @param to ending point.
     @param from starting point.

     @return The displacement between two MKMapPoint objects.
*/
static AAPLMKMapPointDisplacement AAPLMKMapPointSubtract(MKMapPoint to, MKMapPoint from) {
    double dx = to.x - from.x;
    double dy = to.y - from.y;

    double distance = hypot(dx, dy);

    return (AAPLMKMapPointDisplacement) {
        .direction = (AAPLMKMapDirection) {
            .eX = dx / distance,
            .eY = dy / distance
        },
        .distance = distance
    };
}

AAPLMKMapRectRotated AAPLMKMapRectRotatedMake(MKMapPoint corner1, MKMapPoint corner2, MKMapPoint corner3, MKMapPoint corner4) {

    // Avg the points to get the center of the rectangle in MKMapPoint space.
    MKMapPoint center = {
        .x = (corner1.x + corner2.x + corner3.x + corner4.x) / 4.0,
        .y = (corner1.y + corner2.y + corner3.y + corner4.y) / 4.0
    };

    // Figure out the "width direction" and "height direction"...
    MKMapPoint heightMax = AAPLMKMapPointMidpoint(corner1, corner2);
    MKMapPoint heightMin = AAPLMKMapPointMidpoint(corner4, corner3);
    MKMapPoint widthMax  = AAPLMKMapPointMidpoint(corner1, corner4);
    MKMapPoint widthMin  = AAPLMKMapPointMidpoint(corner2, corner3);

    // ...as well as the actual width and height.
    AAPLMKMapPointDisplacement width = AAPLMKMapPointSubtract(widthMax, widthMin);
    AAPLMKMapPointDisplacement height = AAPLMKMapPointSubtract(heightMax, heightMin);

    return (AAPLMKMapRectRotated) {
        .rectCenter = center,
        .rectSize = (MKMapSize) {
            .width = width.distance,
            .height = height.distance
        },
        .widthDirection = width.direction,
        .heightDirection = height.direction
    };
}

MKMapPoint AAPLMKMapRectRotatedNearestPoint(AAPLMKMapRectRotated mapRectRotated, MKMapPoint point) {
    double dxCenter = (point.x - mapRectRotated.rectCenter.x);
    double dyCenter = (point.y - mapRectRotated.rectCenter.y);

    /*
        We use a dot product against a unit vector (a.k.a. projection) to find
        distance "along a particular direction."
     */
    double widthDistance = dxCenter * mapRectRotated.widthDirection.eX +
                           dyCenter * mapRectRotated.widthDirection.eY;

    /*
        We use a dot product against a unit vector (a.k.a. projection) to find
        distance "along a particular direction."
     */
    double heightDistance = dxCenter * mapRectRotated.heightDirection.eX +
                            dyCenter * mapRectRotated.heightDirection.eY;

    // "If this rectangle _were_ upright, this would be the result."
    double widthNearestPoint  = clamp(widthDistance, -0.5 * mapRectRotated.rectSize.width, 0.5 * mapRectRotated.rectSize.width);
    double heightNearestPoint = clamp(heightDistance, -0.5 * mapRectRotated.rectSize.height, 0.5 * mapRectRotated.rectSize.height);

    /*
        Since it's not upright, just combine the width and height in their corresponding
        directions!
     */
    return (MKMapPoint) {
        .x = mapRectRotated.rectCenter.x + widthNearestPoint * mapRectRotated.widthDirection.eX + heightNearestPoint * mapRectRotated.heightDirection.eX,
        .y = mapRectRotated.rectCenter.y + widthNearestPoint * mapRectRotated.widthDirection.eY + heightNearestPoint * mapRectRotated.heightDirection.eY
    };
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    In order to properly clamp the MKMapView (see
                VisibleMapRegionDelegate) to inside a floorplan (that may not be
                "North up", and therefore may not be aligned with the standard
                MKMapRect coordinate frames),
                we'll need a way to store and quickly compute whether a specific
                MKMapPoint is inside your floorplan or not, and the displacement to
                the nearest edge of the floorplan.
    
                Since all PDF bounding boxes are still PDFs, after all, in the case
                of this sample code we need only represent a "rotated" MKMapRect.
                If you have transparency in your PDF or need something fancier,
                consider an MKPolygon and some combination of CGPathContainsPoint()
*/

import Foundation
import MapKit

/**
    Represents a "direction vector" or a "unit vector" between MKMapPoints.

    It is intended to always have length 1.0, that is `hypot(eX, eY) === 1.0`

    - parameter eX: direction along x
    - parameter eY: direction along y
*/
struct MKMapDirection {
    var eX = 0.0
    var eY = 0.0
}

/**
    In order to properly clamp the MKMapView (see VisibleMapRegionDelegate) to
    inside a floorplan (that may not be "North up", and therefore may not be
    aligned with the standard MKMapRect coordinate frames), we'll need a way to
    store and quickly compute whether a specific MKMapPoint is inside your
    floorplan or not, and the displacement to the nearest edge of the floorplan.

    Since all PDF bounding boxes are still PDFs, after all, in the case of this
    sample code we need only represent a "rotated" MKMapRect.
    If you have transparency in your PDF or need something fancier, consider an
    MKPolygon and some combination of CGPathContainsPoint(), etc.

    - parameter rectCenter: The center of the rectangle in MK coordinates.
    - parameter rectSize: The size of the original rectangle in MK coordinates.
    - parameter widthDirection: The "direction vector" of the "width" dimension.
            This vector has length 1.0 and points in the direction of "width".
    - parameter heightDirection: The "direction vector" of the "height"
            dimension. This vector has length 1.0 and points in the direction of
            "width".
*/
struct MKMapRectRotated {
    var rectCenter = MKMapPoint()
    var rectSize = MKMapSize()
    var widthDirection = MKMapDirection()
    var heightDirection = MKMapDirection()
}

/**
    Displacement from two MKMapPoints -- a direction and distance.

    - parameter direction: The direction of displacement, a unit vector.
    - parameter distance: The magnitude of the displacement.
*/
struct MKMapPointDisplacement {
    var direction = MKMapDirection()
    var distance = 0.0
}

/**
    - parameter corner1: First corner.
    - parameter corner2: Next corner.
    - parameter corner3: Corner after corner2.
    - parameter corner4: Last corner.

    - note: The four corners MUST be in clockwise or counter-clockwise order
        (i.e. going around the rectangle, and not criss-crossing through it)!

    - returns: MKMapRect constructed from the four corners of a (probably
        rotated) rectangle.
*/
func MKMapRectRotatedMake(_ corner1: MKMapPoint, corner2: MKMapPoint, corner3: MKMapPoint, corner4: MKMapPoint) -> MKMapRectRotated{

    // Average the points to get the center of the rect in MKMapPoint space.
    let averageX = (corner1.x + corner2.x + corner3.x + corner4.x) / 4.0
    let averageY = (corner1.y + corner2.y + corner3.y + corner4.y) / 4.0
    let center = MKMapPoint(x: averageX, y: averageY)

    // Figure out the "width direction" and "height direction"...
    let heightMax = MKMapPoint.midpoint(corner1, b: corner2)
    let heightMin = MKMapPoint.midpoint(corner4, b: corner3)
    let widthMax = MKMapPoint.midpoint(corner1, b: corner4)
    let widthMin = MKMapPoint.midpoint(corner2, b: corner3)

    // ...as well as the actual width and height.
    let width = widthMax.displacementToPoint(widthMin)
    let height = heightMax.displacementToPoint(heightMin)
    let rotatedRectSize = MKMapSize(width: width.distance, height: height.distance)

    return MKMapRectRotated(rectCenter: center, rectSize: rotatedRectSize,
                            widthDirection: width.direction, heightDirection: height.direction)
}

/**
    Return the *nearest* MKMapPoint that is inside the MKMapRectRotated
    For an "upright" rectangle, getting the nearest point is simple. Just clamp
    the value to width and height!

    We'd love to have that simplicity too, so our underlying main strategy is to
    simplify the problem.

    If we can answer the following two questions:
        1. how far away are you, from the rectangle, in the height direction?
        2. how far away are you, from the rectangle, in the width direction?

    Then we can use these values to take the exact same (simple) approach!

    - parameter mapRectRotated: Your (likely rotated) MKMapRectRotated.
    - parameter point: An MKMapPoint.

    - returns: The MKMapPoint inside mapRectRotated that is closest to point
*/
func MKMapRectRotatedNearestPoint(_ mapRectRotated: MKMapRectRotated, point: MKMapPoint) -> MKMapPoint {
    let dxCenter = (point.x - mapRectRotated.rectCenter.x)
    let dyCenter = (point.y - mapRectRotated.rectCenter.y)

    /*
        We use a dot product against a unit vector (a.k.a. projection) to find
        distance "along a particular direction."
    */
    let widthDistance = dxCenter * mapRectRotated.widthDirection.eX + dyCenter * mapRectRotated.widthDirection.eY

    /*
        We use a dot product against a unit vector (a.k.a. projection) to find
        distance "along a particular direction."
    */
    let heightDistance = dxCenter * mapRectRotated.heightDirection.eX + dyCenter * mapRectRotated.heightDirection.eY

    // "If this rectangle _were_ upright, this would be the result."
    let widthNearestPoint  = clamp(widthDistance,  min: -0.5 * mapRectRotated.rectSize.width,  max: 0.5 * mapRectRotated.rectSize.width)
    let heightNearestPoint = clamp(heightDistance, min: -0.5 * mapRectRotated.rectSize.height, max: 0.5 * mapRectRotated.rectSize.height)

    /*
        Since it's not upright, just combine the width and height in their
        corresponding directions!
    */
    let mapPointX = mapRectRotated.rectCenter.x + widthNearestPoint * mapRectRotated.widthDirection.eX + heightNearestPoint * mapRectRotated.heightDirection.eX
    let mapPointY = mapRectRotated.rectCenter.y + widthNearestPoint * mapRectRotated.widthDirection.eY + heightNearestPoint * mapRectRotated.heightDirection.eY
    return MKMapPoint(x: mapPointX, y: mapPointY)
}

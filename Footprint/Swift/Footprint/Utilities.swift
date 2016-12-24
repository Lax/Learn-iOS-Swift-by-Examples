/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This contains several utility methods and extensions
*/
import Foundation
import MapKit

/**
    - parameter a:
    - parameter b:
    - note: If numbers are the same, always chooses first
    - returns: the SMALLER of the two numbers (not the minimum) e.g. 
            smallest(-5.0, 0.01) returns 0.01.
*/
func smallest(_ a: Double, b: Double) -> Double {
    return (fabs(a) <= fabs(b)) ? a: b
}

/**
    - parameter val: value to clamp.
    - parameter min: least possible value.
    - parameter max: greatest possible value.

    - returns: clamped version of val such that it falls between min and max.
*/
func clamp(_ val: Double, min: Double, max: Double) -> Double {
    return (val < min) ? min : ((val > max) ? max : val)
}

extension MKMapPoint {
    /**
        - parameter a: Point A.
        - parameter b: Point B.
        - returns: An MKMapPoint object representing the midpoints of a and b.
    */
    static func midpoint(_ a: MKMapPoint, b: MKMapPoint) -> MKMapPoint {
        return MKMapPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
    }

    /**
        - parameter other: ending point.
        - returns: The MKMapPointDisplacement between two MKMapPoint objects.
    */
    func displacementToPoint(_ other: MKMapPoint) -> MKMapPointDisplacement {
        let dx = (other.x - x)
        let dy = (other.y - y)
        let distance = hypot(dx, dy)

        return MKMapPointDisplacement(direction: MKMapDirection(eX: dx/distance, eY: dy/distance), distance: distance)
    }
}

extension CLLocationDistance {
    /**
        - parameter a: coordinate A.
        - parameter b: coordinate B.
        - returns: The distance between the two coordinates.
    */
    static func distanceBetweenLocationCoordinates2D(_ a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> CLLocationDistance {

        let locA: CLLocation = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB: CLLocation = CLLocation(latitude: b.latitude, longitude: b.longitude)

        return locA.distance(from: locB)
    }
}

extension CGPoint {
    /**
        - parameter a: point A.
        - parameter b: point B.
        - returns: the mean point of the two CGPoint objects.
    */
    static func pointAverage(_ a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPoint(x:(a.x + b.x) * 0.5, y:(a.y + b.y) * 0.5)
    }
}

extension CGVector {
    /**
        - parameter other: a vector.
        - returns: the dot product of the other vector with this vector.
    */
    func dotProductWithVector(_ other: CGVector) -> CGFloat {
        return dx * other.dx + dy * other.dy
    }


    /**
        - parameter scale: how much to scale (e.g. 1.0, 1.5, 0.2, etc).
        - returns: a copy of this vector, rescaled by the amount given.
    */
    func scaledByFloat(_ scale: CGFloat) -> CGVector {
        return CGVector(dx: dx * scale, dy: dy * scale)
    }

    /**
        - parameter radians: how many radians you want to rotate by.
        - returns: a copy of this vector, after being rotated in the
                "positive radians" direction by the amount given.
        - note: If your coordinate frame is right-handed, positive radians
            is counter-clockwise.
    */
    func rotatedByRadians(_ radians: CGFloat) -> CGVector {
        let cosRadians = cos(radians)
        let sinRadians = sin(radians)

        return CGVector(dx: cosRadians * dx - sinRadians * dy, dy: sinRadians * dx + cosRadians * dy)
    }
}

extension CGPoint {
    /**
        - parameter a: point A.
        - parameter b: point B.
        - returns: The hypotenuse defined by the two.
    */
    static func hypotenuse(_ a: CGPoint, b: CGPoint) -> Double {
        return Double(hypot(b.x - a.x, b.y - a.y))
    }
}

extension MKMapRect {
    /**
        - returns: The point at the center of the rectangle.
        - parameter rect: A rectangle.
    */
    func getCenter() -> MKMapPoint {
        return MKMapPointMake(MKMapRectGetMidX(self), MKMapRectGetMidY(self))
    }

    /**
        - parameter rect: a rectangle.
        - returns: an MKMapRect converted to an MKPolygon.
    */
    func polygonFromMapRect() -> MKPolygon {
        var corners =  [MKMapPointMake(MKMapRectGetMaxX(self),  MKMapRectGetMaxY(self)),
                        MKMapPointMake(MKMapRectGetMinX(self),  MKMapRectGetMaxY(self)),
                        MKMapPointMake(MKMapRectGetMinX(self),  MKMapRectGetMinY(self)),
                        MKMapPointMake(MKMapRectGetMaxX(self),  MKMapRectGetMinY(self))]

        return MKPolygon(points: &corners, count: corners.count)
    }
}

extension MKMapSize {
    /// - returns: The area of this MKMapSize object
    func area() -> Double {
        return height * width
    }
}

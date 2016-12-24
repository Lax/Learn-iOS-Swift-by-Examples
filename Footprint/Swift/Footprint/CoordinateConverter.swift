/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class converts PDF coordinates of a floorplan to Geographic
                coordinates on Earth.
                    NOTE: This class can also be used for any "right-handed"
                    coordinate system (other than PDF) but should not be used as-is
                    for "Raster image" coordinates (such as PNGs or JPEGs) because
                    those require left-handed coordinate frames.
                    There are other reasons we discourage the use of raster images
                    as indoor floorplans. See the code  comments inside
                    FloorplanOverlay init for more info.
*/

import CoreLocation
import Foundation
import MapKit

/**
    - note: In iOS, the term "pixel" usually refers to screen pixels whereas the
       term "point" is used to describe coordinates inside a visual/image asset.

    For more information, see: "Points Versus Pixels" on developer.apple.com

    This class matches a specific latitude & longitude (a coordinate on Earth)
    to a specifc x,y coordinate (a position on your floorplan PDF).

    PDFs are defined in a coordinate system where +y is counter-clockwise of +x
    (a.k.a. "a right handed coordinate system"). PDF coordinates

    - parameter latitudeLongitude: The lat-lon coordinate for this anchor
    - parameter pdfPoint: corresponding PDF coordinate
*/
struct GeoAnchor {
    var latitudeLongitudeCoordinate = CLLocationCoordinate2D()
    var pdfPoint = CGPoint.zero
}

/**
    Defines a pair of GeoAnchors

    - parameter fromAnchor: starting anchor
    - parameter toAnchor: ending anchor
*/
struct GeoAnchorPair {
    var fromAnchor = GeoAnchor()
    var toAnchor = GeoAnchor()
}

/**
    This class converts PDF coordinates of a floorplan to Geographic coordinates
    on Earth.

    **This class can also be used for any "right-handed" coordinate system
    (other than PDF) but should not be used as-is for "Raster image" coordinates
    (such as PNGs or JPEGs) because those require left-handed coordinate frames.
    There are other reasons we discourage the use of raster images as indoor
    floorplans. See the code & comments inside FloorplanOverlay init for more
    info.**
*/
class CoordinateConverter: NSObject {

    /// The GeoAnchorPair used to define this converter
    var anchors: GeoAnchorPair = GeoAnchorPair()

    /**
        This vector, expressed in points (PDF coordinates), has length one meter
        and direction due East.
    */
    fileprivate var oneMeterEastwardVector: CGVector

    /**
        This vector, expressed in points (PDF coordinates), has length one meter
        and direction due South.
    */
    fileprivate var oneMeterSouthwardVector: CGVector

    /**
        This coordinate, expressed in points (PDF coordinates), corresponds to
        exactly the same location as tangentLatLng
    */
    fileprivate var tangentPDFPoint: CGPoint

    /**
        This coordinate, expressed in latitude & longitude (global coordinates),
        corresponds to exactly the same location as tangentPoint
    */
    fileprivate var tangentLatitudeLongitudeCoordinate: CLLocationCoordinate2D

    /**
        Initializes this class from a given GeoAnchorPair
    
        - parameter Anchors: the anchors that this class will use for converting
    */
    init(anchors: GeoAnchorPair) {
        self.anchors = anchors

        /*
            Next, to compute the direction between two geographical coordinates,
            we first need to convert to MapKit coordinates...
        */
        let fromAnchorMercatorCoordinate = MKMapPointForCoordinate(anchors.fromAnchor.latitudeLongitudeCoordinate)
        let toAnchorMercatorCoordinate = MKMapPointForCoordinate(anchors.toAnchor.latitudeLongitudeCoordinate)

        let pdfDisplacement = CGPoint(x: anchors.toAnchor.pdfPoint.x - anchors.fromAnchor.pdfPoint.x, y: anchors.toAnchor.pdfPoint.y - anchors.fromAnchor.pdfPoint.y)

        /*
            ...so that we can use MapKit's Mercator coordinate system where +x
            is always eastward and +y is always southward. Imagine an arrow
            connecting fromAnchor to toAnchor...
        */
        let anchorDisplacementMapKitX = (toAnchorMercatorCoordinate.x - fromAnchorMercatorCoordinate.x)
        let anchorDisplacementMapKitY = (toAnchorMercatorCoordinate.y - fromAnchorMercatorCoordinate.y)

        /*
            What is the angle of this arrow (geographically)?
            atan2 always returns:
              exactly 0.0 radians if the arrow is exactly in the +x direction
                    ("MapKit's +x" is due East).
              positive radians as the arrow is rotated toward and through the +y
                    direction ("MapKit's +y" is due South).
            In the case of MapKit, this is radians clockwise from due East.
        */
        let radiansClockwiseOfDueEast = atan2(anchorDisplacementMapKitY, anchorDisplacementMapKitX)

        /*
            That means if we rotate pdfDisplacement COUNTER-clockwise by this
            value, it will be facing due east. In the CG coordinate frame,
            positive radians is counter-clockwise because in a PDF +x is
            rightward and +y is upward.
        */
        let cgDueEast = CGVector(dx: pdfDisplacement.x, dy: pdfDisplacement.y).rotatedByRadians(CGFloat(radiansClockwiseOfDueEast))

        // Now, get the distance (in meters) between the two anchors...
        let distanceBetweenAnchorsMeters = CLLocationDistance.distanceBetweenLocationCoordinates2D(anchors.fromAnchor.latitudeLongitudeCoordinate, b: anchors.toAnchor.latitudeLongitudeCoordinate)

        // ...and rescale so that it's exactly one meter in length.
        oneMeterEastwardVector = cgDueEast.scaledByFloat(CGFloat(1.0 / distanceBetweenAnchorsMeters))

        /*
            Lastly, due south is PI/2 clockwise of due east.
            In the CG coordinate frame, clockwise rotation is NEGATIVE radians
            because in a PDF +x is rightward and +y is upward.
        */
        oneMeterSouthwardVector = oneMeterEastwardVector.rotatedByRadians(CGFloat(-M_PI_2))

        /*
            We'll choose the midpoint between the two anchors to be our "tangent
            point". This is the MKMapPoint that will correspond to both
            tangentLatitudeLongitudeCoordinate on Earth and _tangentPDFPoint
            in the PDF.
        */
        let tangentMercatorCoordinate = MKMapPoint.midpoint(fromAnchorMercatorCoordinate, b: toAnchorMercatorCoordinate)

        tangentLatitudeLongitudeCoordinate = MKCoordinateForMapPoint(tangentMercatorCoordinate)

        tangentPDFPoint = CGPoint.pointAverage(anchors.fromAnchor.pdfPoint, b: anchors.toAnchor.pdfPoint)

    }

    /**
        Calculate the MKMapPoint from a specific PDF coordinate
    
        - parameter pdfPoint: starting point in the PDF
        - returns: The corresponding MKMapPoint
    */
    func MKMapPointFromPDFPoint(_ pdfPoint: CGPoint) -> MKMapPoint {
        /*
            To perform this conversion, we start by seeing how far we are from
            the tangentPoint. The tangentPoint is the one place on the PDF where
            we know exactly the corresponding Earth latitude & lontigude.
        */
        let displacementFromTangentPoint = CGVector(dx: pdfPoint.x - tangentPDFPoint.x, dy: pdfPoint.y - tangentPDFPoint.y)

        // Now, let's figure out how far East & South we are from this point.
        let dotProductEast  = displacementFromTangentPoint.dotProductWithVector(oneMeterEastwardVector)
        let dotProductSouth = displacementFromTangentPoint.dotProductWithVector(oneMeterSouthwardVector)

        let eastSouthDistanceMeters = (
                                        east: CLLocationDistance(dotProductEast / oneMeterEastwardVector.dotProductWithVector(oneMeterEastwardVector)),
                                        south: CLLocationDistance(dotProductSouth / oneMeterSouthwardVector.dotProductWithVector(oneMeterSouthwardVector))
                                      )

        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(tangentLatitudeLongitudeCoordinate.latitude)
        let tangentMercatorCoordinate = MKMapPointForCoordinate(tangentLatitudeLongitudeCoordinate)

        /*
            Each meter is about (1.0 / metersPerMapPoint) 'MKMapPoint's, as long
            as we are nearby _tangentLatLng. So just move this many meters East
            and South and we're done!
        */
        return MKMapPoint(x: tangentMercatorCoordinate.x + eastSouthDistanceMeters.east / metersPerMapPoint,
                          y: tangentMercatorCoordinate.y + eastSouthDistanceMeters.south / metersPerMapPoint)
    }

    /**
        - returns: a single CGAffineTransform that can transform any CGPoint in
                    a PDF into its corresponding MKMapPoint.

        In theory, the following equalities should always hold:

            CGPointApplyAffineTransform(pdfPoint, transformerFromPDFToMk).x 
                    == MKMapPointFromPDFPoint(pdfPoint).x
            CGPointApplyAffineTransform(pdfPoint, transformerFromPDFToMk).y
                    == MKMapPointFromPDFPoint(pdfPoint).y

        However, in practice we find that MKMapPointFromPDFPoint can be slightly
        more accurate than transformerFromPDFToMk due to hardware acceleration
        and/or numerical precision losses of CGAffineTransform operations.
    */
    func transformerFromPDFToMk() -> CGAffineTransform {
        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(tangentLatitudeLongitudeCoordinate.latitude)
        let tangentMercatorCoordinate = MKMapPointForCoordinate(tangentLatitudeLongitudeCoordinate)

        /*
            CGAffineTransform operations are easier to construct in reverse-order.
            Start with the last operation:
        */
        let resultOfTangentMercatorCoordinate = CGAffineTransform(translationX: CGFloat(tangentMercatorCoordinate.x), y: CGFloat(tangentMercatorCoordinate.y))

        /*
            Revise the AffineTransform to first scale by 
            (1.0 / metersPerMapPoint), and then perform the above translation.
        */
        let resultOfEastSouthDistanceMeters = resultOfTangentMercatorCoordinate.scaledBy(x: CGFloat(1.0 / metersPerMapPoint), y: CGFloat(1.0 / metersPerMapPoint))

        /*
            Revise the AffineTransform to first scale by 
            (1.0 / dotProduct(...)) before performing the transform so far.
        */
        let resultOfDotProduct = resultOfEastSouthDistanceMeters.scaledBy(x: 1.0 / oneMeterEastwardVector.dotProductWithVector(oneMeterEastwardVector),
            y: 1.0 / oneMeterSouthwardVector.dotProductWithVector(oneMeterSouthwardVector))

        /*
            Revise the AffineTransform to first perform dot products aginst our
            reference vectors before performing the  transform so far.
        */
        let resultOfDisplacementFromTangentPoint = CGAffineTransform(
            a: oneMeterEastwardVector.dx, b: oneMeterEastwardVector.dy,
            c: oneMeterSouthwardVector.dx, d: oneMeterSouthwardVector.dy,
            tx: 0.0, ty: 0.0
            ).concatenating(resultOfDotProduct
        )

        /*
            Lastly, revise the AffineTransform to first perform the initial
            subtraction before performing the remaining operations.
            Each meter is about (1.0 / metersPerMapPoint) 'MKMapPoint's, as long
            as we are nearby tangentLatitudeLongitudeCoordinate.
        */
        return resultOfDisplacementFromTangentPoint.translatedBy(x: -tangentPDFPoint.x, y: -tangentPDFPoint.y)
    }

    /// - returns: the size in meters of 1.0 CGPoint distance
    var unitSizeInMeters: CLLocationDistance {
        return CLLocationDistance(1.0 / hypot(oneMeterEastwardVector.dx, oneMeterEastwardVector.dy))
    }

    /**
        Converts each corner of a PDF rectangle into an MKMapPoint (in MapKit
        space). The collection of MKMapPoints is returned as an MKPolygon
        overlay.
    
        - parameter pdfRect: A PDF rectangle
        - returns: the corners of the PDF in an MKPolygon (obviously there
                            should be four points since it's a rectangle)
    */
    func polygonFromPDFRectCorners(_ pdfRect: CGRect) -> MKPolygon {
        var corners = [ MKMapPointFromPDFPoint(CGPoint(x: pdfRect.maxX, y: pdfRect.maxY)),
                        MKMapPointFromPDFPoint(CGPoint(x: pdfRect.minX, y: pdfRect.maxY)),
                        MKMapPointFromPDFPoint(CGPoint(x: pdfRect.minX, y: pdfRect.minY)),
                        MKMapPointFromPDFPoint(CGPoint(x: pdfRect.maxX, y: pdfRect.minY))]

        return MKPolygon(points: &corners, count: corners.count)
    }

    /**
        - returns: the smallest MKMapRect that can show all rotations of the 
                given PDF rectangle.
    */
    func boundingMapRectIncludingRotations(_ rect: CGRect) -> MKMapRect {
        // Start with the nominal rendering box for this rect is.
        let nominalRenderingRect = polygonFromPDFRectCorners(rect).boundingMapRect

        /*
            In order to account for all rotations, any bounding map rect must
            have diameter equal to the longest distance inside the rectangle.
        */
        let boundsDiameter = hypot(nominalRenderingRect.size.width, nominalRenderingRect.size.height)

        let rectCenterPoints = CGPoint(x: rect.midX, y: rect.midY)

        let boundsCenter = MKMapPointFromPDFPoint(rectCenterPoints)

        /*
            Return a square MKMapRect centered at boundsCenterMercator with edge
            length diameterMercator
        */
        return MKMapRectMake(
            boundsCenter.x - boundsDiameter / 2.0,
            boundsCenter.y - boundsDiameter / 2.0,
            boundsDiameter, boundsDiameter)
    }

    /**
        - returns: the MKMapCamera heading required to display your PDF (user
                space) coordinate system upright so that PDF +x is rightward and
                PDF +y is upward.
    */
    func getUprightMKMapCameraHeading() -> CLLocationDirection {
        /*
            To make the floorplan upright, we want to rotate the floorplan +x
            vector toward due east.
        */
        let resultRadians: CGFloat = atan2(oneMeterEastwardVector.dy, oneMeterEastwardVector.dx)
        let result = resultRadians * 180.0 / CGFloat(M_PI)

        /*
            According to the CLLocationDirection documentation we must store a
            positive value if it is valid.
        */
        if result < 0.0 {
            return CLLocationDirection(result + 360.0)
        } else {
            return CLLocationDirection(result)
        }
    }
    
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class converts PDF coordinates of a floorplan to Geographic coordinates on Earth. NOTE: This class can also be used for any "right-handed" coordinate system (other than PDF) but should not be used as-is for "Raster image" coordinates (such as PNGs or JPEGs) because those require left-handed coordinate frames.
    
                There are other reasons we discourage the use of raster images as indoor floorplans. See the code  comments inside AAPLFloorplanOverlay initWithFloorplanURL: for more info.
*/

#import "AAPLCoordinateConverter.h"
@import MapKit;

/**
    @param a a vector.
    @param b a vector.
    @return the dot product of the two input vectors.
*/
static CGFloat AAPLCGVectorDot(CGVector a, CGVector b) {
    return a.dx * b.dx + a.dy * b.dy;
}

/**
    @param v the initial vector.
    @param scale how much to scale (e.g. 1.0, 1.5, 0.2, etc).
    @return a copy of the input vector, rescaled by the amount given.
*/
static CGVector AAPLCGVectorScaled(CGVector v, CGFloat scale) {
    return (CGVector) {
        .dx = v.dx * scale,
        .dy = v.dy * scale
    };
}

/**
    @param v the initial vector.
    @param radians how many radians you want to rotate by.
    @return a copy of the input vector, after being rotated in the "positive
        radians" direction by the amount given.
*/
static CGVector AAPLCGVectorRotatedRadians(CGVector v, CGFloat radians) {
    CGFloat cosRadians = cos(radians);
    CGFloat sinRadians = sin(radians);

    return (CGVector) {
        .dx = +cosRadians * v.dx  -sinRadians * v.dy,
        .dy = +sinRadians * v.dx  +cosRadians * v.dy,
    };
}

/**
    @param a Point A.
    @param b Point B.
    @return The midpoint between A and B.
*/
static MKMapPoint AAPLMKMapPointMidpoint(MKMapPoint a, MKMapPoint b) {
    return (MKMapPoint) {
        .x = (a.x + b.x) * 0.5,
        .y = (a.y + b.y) * 0.5
    };
}

/**
    @param a point A.
    @param b point B.
    @return the mean of the two CGPoint objects.
*/
static CGPoint AAPLCGPointAverage(CGPoint a, CGPoint b) {
    return (CGPoint) {
        .x = (a.x + b.x) * 0.5,
        .y = (a.y + b.y) * 0.5
    };
}

/**
    @param a coordinate A.
    @param b coordinate B.
    @return The distance between the two coordinates in meters.
*/
static CLLocationDistance AAPLCLDistanceBetweenLocationCoordinates2D(CLLocationCoordinate2D a, CLLocationCoordinate2D b) {

    CLLocation *locA = [[CLLocation alloc]initWithLatitude:a.latitude longitude:a.longitude];
    CLLocation *locB = [[CLLocation alloc]initWithLatitude:b.latitude longitude:b.longitude];

    return [locA distanceFromLocation:locB];
}

/**
    Struct that contains a position in meters (east and south) with respect to
    an origin position (in geographic space). We use East & South because
    \c MKMapPoint's x value is positive in the Eastward direction and
    \c MKMapPoint's y value is positive in the Southward direction.

    @param east The distance eastward.
    @param south The distance southward.
*/
typedef struct {
    CLLocationDistance east;
    CLLocationDistance south;
} AAPLEastSouthDistance;


@implementation AAPLCoordinateConverter

- (instancetype)initWithAnchorPair:(AAPLGeoAnchorPair)anchors {
    self = [super init];
    if (self) {
        _anchors = anchors;

        /*
            Next, to compute the direction between two geographical
            co-ordinates, we first need to convert to MapKit coordinates...
         */
        MKMapPoint fromAnchorMercatorCoordinate = MKMapPointForCoordinate(anchors.fromAnchor.latitudeLongitude);
        MKMapPoint toAnchorMercatorCoordinate = MKMapPointForCoordinate(anchors.toAnchor.latitudeLongitude);

        CGVector pdfDisplacement = {
            .dx = anchors.toAnchor.PDFPoint.x - anchors.fromAnchor.PDFPoint.x,
            .dy = anchors.toAnchor.PDFPoint.y - anchors.fromAnchor.PDFPoint.y
        };

        // ... so that we can use MapKit's Mercator coordinate system where +x is always eastward and +y is always southward.

        // Imagine an arrow connecting fromAnchor to toAnchor...
        double anchorDisplacementMapkitX = (toAnchorMercatorCoordinate.x - fromAnchorMercatorCoordinate.x);
        double anchorDisplacementMapkitY = (toAnchorMercatorCoordinate.y - fromAnchorMercatorCoordinate.y);

        /*
            What is the angle of this arrow (geographically)?
            atan2 always returns:
                exactly 0.0 radians if the arrow is exactly in the +x direction
                    ("MapKit's +x" is due East).
                positive radians as the arrow is rotated toward and through the
                    +y direction ("MapKit's +y" is due South).
            In the case of MapKit, this is radians clockwise from due East.
         */
        float radiansClockwiseOfDueEast = atan2(anchorDisplacementMapkitY, anchorDisplacementMapkitX);

        /*
            That means if we rotate cgDisplacement COUNTER-clockwise by this
            value, it will be facing due east. In the CG coordinate frame,
            positive radians is counter-clockwise because in a PDF +x is
            rightward and +y is upward.
         */
        CGVector cgDueEast = AAPLCGVectorRotatedRadians(pdfDisplacement, radiansClockwiseOfDueEast);

        // Now, get the distance (in meters) between the two anchors...
        CLLocationDistance distanceBetweenAnchorsMeters = AAPLCLDistanceBetweenLocationCoordinates2D(anchors.fromAnchor.latitudeLongitude, anchors.toAnchor.latitudeLongitude);

        // ...and rescale so that it's exactly one meter in length.
        _oneMeterEastward = AAPLCGVectorScaled(cgDueEast, 1.0 / distanceBetweenAnchorsMeters);

        /*
            Lastly, due south is PI/2 clockwise of due east.
            In the CG coordinate frame, clockwise rotation is NEGATIVE radians
            because in a PDF +x is rightward and +y is upward.
         */
        _oneMeterSouthward = AAPLCGVectorRotatedRadians(_oneMeterEastward, -M_PI_2);

        /*
            We'll choose the midpoint between the two anchors to be our "tangent
            point". This is the MKMapPoint that will correspond to both
            _tangentLatitudeLongitude on Earth and _tangentPDFPoint in the PDF.
         */
        MKMapPoint tangentMercatorCoordinate = AAPLMKMapPointMidpoint(fromAnchorMercatorCoordinate, toAnchorMercatorCoordinate);

        _tangentLatitudeLongitude = MKCoordinateForMapPoint(tangentMercatorCoordinate);

        _tangentPDFPoint = AAPLCGPointAverage(anchors.fromAnchor.PDFPoint, anchors.toAnchor.PDFPoint);

    }

    return self;
}

- (MKMapPoint)MKMapPointFromPDFPoint:(CGPoint)PDFPoint {
    /*
        To perform this conversion, we start by seeing how far we are from the
        tangentPoint. The tangentPoint is the one place on the PDF where we know
        exactly the corresponding Earth latitude & lontigude.
     */
    CGVector displacementFromTangentPoint = CGVectorMake(PDFPoint.x - self.tangentPDFPoint.x, PDFPoint.y - self.tangentPDFPoint.y);

    // Now, let's figure out how far East & South we are from this tangentPoint.

    CGFloat dotProductEast = AAPLCGVectorDot(displacementFromTangentPoint, _oneMeterEastward);
    CGFloat dotProductSouth = AAPLCGVectorDot(displacementFromTangentPoint, _oneMeterSouthward);

    AAPLEastSouthDistance eastSouthDistanceMeters = {
        // How many meters Eastward is cgPoint from tangentPoint?
        .east = dotProductEast / AAPLCGVectorDot(_oneMeterEastward, _oneMeterEastward),

        // How many meters Southward is cgPoint from tangentPoint?
        .south = dotProductSouth / AAPLCGVectorDot(_oneMeterSouthward, _oneMeterSouthward)
    };


    CLLocationDistance metersPerMapPoint = MKMetersPerMapPointAtLatitude(self.tangentLatitudeLongitude.latitude);
    MKMapPoint tangentMercatorCoordinate = MKMapPointForCoordinate(self.tangentLatitudeLongitude);

    /*
        Each meter is about (1.0 / metersPerMapPoint) MKMapPoints, as long as we
        are nearby _tangentLatitudeLongitude. So just move this many meters East
        and South and we're done!
     */
    MKMapPoint result = {
        .x = tangentMercatorCoordinate.x + eastSouthDistanceMeters.east / metersPerMapPoint,
        .y = tangentMercatorCoordinate.y + eastSouthDistanceMeters.south / metersPerMapPoint,
    };

    return result;

}

- (CGAffineTransform)PDFToMapKitAffineTransform {
    CLLocationDistance metersPerMapPoint = MKMetersPerMapPointAtLatitude(self.tangentLatitudeLongitude.latitude);
    MKMapPoint tangentMercatorCoordinate = MKMapPointForCoordinate(self.tangentLatitudeLongitude);

    /*
        CGAffineTransform operations easier to construct in reverse-order.
        Start with the last operation:
     */
    CGAffineTransform resultOfTangentMercatorCoordinate = CGAffineTransformMakeTranslation(tangentMercatorCoordinate.x, tangentMercatorCoordinate.y);

    /*
        Revise the CGAffineTransform to first scale by
        (1.0 / metersPerMapPoint), and then perform the above translation.
     */
    CGAffineTransform resultOfEastSouthDistanceMeters = CGAffineTransformScale(resultOfTangentMercatorCoordinate, 1.0 / metersPerMapPoint, 1.0 / metersPerMapPoint);

    /*
        Revise the AffineTransform to first scale by 
        (1.0 / AAPLCGVectorDot(...)) before performing the transform so far.
     */
    CGAffineTransform resultOfDotProduct =
        CGAffineTransformScale(
            resultOfEastSouthDistanceMeters,
            1.0 / AAPLCGVectorDot(_oneMeterEastward, _oneMeterEastward),
            1.0 / AAPLCGVectorDot(_oneMeterSouthward, _oneMeterSouthward)
        );

    /*
        Revise the affine transform to first perform dot products against our
        reference vectors before performing the  transform so far.
     */
    CGAffineTransform resultOfDisplacementFromTangentPoint =
        CGAffineTransformConcat(
            CGAffineTransformMake(
                _oneMeterEastward.dx, _oneMeterEastward.dy,
                _oneMeterSouthward.dx, _oneMeterSouthward.dy,
                0.0, 0.0
            ),
            resultOfDotProduct
        );

    /*
        Lastly, revise the CGAffineTransform to first perform the initial
        subtraction before performing the remaining operations.

        Each meter is about (1.0 / metersPerMapPoint) MKMapPoints, as
        long as we are nearby _tangentLatitudeLongitude.
     */
    return CGAffineTransformTranslate(
        resultOfDisplacementFromTangentPoint,
        - self.tangentPDFPoint.x,
        - self.tangentPDFPoint.y
    );
}

- (CLLocationDistance)unitSizeInMeters {
    return 1.0 / hypot(_oneMeterEastward.dx, _oneMeterEastward.dy);
}

- (MKPolygon *)polygonFromPDFRectCorners:(CGRect)pdfRect {
    MKMapPoint corners[4];
    corners[0] = [self MKMapPointFromPDFPoint:CGPointMake(CGRectGetMaxX(pdfRect), CGRectGetMaxY(pdfRect))];
    corners[1] = [self MKMapPointFromPDFPoint:CGPointMake(CGRectGetMinX(pdfRect), CGRectGetMaxY(pdfRect))];
    corners[2] = [self MKMapPointFromPDFPoint:CGPointMake(CGRectGetMinX(pdfRect), CGRectGetMinY(pdfRect))];
    corners[3] = [self MKMapPointFromPDFPoint:CGPointMake(CGRectGetMaxX(pdfRect), CGRectGetMinY(pdfRect))];
    return [MKPolygon polygonWithPoints:corners count:4];
}

- (MKMapRect)boundingMapRectIncludingRotations:(CGRect)rect {

    // Start with the nominal rendering box for this rect is.
    MKMapRect nominalRenderingRect = [self polygonFromPDFRectCorners:rect].boundingMapRect;

    /*
        In order to account for all rotations, any bounding map rect must have
        diameter equal to the longest distance inside the rectangle.
     */
    double boundsDiameter = hypot(nominalRenderingRect.size.width, nominalRenderingRect.size.height);

    CGPoint rectCenterPoints = {
        .x = CGRectGetMidX(rect),
        .y = CGRectGetMidY(rect)
    };

    MKMapPoint boundsCenter = [self MKMapPointFromPDFPoint:rectCenterPoints];

    /*
        Return a square MKMapRect centered at boundsCenterMercator with edge
        length diameterMercator.
     */
    return MKMapRectMake(
        boundsCenter.x - boundsDiameter / 2.0,
        boundsCenter.y - boundsDiameter / 2.0,
        boundsDiameter,
        boundsDiameter);
}

- (CLLocationDirection)uprightMKMapCameraHeading {
    /*
        To make the floorplan upright, we want to rotate the floorplan +x vector
        toward due east.
     */
    CGFloat resultRadians = atan2(_oneMeterEastward.dy, _oneMeterEastward.dx);
    CLLocationDirection result = resultRadians * 180.0 / M_PI;

    /*
        According to the CLLocationDirection documentation we must store a
        positive value if it is valid.
     */
    return (result < 0.0) ? (result + 360.0) : result;
}

@end

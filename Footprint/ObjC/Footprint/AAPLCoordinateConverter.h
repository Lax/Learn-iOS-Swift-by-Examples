/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class converts PDF coordinates of a floorplan to Geographic coordinates on Earth. NOTE: This class can also be used for any "right-handed" coordinate system (other than PDF) but should not be used as-is for "Raster image" coordinates (such as PNGs or JPEGs) because those require left-handed coordinate frames.
    
                There are other reasons we discourage the use of raster images as indoor floorplans. See the code  comments inside AAPLFloorplanOverlay initWithFloorplanURL: for more info.
*/

@import CoreLocation;
@import MapKit;
@import UIKit;

/**
    @note In iOS, the term "pixel" usually refers to screen pixels whereas the
       term "point" is used to describe coordinates inside a visual/image asset.

    For more information, see: "Points Versus Pixels" under 2DDrawing and 
    WindowsViews.

    This class matches a specific latitude & longitude (a coordinate on Earth)
    to a specifc x,y coordinate (a position on your floorplan PDF).

    PDFs are defined in a coordinate system where +y is counter-clockwise of +x
    (a.k.a. "a right handed coordinate system"). PDF coordinates.

    @param latitudeLongitude The latitude-longitude coordinate for this anchor.
    @param PDFPoint corresponding PDF coordinate.
 */
typedef struct {
    CLLocationCoordinate2D latitudeLongitude;
    CGPoint PDFPoint;
} AAPLGeoAnchor;

/**
    Defines a pair of \c AAPLGeoAnchors.

    @param fromAnchor starting anchor.
    @param toAnchor ending anchor.
*/
typedef struct {
    AAPLGeoAnchor fromAnchor;
    AAPLGeoAnchor toAnchor;
} AAPLGeoAnchorPair;

/**
    This class converts PDF coordinates of a floorplan to Geographic coordinates
    on Earth.

    @note This class can also be used for any "right-handed" coordinate system
        (other than PDF) but should not be used as-is for "Raster image"
        coordinates (such as PNGs or JPEGs) because those require left-handed
        coordinate frames. There are other reasons we discourage the use of
        raster images as indoor floorplans. See the code & comments inside 
        \c AAPLFloorplanOverlay initWithFloorplanURL for more info.
*/
@interface AAPLCoordinateConverter : NSObject

/**
    Initializes this class from a given \c AAPLGeoAnchorPair.

    @param anchors the anchors that this class will use for converting.
 
    @note This is the designated initializer. If you add any other initializers,
        make sure to annotate with \c NS_DESIGNATED_INITIALIZER.
*/
- (instancetype)initWithAnchorPair:(AAPLGeoAnchorPair)anchors;

/// The \c AAPLGeoAnchorPair used to define this converter.
@property (nonatomic, readonly) AAPLGeoAnchorPair anchors;

/**
    Calculate the \c MKMapPoint from a specific PDF coordinate.

    @param PDFPoint starting point in the PDF.
    @return The corresponding \c MKMapPoint.
*/
- (MKMapPoint)MKMapPointFromPDFPoint:(CGPoint)PDFPoint;

/**
    @return a single \c CGAffineTransform that can transform any \c CGPoint in a
        PDF into its corresponding \c MKMapPoint.

    In theory, the following equalities should always hold:

    \code
    CGPointApplyAffineTransform(PDFPoint, [self transformerFromPDFToMk]).x === [self MKMapPointFromPDFPoint:PDFPoint].x
     
    CGPointApplyAffineTransform(PDFPoint, [self transformerFromPDFToMk]).y === [self MKMapPointFromPDFPoint:PDFPoint].y
    \endcode

    However, in practice we find that \c MKMapPointFromPDFPoint can be slightly
    more accurate than \c transformerFromPDFToMk due to hardware acceleration
    and/or numerical precision losses of \c CGAffineTransform operations.
*/
@property (readonly) CGAffineTransform PDFToMapKitAffineTransform;

/// @return the size in meters of 1.0 \c CGPoint distance
@property (readonly) CLLocationDistance unitSizeInMeters;

/**
    This coordinate, expressed in latitude & longitude (global coordinates),
    corresponds to exactly the same location as \c tangentPDFPoint.
*/
@property (nonatomic, readonly) CLLocationCoordinate2D tangentLatitudeLongitude;

/**
    This vector, expressed in points (PDF coordinates), has length one meter
    and direction due East.
*/
@property (nonatomic, readonly) CGVector oneMeterEastward;

/**
    This vector, expressed in points (PDF coordinates), has length one meter
    and direction due South.
*/
@property (nonatomic, readonly) CGVector oneMeterSouthward;

/**
    This coordinate, expressed in points (PDF coordinates), corresponds to
    exactly the same location as \c tangentLatitudeLongitude.
*/
@property (nonatomic, readonly) CGPoint tangentPDFPoint;

/**
    Converts each corner of a PDF rectangle into an \c MKMapPoint
    (in MapKit space). The collection of \c MKMapPoints is returned as an 
    \c MKPolygon overlay.

    @param pdfRect A PDF rectangle.
    @return the corners of the PDF in an \c MKPolygon (obviously there should be
            four points since it's a rectangle).
*/
- (MKPolygon *)polygonFromPDFRectCorners:(CGRect)PDFRect;

/**
    @return the smallest \c MKMapRect that can show all rotations of the given
        PDF rectangle.
*/
- (MKMapRect)boundingMapRectIncludingRotations:(CGRect)PDFRect;

/** 
    @return the \c MKMapCamera heading required to display your PDF (user space)
    coordinate system upright so that PDF +x is rightward and PDF +y is upward.
*/
@property (readonly) CLLocationDirection uprightMKMapCameraHeading;

@end

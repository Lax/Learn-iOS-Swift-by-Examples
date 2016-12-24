/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class describes a floorplan for an indoor venue.
*/

#import "AAPLMKMapRectRotated.h"
#import "AAPLCoordinateConverter.h"

@import MapKit;

/// This class describes a floorplan for an indoor venue.
@interface AAPLFloorplanOverlay : NSObject <MKOverlay>

/**
    Same as boundingMapRect but slightly larger to fit on-screen under any \c MKMapCamera 
    rotation.
*/
@property (nonatomic, readonly) MKMapRect boundingMapRectIncludingRotations;

/**
    Cache the \c CGAffineTransform used to help draw the floorplan to the screen
    inside an \c MKMapView.
*/
@property (nonatomic, readonly) CGAffineTransform transformerFromPDFToMk;

/// Current floor level.
@property (nonatomic, readonly) NSInteger floorLevel;

/**
    Reference to the internal page data of the selected page of the PDF you are
    drawing. It is very likely that the PDF of your floorplan is a single page.
 */
@property (nonatomic, readonly) CGPDFPageRef PDFPage;

/**
    Same as \c boundingMapRect, but more precise. The \c AAPLMapRectRotated you'll
    get here fits snugly accounting for the rotation of the floorplan (relative 
    to North) whereas the \c boundingMapRect must be "North-aligned" since it's 
    an \c MKMapRect. If you're still not 100% sure, toggle the "debug switch" in 
    the sample code and look at the overlays that are drawn.
*/
@property (nonatomic, readonly) AAPLMKMapRectRotated floorplanPDFBox;

/// For debugging, remember the PDF page box selected at initialization.
@property (nonatomic, readonly) CGRect PDFBoxRect;

/// \c MKOverlay protocol return values.
@property (nonatomic, readonly) MKMapRect boundingMapRect;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

/**
    The coordinate converter for converting between PDF coordinates (point)
    and MapKit coordinates (\c MKMapPoint).
*/
@property (nonatomic, readonly) AAPLCoordinateConverter *coordinateConverter;

/**
    In this example, our floorplan is described by four things.
        1. The URL of a PDF. This is the visual data for the floorplan itself.
        2. The PDF page box to draw. This tells us which section of the PDF we
            will actually draw.
        3. A pair of anchors. This tells us where the floorplan appears in
            the real world.
        4. A floor level. This tells us which floor our floorplan represents.

    @param floorplanURL the path to a PDF containing the floorplan drawing.
    @param PDFBox which section of the PDF do we draw?
    @param anchors real-world anchors of this floorplan -- opposite corners.
    @param forFloorAtLevel which floor is it on?

    @note This is the designated initializer. If you add any other initializers,
            make sure to annotate with \c NS_DESIGNATED_INITIALIZER.
*/
- (instancetype)initWithFloorplanURL:(NSURL *)floorplanURL PDFBox:(CGPDFBox)PDFBox anchors:(AAPLGeoAnchorPair)anchors forFloorAtLevel:(NSInteger)level;

/**
    This is different from \c AAPLCoordinateConverter 
    \c getUprightMKMapCameraHeading because here we also account for the PDF 
    Page Dictionary's Rotate entry.

    @return the \c MKMapCamera heading needed to display your floorplan upright.
*/
@property (readonly) CLLocationDirection floorplanUprightMKMapCameraHeading;

/**
    Create an \c MKPolygon overlay given a custom \c CGPath (whose coordinates
    are specified in the PDF points).

    @param pdfPath an array of \c CGPoint, each element is a PDF coordinate
        along the path.
    @return A closed MapKit polygon made up of the points in the PDF path.
*/
- (MKPolygon *)polygonFromCustomPDFPath:(CGPoint *)pdfPath count:(size_t)count;

/**
    @return For debugging, you may want to draw the reference anchors that
        define this floor's coordinate converter.
*/
@property (readonly) AAPLGeoAnchorPair anchors;

/**
    @return For debugging, you may want to draw the the (0.0, 0.0) point of 
        the PDF.
*/
@property (readonly) MKMapPoint PDFOrigin;

/**
    @return For debugging, you may want to know the real-world coordinates of
        the PDF page box.
*/
@property (readonly, strong) MKPolygon *polygonFromFloorplanPDFBoxCorners;

/**
    @return For debugging, you may want to have the \c boundingMapRect in the
        form of an \c MKPolygon overlay.
*/
@property (readonly, strong) MKPolygon *polygonFromBoundingMapRect;

/**
    @return For debugging, you may want to have the
        \c boundingMapRectIncludingRotations in the form of 
        an \c MKPolygon overlay.
*/
@property (readonly, strong) MKPolygon *polygonFromBoundingMapRectIncludingRotations;

/**
    @return For debugging, you may want to know the real-world meters size of
        one PDF "point" distance.
*/
@property (readonly) CLLocationDistance PDFPointSizeInMeters;

@end

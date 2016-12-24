/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class describes a floorplan for an indoor venue.
*/

#import "AAPLFloorplanOverlay.h"

/**
    @return The point at the center of the rectangle.
    @param rect A rectangle.
*/
static MKMapPoint AAPLMKMapRectGetCenter(MKMapRect rect) {
    return MKMapPointMake(MKMapRectGetMidX(rect), MKMapRectGetMidY(rect));
}

/**
    @param rect a rectangle
    @return an \c MKMapRect converted to an \c MKPolygon.
*/
static MKPolygon *polygonFromMapRect(MKMapRect rect) {
    MKMapPoint corners[4];
    corners[0] = MKMapPointMake(MKMapRectGetMaxX(rect),  MKMapRectGetMaxY(rect));
    corners[1] = MKMapPointMake(MKMapRectGetMinX(rect),  MKMapRectGetMaxY(rect));
    corners[2] = MKMapPointMake(MKMapRectGetMinX(rect),  MKMapRectGetMinY(rect));
    corners[3] = MKMapPointMake(MKMapRectGetMaxX(rect),  MKMapRectGetMinY(rect));

    return [MKPolygon polygonWithPoints:corners count:4];
}

@implementation AAPLFloorplanOverlay {
    /// The PDF document to be rendered.
    CGPDFDocumentRef _PDFDoc;
}

- (instancetype)initWithFloorplanURL:(NSURL *)floorplanURL PDFBox:(CGPDFBox)pdfBox anchors:(AAPLGeoAnchorPair) anchors forFloorAtLevel:(NSInteger)level {

    // We only support PDF floorplans at this time.
    NSAssert([[floorplanURL absoluteString] hasSuffix:@"pdf"], @"Sanity check: The URL should point to a PDF file.");

    /*
        Using raster images (such as PNG or JPEG) would create a number of
        complications, such as:
        + you need multiple sizes of each image, and each would need its own
            AAPLGeoAnchorPair (see "Icon and Image Sizes" in MobileHIG
            for more).
        + raster/bitmap images use a different coordinate system than PDFs do,
            so the code from AAPLCoordinateConverter could not be used
            out-of-the-box. Instead, you would need a separate implementation of
            AAPLCoordinateConverter that works for left-handed coordinate
            frames. PDFs use a right-handed coordinate frame.
        + text and fine details of raster images may not render as clearly as
           vector images when zoomed in. PDF is primarily a vector image format.
        + some raster image formats, such as JPEG, are designed for photographs
            and may suffer from loss of detail due to compression artifacts when
            being used for floorplans.
     */

    self = [super init];
    if (self) {
        _coordinateConverter = [[AAPLCoordinateConverter alloc] initWithAnchorPair:anchors];
        _transformerFromPDFToMk = _coordinateConverter.PDFToMapKitAffineTransform;
        _floorLevel = level;

        /*
            Read the PDF file from disk into memory. Remember to CFRelease it
            when we dealloc.
            (see "The Create Rule" CFMemoryMgmt for more).
         */
        _PDFDoc = CGPDFDocumentCreateWithURL((__bridge CFURLRef)floorplanURL);

        /*
            In this example the floorplan PDF has only one page, so we pick
            "page 1" of the PDF.
         */
        _PDFPage = CGPDFDocumentGetPage(_PDFDoc, 1);

        // Figure out which region of the PDF is to be drawn.
        _PDFBoxRect = CGPDFPageGetBoxRect(_PDFPage, pdfBox);

        MKPolygon * polygonFromPDFRectCorners = [_coordinateConverter polygonFromPDFRectCorners:_PDFBoxRect];

        /*
            There is no need to display this floorplan if your MapView camera is
            beyond the four corners of the PDF page box.
            Thus, our boundingMapRect is based on the PDF page box corners.
         */
        _boundingMapRect = polygonFromPDFRectCorners.boundingMapRect;

        /*
            We need a quick way to check whether your screen is currently
            looking inside vs. outside the floorplan, in order to "clamp" your
            MKMapView.
         */
        assert(polygonFromPDFRectCorners.pointCount == 4);
        _floorplanPDFBox = AAPLMKMapRectRotatedMake(polygonFromPDFRectCorners.points[0],
                                                     polygonFromPDFRectCorners.points[1],
                                                     polygonFromPDFRectCorners.points[2],
                                                     polygonFromPDFRectCorners.points[3] );

        /*
            For the purposes of clamping MKMapCamera zoom, we need a slightly
            padded MKMapRect that allows the entire floorplan can be visible
            regardless of camera rotation.

            Otherwise, depending on the MKMapCamera rotation, auto-zoom might
            prevent the user from zooming out far enough to see the entire
            floorplan and/or auto-scroll might prevent the user from seeing the
            edge of the floorplan.
         */
        _boundingMapRectIncludingRotations = [_coordinateConverter boundingMapRectIncludingRotations:_PDFBoxRect];

        // For self.coordinate just return the centroid of self.boundingMapRect.
        _coordinate = MKCoordinateForMapPoint(AAPLMKMapRectGetCenter(_boundingMapRect));

    }
    return self;
}

-(void)dealloc {
    /*
        We are about to CFRelease _PDFDoc further below.
        Once that happens _PDFPage will no longer be valid, so let's clear it.
     */
    _PDFPage = nil;

    /*
        The only non Objective-C "Create" call in our designated initializer is
        _pdfDoc = CGPDFDocumentCreateWithURL(...)
        so remember to release it here.
     */
    if (_PDFDoc) {
        CFRelease(_PDFDoc);
    }
}

- (CLLocationDirection)floorplanUprightMKMapCameraHeading {
    /*
        Applying this heading to the MKMapCamera will cause PDF +x to face
        MapKit +x
     */
    CLLocationDirection rotatePdfXToMapKitX = self.coordinateConverter.uprightMKMapCameraHeading;

    /*
        If a PDF Page Dictionary contains the "Rotate" entry, it is a request to
        the reader to rotate the _printed_ page *clockwise* by the given number
        of degrees before reading it.
     */
    int PDFPageDictionaryRotationEntryDegrees = CGPDFPageGetRotationAngle(_PDFPage);

    /*
        In the MapView world that is equivalent to subtracting that amount from
        the MKMapCamera heading.
     */
    CLLocationDirection result = rotatePdfXToMapKitX - PDFPageDictionaryRotationEntryDegrees;

    /*
        According to the CLLocationDirection documentation we must store a
        positive value if it is valid.
     */
    return ((result < 0.0) ? (result + 360.0) : result);
}

- (MKPolygon *)polygonFromCustomPDFPath:(CGPoint *)pdfPath count:(size_t)count {
    // Create a temporary buffer.
    MKMapPoint *coords = calloc(count, sizeof(MKMapPoint));

    // Calculate the corresponding MKMapPoint for each PDF point.
    for (size_t i=0; i<count; ++i) {
        coords[i] = [self.coordinateConverter MKMapPointFromPDFPoint:pdfPath[i]];
    }

    // Construct the result.
    MKPolygon *result = [MKPolygon polygonWithPoints:coords count:count];

    // Cleanup and return.
    free(coords);

    return result;
}

- (AAPLGeoAnchorPair)anchors {
    return self.coordinateConverter.anchors;
}

- (MKMapPoint)PDFOrigin {
    return [self.coordinateConverter MKMapPointFromPDFPoint:CGPointZero];
}

- (MKPolygon *)polygonFromFloorplanPDFBoxCorners {
    return [self.coordinateConverter polygonFromPDFRectCorners:_PDFBoxRect];
}

- (MKPolygon *)polygonFromBoundingMapRect {
    return polygonFromMapRect(_boundingMapRect);
}

- (MKPolygon *)polygonFromBoundingMapRectIncludingRotations {
    return polygonFromMapRect(_boundingMapRectIncludingRotations);
}

- (CLLocationDistance)PDFPointSizeInMeters {
    return self.coordinateConverter.unitSizeInMeters;
}

@end

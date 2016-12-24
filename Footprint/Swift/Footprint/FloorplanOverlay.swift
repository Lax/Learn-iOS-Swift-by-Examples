/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class describes a floorplan for an indoor venue.
*/


import Foundation
import MapKit

/// This class describes a floorplan for an indoor venue.
@objc class FloorplanOverlay: NSObject, MKOverlay {

    /**
        Same as boundingMapRect but slightly larger to fit on-screen under
        any MKMapCamera rotation.
    */
    var boundingMapRectIncludingRotations = MKMapRect()

    /**
        Cache the CGAffineTransform used to help draw the floorplan to the
        screen inside an MKMapView.
    */
    var transformerFromPDFToMk = CGAffineTransform()

    /// Current floor level
    var floorLevel = 0

    /** 
        Reference to the internal page data of the selected page of the PDF you
        are drawing. It is very likely that the PDF of your floorplan is a 
        single page.
    */
    var pdfPage: CGPDFPage

    /**
        Same as boundingMapRect, but more precise.
        The AAPLMapRectRotated you'll get here fits snugly accounting for the 
        rotation of the floorplan (relative to North) whereas the 
        boundingMapRect must be "North-aligned" since it's an MKMapRect.
        If you're still not 100% sure, toggle the "debug switch" in the sample
        code and look at the overlays that are drawn.
    */
    var floorplanPDFBox: MKMapRectRotated

    /// The PDF document to be rendered.
    fileprivate var pdfDoc: CGPDFDocument

    /**
        The coordinate converter for converting between PDF coordinates (point)
        and MapKit coordinates (MKMapPoint).
    */
    fileprivate var coordinateConverter: CoordinateConverter

    /// For debugging, remember the PDF page box selected at initialization.
    fileprivate var pdfBoxRectangle = CGRect.null

    /// MKOverlay protocol return values.
    var boundingMapRect = MKMapRect()
    var coordinate = CLLocationCoordinate2D()

    /**
        In this example, our floorplan is described by four things.
            1. The URL of a PDF. This is the visual data for the floorplan.
            2. The PDF page box to draw. This tells us which section of the PDF
                    we will actually draw.
            3. A pair of anchors. This tells us where the floorplan appears in
                    the real world.
            4. A floor level. This tells us which floor our floorplan represents

        - parameter floorplanUrl: the path to a PDF containing the drawing of
                        the floorplan.
        - parameter pdfBox: which section of the PDF do we draw?
        - parameter andAnchors: real-world anchors of this floorplan
                        -- opposite corners.
        - parameter forFloorLevel: which floor is it on?
    */
    init(floorplanUrl: URL, withPDFBox pdfBox: CGPDFBox, andAnchors anchors: GeoAnchorPair, forFloorLevel level: NSInteger) {
        assert(floorplanUrl.absoluteString.hasSuffix("pdf"), "Sanity check: The URL should point to a PDF file")

        /*
            Using raster images (such as PNG or JPEG) would create a number of
            complications, such as:
             + you need multiple sizes of each image, and each would need its
                own GeoAnchorPair (see "Icon and Image Sizes" for iOS on 
                developer.apple.com for more).
             + raster/bitmap images use a different coordinate system than PDFs
                do, so the code from CoordinateConverter could not be used
                out-of-the-box. Instead, you would need a separate
                implementation of CoordinateConverter that works for left-handed
                coordinate frames. PDFs use a right-handed coordinate frame.
             + text and fine details of raster images may not render as clearly
                as vector images when zoomed in. PDF is primarily a vector image
                format.
             + some raster image formats, such as JPEG, are designed for
                photographs and may suffer from loss of detail due to
                compression artifacts when being used for floorplans.
        */
        coordinateConverter = CoordinateConverter(anchors: anchors)
        transformerFromPDFToMk = coordinateConverter.transformerFromPDFToMk()
        floorLevel = level

        /*
            Read the PDF file from disk into memory. Remember to CFRelease it
            when we dealloc.
            (see "The Create Rule" on developer.apple.com for more)
        */
        pdfDoc = CGPDFDocument(floorplanUrl as CFURL)!

        /*
            In this example the floorplan PDF has only one page, so we pick
            "page 1" of the PDF.
        */
        pdfPage = pdfDoc.page(at: 1)!

        // Figure out which region of the PDF is to be drawn.
        pdfBoxRectangle = pdfPage.getBoxRect(pdfBox)

        /*
            There is no need to display this floorplan if your MapView camera is
            beyond the four corners of the PDF page box. Thus, our
            boundingMapRect is based on the PDF page box corners in the
            MKMapPoint coordinate frame.
        */
        let polygonFromPDFRectCorners = coordinateConverter.polygonFromPDFRectCorners(pdfBoxRectangle)
        boundingMapRect = polygonFromPDFRectCorners.boundingMapRect

        /*
            We need a quick way to check whether your screen is currently
            looking inside vs. outside the floorplan, in order to "clamp" your
            MKMapView.
        */
        assert(polygonFromPDFRectCorners.pointCount == 4)
        let points = polygonFromPDFRectCorners.points()
        floorplanPDFBox = MKMapRectRotatedMake(points[0], corner2: points[1], corner3: points[2], corner4: points[3])

        /*
            For the purposes of clamping MKMapCamera zoom, we need a slightly 
            padded MKMapRect that allows the entire floorplan can be visible
            regardless of camera rotation. Otherwise, depending on the
            MKMapCamera rotation, auto-zoom might prevent the user from zooming
            out far enough to see the entire floorplan and/or auto-scroll might
            prevent the user from seeing the edge of the floorplan.
        */
        boundingMapRectIncludingRotations = coordinateConverter.boundingMapRectIncludingRotations(pdfBoxRectangle)

        // For coordinate just return the centroid of boundingMapRect
        coordinate = MKCoordinateForMapPoint(boundingMapRect.getCenter())
    }

    /**
        This is different from CoordinateConverter getUprightMKMapCameraHeading
        because here we also account for the PDF Page Dictionary's Rotate entry.

        - returns: the MKMapCamera heading required to display your *floorplan*
                upright.
    */
    func getFloorplanUprightMKMapCameraHeading() -> CLLocationDirection {
        /*
            Applying this heading to the MKMapCamera will cause PDF +x to face
            MapKit +x.
        */
        let rotatePDFXToMapKitX = coordinateConverter.getUprightMKMapCameraHeading()

        /*
            If a PDF Page Dictionary contains the "Rotate" entry, it is a
            request to the reader to rotate the _printed_ page *clockwise* by
            the given number of degrees before reading it.
        */
        let pdfPageDictionaryRotationEntryDegrees = pdfPage.rotationAngle

        /*
            In the MapView world that is equivalent to subtracting that amount
            from the MKMapCamera heading.
        */
        let result = CLLocationDirection(rotatePDFXToMapKitX) - CLLocationDirection(pdfPageDictionaryRotationEntryDegrees)

        /*
            According to the CLLocationDirection documentation we must store a
            positive value if it is valid.
        */
        return ((result < CLLocationDirection(0.0)) ? (result + CLLocationDirection(360.0)) : result)
    }

    /**
        Create an MKPolygon overlay given a custom CGPath (whose coordinates
        are specified in the PDF points)
        - parameter pdfPath: an array of CGPoint, each element is a PDF
            coordinate along the path.
        - returns: A closed MapKit polygon made up of the points in PDF path.
    */
    func polygonFromCustomPDFPath(_ pdfPath: [CGPoint]) -> MKPolygon {
        // Calculate the corresponding MKMapPoint for each PDF point.
        var coordinates = pdfPath.map { pathPoint in
            return coordinateConverter.MKMapPointFromPDFPoint(pathPoint)
        }

        return MKPolygon(points: &coordinates, count: coordinates.count)
    }

    /**
        For debugging, you may want to draw the reference anchors that define
        this floor's coordinate converter.
    */
    var geoAnchorPair: GeoAnchorPair {
        return coordinateConverter.anchors
    }

    /// For debugging, you may want to draw the the (0.0, 0.0) point of the PDF.
    var pdfOrigin: MKMapPoint {
        return coordinateConverter.MKMapPointFromPDFPoint(CGPoint.zero)
    }

    /**
        For debugging, you may want to know the real-world coordinates of the
        PDF page box.
    */
    var polygonFromFloorplanPDFBoxCorners: MKPolygon {
        return coordinateConverter.polygonFromPDFRectCorners(pdfBoxRectangle)
    }

    /**
        For debugging, you may want to have the boundingMapRect in the form of
        an MKPolygon overlay
    */
    var polygonFromBoundingMapRect: MKPolygon {
        return boundingMapRect.polygonFromMapRect()
    }

    /**
        For debugging, you may want to have the
        boundingMapRectIncludingRotations in the form of an MKPolygon overlay
    */
    var polygonFromBoundingMapRectIncludingRotations: MKPolygon {
        return boundingMapRectIncludingRotations.polygonFromMapRect()
    }

    /**
        For debugging, you may want to know the real-world meters size of one
        PDF "point" distance.
    */
    var pdfPointSizeInMeters: CLLocationDistance {
        return coordinateConverter.unitSizeInMeters
    }

}

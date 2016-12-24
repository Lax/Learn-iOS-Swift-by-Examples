/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class draws your FloorplanOverlay into an MKMapView.
                It is also capable of drawing diagnostic visuals to help with
                debugging, if needed.
*/

import Foundation
import MapKit

/**
    Should we show diagnostic visuals? Set this to false prior to compile to
    disable some of the diagnostic visuals
*/
let SHOW_DIAGNOSTIC_VISUALS = false

/**
    This class draws your FloorplanOverlay into an MKMapView.
    It is also capable of drawing diagnostic visuals to help with debugging,
    if needed.
*/
class FloorplanOverlayRenderer: MKOverlayRenderer {

    override init(overlay: MKOverlay) {
        super.init(overlay: overlay)
    }

    /**
        - note: Overrides the drawMapRect method for MKOverlayRenderer.
    */
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        assert(overlay.isKind(of: FloorplanOverlay.self), "Wrong overlay type")

        let floorplanOverlay = overlay as! FloorplanOverlay

        let boundingMapRect = overlay.boundingMapRect

        /*
            Mapkit converts to its own dynamic CGPoint frame, which we can read
            through rectForMapRect.
        */
        let mapkitToGraphicsConversion = rect(for: boundingMapRect)

        let graphicsFloorplanCenter = CGPoint(x: mapkitToGraphicsConversion.midX, y: mapkitToGraphicsConversion.midY)
        let graphicsFloorplanWidth = mapkitToGraphicsConversion.width
        let graphicsFloorplanHeight = mapkitToGraphicsConversion.height

        // Now, how does this compare to MapKit coordinates?
        let mapkitFloorplanCenter = MKMapPoint(x: MKMapRectGetMidX(overlay.boundingMapRect), y: MKMapRectGetMidY(overlay.boundingMapRect))

        let mapkitFloorplanWidth = MKMapRectGetWidth(overlay.boundingMapRect)
        let mapkitFloorplanHeight = MKMapRectGetHeight(overlay.boundingMapRect)

        /*
            Create the transformation that converts to Graphics coordinates from
            MapKit coordinates.

                graphics.x = (mapkit.x - mapkitFloorplanCenter.x) * 
                                graphicsFloorplanWidth / mapkitFloorplanWidth 
                                + graphicsFloorplanCenter.x
        */
        var fromMapKitToGraphics = CGAffineTransform.identity as CGAffineTransform

        fromMapKitToGraphics = fromMapKitToGraphics.translatedBy(x: CGFloat(-mapkitFloorplanCenter.x), y: CGFloat(-mapkitFloorplanCenter.y))
        fromMapKitToGraphics = fromMapKitToGraphics.scaledBy(x: graphicsFloorplanWidth / CGFloat(mapkitFloorplanWidth),
            y: graphicsFloorplanHeight / CGFloat(mapkitFloorplanHeight)
        )
        fromMapKitToGraphics = fromMapKitToGraphics.translatedBy(x: graphicsFloorplanCenter.x, y: graphicsFloorplanCenter.y)

        /*
            Using this, we can send draw commands in MapKit coordinates and
            cause the equivalent drawing in (the correct) graphics coordinates
            For additional debugging, uncomment the following two lines to
            highlight the floorplan's boundingMapRect in cyan.
        */
        if (SHOW_DIAGNOSTIC_VISUALS == true) {
            context.setFillColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 0.5)
            context.fill(mapkitToGraphicsConversion)
        }
        /*
            However, we want to be able to send draw commands in the original
            PDF coordinates though, so we'll also need the transformations that
            convert to MapKit coordinates from PDF coordinates.
        */
        let fromPDFToMapKit = floorplanOverlay.transformerFromPDFToMk

        context.concatenate(fromPDFToMapKit.concatenating(fromMapKitToGraphics))

        context.drawPDFPage(floorplanOverlay.pdfPage)

        /*
            The following diagnostic visuals are provided for debugging only.
            In production, you'll want to remove them.
        */
        if (SHOW_DIAGNOSTIC_VISUALS == true) {
            drawDiagnosticVisuals(context, floorplanOverlay: floorplanOverlay)
        }
    }

    /**
        This draws directly in the PDF coordinate system.
        If drawing onto MapKit, the context object provided must already have
        the appropriate transforms applied.

        If you have the transform correct, you should see the following:
        [A] 1.0 m radius red square (50% alpha) centered on the 1st anchor pt.
        [B] 1.0 m radius green square (50% alpha) centered on the 2nd anchor pt.
        [C] a 1x1 point magenta square centered at the (0.0, 0.0) point of your
                PDF. This square is created by the precise overlap of the
                following two rectangles.
         [C.1] a 10x1 point  red rectangle (50% alpha) that covers the 1x1 point
                square centered at PDF coordinate (0.0, 0.0) through the 1x1
                point square centered at PDF coordinate (10.0, 0.0).
         [C.2] a 1x10 point blue rectangle (50% alpha) that covers the 1x1 point
                square centered at PDF coordinate (0.0, 0.0) and the 1x1 point
                square centered at PDF coordinate (10.0, 1.0).

        Use [A] & [B] to verify that your anchor points have been set to the
            correct points on your PDF. If this does not match:
        + check your PDF reader and make sure it is giving you values in
            "points" and not "pixels" or some other unit of measure.
        + look for typos in the CGPoint values of your GeoAnchor structs.

        Use [C] to verify the location of (0.0, 0.0) on your PDF. If this does
        not match:
        + check your PDF reader and make sure it is showing you values of the
            underlying PDF coordinate system, and not its own internal display
            coordinate system. A proper PDF coordinate system should have +x be
            rightward and +y be upward.

        Use [C.1] & [C.2] to verify the sizes of "1.0 point" and "10.0 points"
            on your PDF. If this does not match:
        + check your PDF reader and make sure it is giving you values in
            "points" and not "pixels" or some other unit of measure.
    */
    func drawDiagnosticVisuals(_ context: CGContext, floorplanOverlay: FloorplanOverlay) {
        // Draw a 1.0 meter radius square around each anchor point.
        let radiusPDFPoints = CGFloat(1.0) / CGFloat(floorplanOverlay.pdfPointSizeInMeters)
        let anchorMarkerSize = CGSize(width: radiusPDFPoints * 2.0, height: radiusPDFPoints * 2.0)

        let originPt = CGPoint(x: floorplanOverlay.geoAnchorPair.fromAnchor.pdfPoint.x - radiusPDFPoints,
                               y: floorplanOverlay.geoAnchorPair.fromAnchor.pdfPoint.y - radiusPDFPoints)
        let destPt = CGPoint(x: floorplanOverlay.geoAnchorPair.toAnchor.pdfPoint.x - radiusPDFPoints,
                             y: floorplanOverlay.geoAnchorPair.toAnchor.pdfPoint.y - radiusPDFPoints)
        let fromAnchorMarker = CGRect(origin: originPt, size: anchorMarkerSize)
        let toAnchorMarker = CGRect(origin: destPt, size: anchorMarkerSize)

        // Anchor 1: Red.
        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.75)
        context.fill(fromAnchorMarker)

        // Anchor 2: Green.
        context.setFillColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.75)
        context.fill(toAnchorMarker)

        /**
            Draw a 10pt x 1pt red rectangle that covers the square centered at
            (0.0, 0.0) through the square centered at (10.0, 0.0).
        */
        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        context.fill(CGRect(x: -0.5, y: -0.5, width: 10.0, height: 1.0))
        
        /**
            Draw a 1pt x 10pt blue rectangle that covers the square centered at
            (0.0, 0.0) through the square centered at (0.0, 10.0).
        */
        context.setFillColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.5)
        context.fill(CGRect(x: -0.5, y: -0.5, width: 1.0, height: 10.0))
    }

}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages an MKMapView camera scroll  zoom by implementing
                the typical MKMapViewDelegate regionDidChangeAnimated and
                regionWillChangeAnimated to add bounce-back when the user
                scrolls/zooms away from the floorplan.
*/

import CoreLocation
import Foundation
import MapKit

/**
    This class manages an MKMapView camera scroll & zoom by implementing the
    typical MKMapViewDelegate regionDidChangeAnimated and
    regionWillChangeAnimated to add bounce-back when the user scrolls/zooms away
    from the floorplan.
*/
class VisibleMapRegionDelegate: NSObject {

    /**
        Set to true if you would want reset the MapCamera to center on the
        floorplan.
    */
    var needResetCameraOrientation = true

    /**
        Keep track of changes to [mapView camera].altitude so that we know
        whether to auto-zoom or auto-scroll.
    */
    fileprivate var lastAltitude: CLLocationDistance

    /**
        Properties of the floorplan. See FloorplanOverlay for more.
    */
    fileprivate var boundingMapRectIncludingRotations: MKMapRect
    fileprivate var boundingPDFBox: MKMapRectRotated
    fileprivate var floorplanCenter: CLLocationCoordinate2D!
    fileprivate var floorplanUprightMKMapCameraHeading: CLLocationDirection!

    /// Initializes on floorplan bounds.
    init(floorplanBounds: MKMapRect, boundingPDFBox: MKMapRectRotated, floorplanCenter: CLLocationCoordinate2D, floorplanUprightMKMapCameraHeading heading: CLLocationDirection) {
        boundingMapRectIncludingRotations = floorplanBounds
        self.boundingPDFBox = boundingPDFBox
        self.floorplanCenter = floorplanCenter
        floorplanUprightMKMapCameraHeading = heading

        lastAltitude = Double.nan

        needResetCameraOrientation = true
    }

    /**
        Resets the camera orientation to the floorplan on our mapview.
        - parameter mapView: MKMapView upon which we reset.
    */
    func mapViewResetCameraToFloorplan(_ mapView: MKMapView) {
        resetCameraOrientation(mapView, center: floorplanCenter, heading: floorplanUprightMKMapCameraHeading)
    }

    /// Handles zoom and floorplan autofit.
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let camera = mapView.camera

        var didClampZoom = false

        // Has the zoom level stabilized?
        if (lastAltitude != camera.altitude) {
            // Not yet! Someone is changing the zoom!
            lastAltitude = camera.altitude

            // Auto-zoom the camera to fit the floorplan.
            didClampZoom = clampZoomToFloorplan(mapView, floorplanBoundingMapRect: boundingMapRectIncludingRotations, floorplanCenter: floorplanCenter)
        }

        if (!didClampZoom) {
            // Once the zoom level has stabilized, auto-scroll if needed.
            clampScrollToFloorplan(mapView, floorplanBoundingPDFBoxRect: boundingPDFBox, optionalCameraHeading: needResetCameraOrientation ? floorplanUprightMKMapCameraHeading : Double.nan)
            needResetCameraOrientation = false
        }
    }

    /**
        Resets the camera orientation to the given centerpoint with the given
            heading/orientation.
        - parameter mapView: MapView which needs to be re-centered.
        - parameter center: new centerpoint.
        - parameter heading: orientation to use.
    */
    func resetCameraOrientation(_ mapView: MKMapView, center: CLLocationCoordinate2D, heading: CLLocationDirection) {
        let newCamera = mapView.camera.copy() as! MKMapCamera
        // Center the floorplan...
        newCamera.centerCoordinate = center
        // ...and rotate so the floorplan is upright.
        newCamera.heading = heading

        mapView.setCamera(newCamera, animated: true)
    }

    /**
        - returns: `true` if the floorplan doesn't fill the screen.
        - parameter mapView: MapView to check.
        - parameter floorplanBoundingMapRect: MKMapRect that defines the
            floorplan's boundaries.
    */
    func floorplanDoesNotFillScreen(_ mapView: MKMapView, floorplanBoundingMapRect: MKMapRect) -> Bool {

        if (MKMapRectContainsRect(floorplanBoundingMapRect, mapView.visibleMapRect)) {
            // Your view is already entirely inside the floorplan.
            return false
        }

        // The specific part of the floorplan that is currently visible.
        let visiblePartOfFloorplan = MKMapRectIntersection(floorplanBoundingMapRect, mapView.visibleMapRect)

        // The floorplan does not fill your screen in either direction.
        return (
            (visiblePartOfFloorplan.size.width < mapView.visibleMapRect.size.width)
            &&
            (visiblePartOfFloorplan.size.height < mapView.visibleMapRect.size.height)
        )
    }

    /**
        Helper function for clampZoomToFloorplan()
        - returns: the MapCamera altitude required to bounce back the MapCamera
            zoom back onto the floorplan. if no zoom adjustment is needed,
            returns NAN.
        - parameter mapView: The MKMapView we're looking at
        - parameter floorplanBoundingMapRect: floorplan's bounding rectangle.
    */
    func getZoomAdjustment(_ mapView: MKMapView, floorplanBoundingMapRect: MKMapRect) -> Double {
        let mapViewVisibleMapRectArea: Double = mapView.visibleMapRect.size.area()

        let maxZoomedOut: MKMapRect = mapView.mapRectThatFits(floorplanBoundingMapRect)
        let maxZoomedOutArea: Double = maxZoomedOut.size.area()

        if (maxZoomedOutArea < mapViewVisibleMapRectArea) {
            // You have zoomed out too far?

            let zoomFactor: Double = sqrt(maxZoomedOutArea / mapViewVisibleMapRectArea)
            let currentAltitude: CLLocationDistance = mapView.camera.altitude
            let newAltitude: CLLocationDistance = currentAltitude * zoomFactor

            let newAltitudeUsable: CLLocationDistance = newAltitude

            /**
                NOTE: Supposedly MapKit's internal zoom level counter is by
                    powers of two, so a 0.5x buffer here is safe and should
                    prevent pulsing when we're near the maximum zoom level.

                Assumption: We will never see a lowestGoodAltitude smaller than
                0.5x a stable MapKit altitude.
            */
            if (newAltitudeUsable < currentAltitude) {
                // Zoom back in.
                return newAltitudeUsable
            }
        }

        // No change. Return NAN.
        return Double.nan
    }

    /**
        Detect whether the user has zoomed away from the floorplan and, if so, bounce back.
        - returns: `true` if we needed to bounce back
        - parameter mapView: mapview we're working on
        - parameter floorplanBoundingMapRect: bounds of the floorplan
        - parameter floorplanCenter: center of the floorplan
    */
    func clampZoomToFloorplan(_ mapView: MKMapView, floorplanBoundingMapRect: MKMapRect, floorplanCenter: CLLocationCoordinate2D) -> Bool {

        if (floorplanDoesNotFillScreen(mapView, floorplanBoundingMapRect: floorplanBoundingMapRect)) {
            // Clamp!

            let newAltitude: CLLocationDistance = getZoomAdjustment(mapView, floorplanBoundingMapRect: floorplanBoundingMapRect)

            if (!newAltitude.isNaN) {
                // We have a zoom change to make!

                let newCamera: MKMapCamera = mapView.camera.copy() as! MKMapCamera

                newCamera.altitude = newAltitude

                /**
                    Since we've zoomed out enough to see the entire floorplan
                    anyway, let's re-center to make sure the entire floorplan is
                    actually on-screen.
                */
                newCamera.centerCoordinate = floorplanCenter

                mapView.setCamera(newCamera, animated: true)

                return true
            }
        }

        // No zoom correction took place.
        return false
    }

    /**
        Detect whether the user has scrolled away from the floorplan, and if so,
        bounce back.
        - parameter mapView: The MapView to scroll.
        - parameter floorplanBoundingMapRect: A map rect that must be "in view"
            when the scrolling is complete. We will only scroll until this map
            rect enters the view.
        - parameter optionalCameraHeading: If you give valid CLLocationDirection
            we will also adjust the camera heading. If you give an invalid
            CLLocationDirection (e.g. -1.0), we'll keep whatever heading the
            camera already has.
    */
    func clampScrollToFloorplan(_ mapView: MKMapView, floorplanBoundingPDFBoxRect: MKMapRectRotated, optionalCameraHeading: CLLocationDirection) {

        let rotationNeeded: Bool = 0.0 <= optionalCameraHeading && optionalCameraHeading < 360.0

        /**
            Assuming we are zoomed at the correct level, we still can't see the
            floorplan. Maybe you have scrolled too far?
        */

        let visibleMapRectMid = MKMapPoint(x: MKMapRectGetMidX(mapView.visibleMapRect), y: MKMapRectGetMidY(mapView.visibleMapRect))

        let visibleMapRectOriginProposed = MKMapRectRotatedNearestPoint(floorplanBoundingPDFBoxRect, point: visibleMapRectMid)

        let dxOffset = visibleMapRectOriginProposed.x - visibleMapRectMid.x
        let dyOffset = visibleMapRectOriginProposed.y - visibleMapRectMid.y

        // Okay, now we know the "proposed" scroll adjustment...

        let visibleMapRectMidPixels = mapView.convert(MKCoordinateForMapPoint(visibleMapRectMid), toPointTo: mapView)
        let visibleMapRectProposedPixels = mapView.convert(MKCoordinateForMapPoint(visibleMapRectOriginProposed), toPointTo: mapView)

        let scrollDistancePixels = CGPoint.hypotenuse(visibleMapRectProposedPixels, b: visibleMapRectMidPixels)

        /**
            ...but is it more than 1.0 screen pixel worth? (Otherwise the user
            probably wouldn't even notice)
            
            NOTE: Due to rounding errors it's hard to get exactly
                scrollDistancePixels == 0.0 anyway, so doing a check like this
                improves general responsiveness overall.
        */
        let scrollNeeded = scrollDistancePixels > 1.0

        if (rotationNeeded || scrollNeeded) {
            let newCamera = mapView.camera.copy() as! MKMapCamera
            if (rotationNeeded) {
                // Rotation the camera (e.g. to make the floorplan upright).
                newCamera.heading = optionalCameraHeading
            }
            if (scrollNeeded) {
                // Scroll back toward the floorplan.
                var cameraCenter = MKMapPointForCoordinate(mapView.camera.centerCoordinate)
                cameraCenter.x += dxOffset
                cameraCenter.y += dyOffset
                newCamera.centerCoordinate = MKCoordinateForMapPoint(cameraCenter)
            }
            mapView.setCamera(newCamera, animated: true)
        }
        
    }
}

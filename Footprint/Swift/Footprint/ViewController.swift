/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Primary view controller for what is displayed by the application.
                In this class we configure an MKMapView to display a floorplan,
                recieve location updates to determine floor number, as well as
                provide a few helpful debugging annotations.
                We will also show how to highlight a region that you have defined in
                PDF coordinates but not Latitude  Longitude.
*/

import CoreLocation
import Foundation
import MapKit

/**
    Primary view controller for what is displayed by the application.

    In this class we configure an MKMapView to display a floorplan, recieve
    location updates to determine floor number, as well as provide a few helpful
    debugging annotations.

    We will also show how to highlight a region that you have defined in PDF
    coordinates but not Latitude & Longitude.
*/
class ViewController: UIViewController, MKMapViewDelegate {

    /// Outlet for the map view in the storyboard.
    @IBOutlet weak var mapView: MKMapView!

    /// Outlet for the visuals switch at the lower-right of the storyboard.
    @IBOutlet weak var debugVisualsSwitch: UISwitch!

    /**
        To enable user location to be shown in the map, go to Main.storyboard,
        select the Map View, open its Attribute Inspector and click the checkbox
        next to User Location

        The user will need to authorize this app to use their location either by 
        enabling it in Settings or by selecting the appropriate option when 
        prompted.
    */
    var locationManager: CLLocationManager!

    var hideBackgroundOverlayAlpha: CGFloat!

    /// Helper class for managing the scroll & zoom of the MapView camera.
    var visibleMapRegionDelegate: VisibleMapRegionDelegate!

    /// Store the data about our floorplan here.
    var floorplan0: FloorplanOverlay!

    var debuggingOverlays: [MKOverlay]!
    var debuggingAnnotations: [MKAnnotation]!

    /// This property remembers which floor we're on.
    var lastFloor: CLFloor!

    /**
        Set to false if you want to turn off auto-scroll & auto-zoom that snaps
        to the floorplan in case you scroll or zoom too far away.
    */
    var snapMapViewToFloorplan: Bool!

    /**
        Set to true when we reveal the MapKit tileset (by pressing the trashcan
        button).
     */
    var mapKitTilesetRevealed = false

    /// Call this to reset the camera.
    @IBAction func resetCamera(_ sender: AnyObject) {
        visibleMapRegionDelegate.mapViewResetCameraToFloorplan(mapView)
    }

    /**
        When the trashcan hasn't yet been pressed, this toggles the debug
        visuals. Otherwise, this toggles the floorplan.
    */
    @IBAction func toggleDebugVisuals(_ sender: AnyObject) {
        if (sender.isKind(of: UISwitch.classForCoder())) {
            let senderSwitch: UISwitch = sender as! UISwitch
            /*
                If we have revealed the mapkit tileset (i.e. the trash icon was
                pressed), toggle the floorplan display off.
            */
            if (mapKitTilesetRevealed == true) {
                if (senderSwitch.isOn == true) {
                    showFloorplan()
                } else {
                    hideFloorplan()
                }
            } else {
                if (senderSwitch.isOn == true) {
                    showDebugVisuals()
                } else {
                    hideDebugVisuals()
                }
            }
        }
    }

    /**
        Remove all the overlays except for the debug visuals. Forces the debug
        visuals switch off.
    */
    @IBAction func revealMapKitTileset(_ sender: AnyObject) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        // Show labels for restaurants, schools, etc.
        mapView.showsPointsOfInterest = true
        // Show building outlines.
        mapView.showsBuildings = true
        mapKitTilesetRevealed = true
        // Set switch to off.
        debugVisualsSwitch.setOn(false, animated: true)
        showDebugVisuals()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager = CLLocationManager()

        // === Configure our floorplan.

        /*
            We setup a pair of anchors that will define how the floorplan image
            maps to geographic co-ordinates.
        */
        let anchor1 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(37.770419,-122.465726), pdfPoint: CGPoint(x: 26.2, y: 86.4))

        let anchor2 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(37.769288,-122.466376), pdfPoint: CGPoint(x: 570.1, y: 317.7))

        let anchorPair = GeoAnchorPair(fromAnchor: anchor1, toAnchor: anchor2)

        /*
            Pick a triangle on your PDF that you would like to highlight in
            yellow. Feel free to try regions with more than three edges.
            Note that these coordinates are given in PDF coordinates, but they
            will show up on just fine on MapKit in MapKit coordinates.
        */
        let pdfTriangleRegionToHighlight = [CGPoint(x: 205.0, y: 335.3), CGPoint(x: 205.0, y: 367.3), CGPoint(x: 138.5, y: 367.3)]

        // === Initialize our assets

        /*
            We have to specify subdirectory here since we copy our folder
            reference during "Copy Bundle Resources" section under target
            settings build phases.
        */
        let pdfUrl = Bundle.main.url(forResource: "floorplan_overlay_floor0", withExtension: "pdf", subdirectory:"Floorplans")!

        floorplan0 = FloorplanOverlay(floorplanUrl: pdfUrl, withPDFBox: CGPDFBox.trimBox, andAnchors: anchorPair, forFloorLevel: 0)

        visibleMapRegionDelegate = VisibleMapRegionDelegate(floorplanBounds: floorplan0.boundingMapRectIncludingRotations, boundingPDFBox: floorplan0.floorplanPDFBox,
                                                            floorplanCenter: floorplan0.coordinate,
                                                            floorplanUprightMKMapCameraHeading: floorplan0.getFloorplanUprightMKMapCameraHeading())

        // === Initialize our view
        hideBackgroundOverlayAlpha = 1.0

        // Disable tileset.
        mapView.add(HideBackgroundOverlay.hideBackgroundOverlay(), level: .aboveRoads)

        /*
            The following are provided for debugging.
            In production, you'll want to comment this out.
        */
        debuggingOverlays = ViewController.createDebuggingOverlaysForMapView(mapView!, aboutFloorplan: floorplan0)
        debuggingAnnotations = ViewController.createDebuggingAnnotationsForMapView(mapView!, aboutFloorplan: floorplan0)

        // Draw the floorplan!
        mapView.add(floorplan0)

        /*
            Highlight our region (originally specified in PDF coordinates) in
            yellow!
        */
        let customHighlightRegion = floorplan0.polygonFromCustomPDFPath(pdfTriangleRegionToHighlight)
        customHighlightRegion.title = "Hello World"
        customHighlightRegion.subtitle = "This custom region will be highlighted in Yellow!"
        mapView!.add(customHighlightRegion)

        /*
            By default, we listen to the scroll & zoom events to make sure that
            if the user scrolls/zooms too far away from the floorplan, we
            automatically bounce back. If you would like to disable this
            behavior, comment out the following line.
        */
        snapMapViewToFloorplan = true
    }

    override func viewDidAppear(_ animated: Bool) {
        /*
            For additional debugging, you may prefer to use non-satellite
            (standard) view instead of satellite view. If so, uncomment the line
            below. However, satellite view allows you to zoom in more closely
            than non-satellite view so you probably do not want to leave it this
            way in production.
        */
        //mapView.mapType = MKMapTypeStandard
    }

    /// Respond to CoreLocation updates
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let location: CLLocation = userLocation.location!

        // CLLocation updates will not always have floor information...
        if (location.floor != nil) {
            // ...but when they do, take note!
            NSLog("Location (Floor %ld): %s", location.floor!, location.description)
            lastFloor = location.floor
            NSLog("We are on floor %ld", lastFloor.level)
        }
    }

    /// Request authorization if needed.
    func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
        switch (CLLocationManager.authorizationStatus()) {
            case CLAuthorizationStatus.notDetermined:
                // Ask the user for permission to use location.
                locationManager.requestWhenInUseAuthorization()
            case CLAuthorizationStatus.denied:
                NSLog("Please authorize location services for this app under Settings > Privacy")
            case CLAuthorizationStatus.authorizedAlways, CLAuthorizationStatus.authorizedWhenInUse, CLAuthorizationStatus.restricted:
                break
        }
    }

    /// Helper method that shows the floorplan.
    func showFloorplan() {
        mapView.add(floorplan0)
    }

    /// Helper method that hides the floorplan.
    func hideFloorplan() {
        mapView.remove(floorplan0)
    }

    /// Helper function that shows the debug visuals.
    func showDebugVisuals() {
        // Make the background transparent to reveal the underlying grid.
        hideBackgroundOverlayAlpha = 0.5
        // Show debugging bounding boxes.
        mapView.addOverlays(debuggingOverlays, level: .aboveRoads)
        // Show debugging pins.
        mapView.addAnnotations(debuggingAnnotations)
    }

    /// Helper function that hides the debug visuals.
    func hideDebugVisuals() {
        mapView.removeAnnotations(debuggingAnnotations)
        mapView.removeOverlays(debuggingOverlays)
        hideBackgroundOverlayAlpha = 1.0
    }

    /**
        Check for when the MKMapView is zoomed or scrolled in case we need to
        bounce back to the floorplan. If, instead, you're using e.g.
        MKUserTrackingModeFollow then you'll want to disable
        snapMapViewToFloorplan since it will conflict with the user-follow
        scroll/zoom.
    */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (snapMapViewToFloorplan == true) {
            visibleMapRegionDelegate.mapView(mapView, regionDidChangeAnimated:animated)
        }
    }

    /// Produce each type of renderer that might exist in our mapView.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if (overlay.isKind(of: FloorplanOverlay.self)) {
            let renderer: FloorplanOverlayRenderer = FloorplanOverlayRenderer(overlay: overlay as MKOverlay)
            return renderer
        }

        if (overlay.isKind(of: HideBackgroundOverlay.self) == true) {
            let renderer = MKPolygonRenderer(overlay: overlay as MKOverlay)

            /*
                HideBackgroundOverlay covers the entire world, so this means all
                of MapKit's tiles will be replaced with a solid white background
            */
            renderer.fillColor = UIColor.white.withAlphaComponent(hideBackgroundOverlayAlpha)

            // No border.
            renderer.lineWidth = 0.0
            renderer.strokeColor = UIColor.white.withAlphaComponent(0.0)

            return renderer
        }

        if (overlay.isKind(of: MKPolygon.self) == true) {
            let polygon: MKPolygon = overlay as! MKPolygon

            /*
                A quick and dirty MKPolygon renderer for addDebuggingOverlays
                and our custom highlight region.
                In production, you'll want to implement this more cleanly.
                "However, if each overlay uses different colors or drawing
                attributes, you should find a way to initialize that information
                using the annotation object, rather than having a large decision
                tree in mapView:rendererForOverlay:"

                See "Creating Overlay Renderers from Your Delegate Object"
            */
            if (polygon.title == "Hello World") {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.yellow.withAlphaComponent(0.5)
                renderer.strokeColor = UIColor.yellow.withAlphaComponent(0.0)
                renderer.lineWidth = 0.0
                return renderer
            }

            if (polygon.title == "debug") {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.gray.withAlphaComponent(0.1)
                renderer.strokeColor = UIColor.cyan.withAlphaComponent(0.5)
                renderer.lineWidth = 2.0
                return renderer
            }
        }

        NSException(name:NSExceptionName(rawValue: "InvalidMKOverlay"), reason:"Did you add an overlay but forget to provide a matching renderer here? The class was type \(type(of: overlay))", userInfo:["wasClass": type(of: overlay)]).raise()
        return MKOverlayRenderer()
    }

    /// Produce each type of annotation view that might exist in our MapView.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        /*
            For now, all we have are some quick and dirty pins for viewing debug
            annotations. To learn more about showing annotations, 
            see "Annotating Maps".
        */

        if (annotation.title! == "red") {
            let pinView = MKPinAnnotationView()
            pinView.pinTintColor = UIColor.red
            pinView.canShowCallout = true
            return pinView
        }

        if (annotation.title! == "green") {
            let pinView = MKPinAnnotationView()
            pinView.pinTintColor = UIColor.green
            pinView.canShowCallout = true
            return pinView
        }

        if (annotation.title! == "purple") {
            let pinView = MKPinAnnotationView()
            pinView.pinTintColor = UIColor.purple
            pinView.canShowCallout = true
            return pinView
        }
        
        return nil
    }

    /**
        If you have set up your anchors correctly, this function will create:
        1. a red pin at the location of your fromAnchor.
        2. a green pin at the location of your toAnchor.
        3. a purple pin at the location of the PDF's internal origin.

        Use these pins to:
        * Compare the location of pins #1 and #2 with the underlying Apple Maps
            tiles.
            + The pins should appear, on the real world, in the physical
              locations corresponding to the landmarks that you chose for each
              anchor.
            + If either pin does not seem to be at the correct position on Apple
              Maps, double-check for typos in the CLLocationCoordinate2D values
              of your GeoAnchor struct.
        * Compare the location of pins #1 and #2 with the matching colored
            squares drawn by FloorplanOverlayRenderer.m:drawDiagnosticVisuals on
            your floorplan overlay.
            + The red pin should appear at the same location as the red square
              the green pin should appear at the same location as the green 
              square.
            + If either pin does not match the location of its corresponding
              square, you may be having problems with coordinate conversion
              accuracy. Try picking anchor points that are further apart.

        - parameter mapView: MapView to draw on.
        - parameter aboutFloorplan: floorplan from which we get anchors and
                coordinates.
    */
    class func createDebuggingAnnotationsForMapView(_ mapView: MKMapView, aboutFloorplan floorplan: FloorplanOverlay) -> [MKPointAnnotation] {
        // Drop a red pin on the fromAnchor latitudeLongitude location.
        let fromAnchor = MKPointAnnotation()
        fromAnchor.title = "red"
        fromAnchor.subtitle = "fromAnchor should be here"
        fromAnchor.coordinate = floorplan.geoAnchorPair.fromAnchor.latitudeLongitudeCoordinate

        // Drop a green pin on the toAnchor latitudeLongitude location.
        let toAnchor = MKPointAnnotation()
        toAnchor.title = "green"
        toAnchor.subtitle = "toAnchor should be here"
        toAnchor.coordinate = floorplan.geoAnchorPair.toAnchor.latitudeLongitudeCoordinate

        // Drop a purple pin showing the (0.0 pt, 0.0 pt) location of the PDF.
        let pdfOrigin = MKPointAnnotation()
        pdfOrigin.title = "purple"
        pdfOrigin.subtitle = "This is the 0.0, 0.0 coordinate of your PDF"
        pdfOrigin.coordinate = MKCoordinateForMapPoint(floorplan.pdfOrigin)

        return [fromAnchor, toAnchor, pdfOrigin]
    }

    /**
        Return an array of three debugging overlays. These overlays will show:
        1. the PDF Page Box that was selected for this floor.
        2. the boundingMapRect used to define the rendering of this floorplan by
            MKMapView.
        3. the boundingMapRectIncludingRotations used to define the rendering of
            this floorplan.
    
        Use these outlines to:
        * Ensure that #1 shows a polygon that is just small enough to enclose
            all of the important visual content in your floorplan.
            + If this polygon is much larger than your floorplan, you may
                experience runtime performance issues. In this case it's better
                to choose or define a smaller PDF Page Box.
    
        * Ensure that #2 shows a polygon that encloses your floorplan exactly.
            + If any important visual floorplan information is outside this
                polygon, those parts of the floorplan might not be displayed to
                the user, depending on their zoom & scrolling. In this case it's
                better to choose or define a larger PDF Page Box.

        * Ensure that #3 shows a polygon that is large enough to contain your
            floorplan comfortably, but still small enough to cause bounce-back
            when the user scrolls/zooms out too far.
            + The boundingMapRect is based on the PDF Page Box, so the best way
              to adjust the boundingMapRect is to get a more accurate PDF Page 
              Box.
            + Note: In this sample code app we use the boundingMapRect also to
              determine the limits where zoom/scroll bounce-back takes place.
    */
    class func createDebuggingOverlaysForMapView(_ mapView: MKMapView, aboutFloorplan floorplan: FloorplanOverlay) -> [MKPolygon] {
        let floorplanPDFBox = floorplan.polygonFromFloorplanPDFBoxCorners
        floorplanPDFBox.title = "debug"
        floorplanPDFBox.subtitle = "PDF Page Box"

        let floorplanBoundingMapRect = floorplan.polygonFromBoundingMapRect
        floorplanBoundingMapRect.title = "debug"
        floorplanBoundingMapRect.subtitle = "boundingMapRect"

        let floorplanBoundingMapRectWithRotations = floorplan.polygonFromBoundingMapRectIncludingRotations
        floorplanBoundingMapRectWithRotations.title = "debug"
        floorplanBoundingMapRectWithRotations.subtitle = "boundingMapRectIncludingRotations"

        return [floorplanPDFBox, floorplanBoundingMapRect, floorplanBoundingMapRectWithRotations]
    }
}

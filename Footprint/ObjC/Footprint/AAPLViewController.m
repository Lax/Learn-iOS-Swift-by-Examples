/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Primary view controller for what is displayed by the application. In this class we configure an MKMapView to display a floorplan, recieve location updates to determine floor number, as well as provide a few helpful debugging annotations.
    
                We will also show how to highlight a region that you have defined in PDF coordinates but not Latitude  Longitude.
*/

#import "AAPLViewController.h"
#import "AAPLCoordinateConverter.h"
#import "AAPLFloorplanOverlay.h"
#import "AAPLFloorplanOverlayRenderer.h"
#import "AAPLHideBackgroundOverlay.h"

#define USE_DEBUG_ANNOTATIONS

#define AAPL_HIGHLIGHT_REGION_COUNT 3

@import MapKit;

/**
    This class manages an \c MKMapView camera scroll & zoom by implementing the
    typical \c MKMapViewDelegate \c regionDidChangeAnimated and
    \c regionWillChangeAnimated to add bounce-back when the user scrolls/zooms
    away from the floorplan.
 */
@interface AAPLVisibleMapRegionDelegate : NSObject

/*
 Keep track of changes to [mapView camera].altitude so that we know
 whether to auto-zoom or auto-scroll.
 */
@property (nonatomic) CLLocationDistance lastAltitude;

// Properties of the floorplan. See AAPLFloorplanOverlay for more.
@property (nonatomic) MKMapRect boundingMapRectIncludingRotations;
@property (nonatomic) AAPLMKMapRectRotated boundingPDFBox;
@property (nonatomic) CLLocationCoordinate2D floorplanCenter;
@property (nonatomic) CLLocationDirection floorplanUprightMKMapCameraHeading;

- (instancetype)initWithFloorplanBounds:(MKMapRect)boundingMapRectWithRotations pdfBoundingBox:(AAPLMKMapRectRotated)pdfBoundingBox centerOfFloorplan:(CLLocationCoordinate2D)centerOfFloorplan floorplanUprightMKMapCameraHeading:(CLLocationDirection)heading;

- (void)mapViewResetCameraToFloorplan:(MKMapView *)mapView;

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;

@end


@interface AAPLViewController () <MKMapViewDelegate>

/// Outlet for the map view in the storyboard.
@property (nonatomic, weak) IBOutlet MKMapView *mapView;

/// Outlet for the debug visuals switch at the lower-right of the storyboard.
@property (weak, nonatomic) IBOutlet UISwitch *debugVisualsSwitch;

/**
    To enable user location to be shown in the map, go to Main.storyboard,
    select the Map View, open its Attribute Inspector and click the checkbox
    next to User Location

    The user will need to authorize this app to use their location either by
    enabling it in Settings or by selecting the appropriate option when
    prompted.
 */
@property (nonatomic, strong) CLLocationManager *locationManager;

/**
    This is the alpha value we'll use for the White overlay that hides the
    underlying Apple base map tiles.
 */
@property (nonatomic) CGFloat hideBackgroundOverlayAlpha;

/// Helper class for managing the scroll & zoom of the MapView camera.
@property (nonatomic, strong) AAPLVisibleMapRegionDelegate *visibleMapRegionDelegate;

/// Store the data about our floorplan here.
@property (nonatomic, strong) AAPLFloorplanOverlay *floorplan0;

/// This property remembers which floor we're on. See documentation for CLFloor.
@property (strong) CLFloor *lastFloor;

#ifdef USE_DEBUG_ANNOTATIONS
@property (nonatomic, strong, nonnull) NSArray<id<MKOverlay>> *debuggingOverlays;
@property (nonatomic, strong, nonnull) NSArray<id<MKAnnotation>> *debuggingAnnotations;

/**
    Set to NO if you want to turn off \c AAPLFloorplanOverlayRenderer's
    diagnostic visuals.
*/
@property (nonatomic) BOOL showsPDFDiagnosticVisuals;
#endif

/**
    Set to NO if you want to turn off auto-scroll & auto-zoom that snaps to the
    floorplan in case you scroll or zoom too far away.
*/
@property (nonatomic) BOOL snapsMapViewToFloorplan;

/**
    Set to YES when we reveal the MapKit tileset (by pressing the
    X button).
*/
@property (nonatomic) BOOL mapKitTilesetRevealed;

/// Call this to reset the camera.
- (IBAction)resetCamera:(id)sender;

/**
    When the X icon hasn't yet been pressed, this toggles the debug visuals.
    Otherwise, this toggles the floorplan.
*/
- (IBAction)toggleDebugVisuals:(id)sender;

/**
    Remove all the overlays except for the debug visuals. Forces the debug
    visuals switch off.
*/
- (IBAction)revealMapKitTileset:(id)sender;

/**
    If you have set up your anchors correctly, this function will create:
        1. a red pin at the location of your \c fromAnchor.
        2. a green pin at the location of your \c toAnchor.
        3. a purple pin at the location of the PDF's internal origin.

    Use these pins to:
        * Compare the location of pins #1 and #2 with the underlying Apple Maps
            tiles.
            + The pins should appear, on the real world, in the physical
                locations corresponding to the landmarks that you chose for each
                anchor.
            + If either pin does not seem to be at the correct position on Apple
                Maps, double-check for typos in the \c CLLocationCoordinate2D
                values of your \c AAPLGeoAnchor struct.
        * Compare the location of pins #1 and #2 with the matching colored
           squares drawn by AAPLFloorplanOverlayRenderer.m:drawDiagnosticVisuals
            on your floorplan overlay.
            + The red pin should appear at the same location as the red square;
                the green pin should appear at the same location as the green
                square.
            + If either pin does not match the location of its corresponding
                square, you may be having problems with coordinate conversion
                accuracy. Try picking anchor points that are further apart.

    @param mapView MapView to draw on.
    @param aboutFloorplan floorplan from which we get anchors and coordinates.
*/
+ (nonnull NSArray<id<MKAnnotation>> *)createDebuggingAnnotationsForMapView:(MKMapView *)mapView aboutFloorplan:(AAPLFloorplanOverlay *)floorplan;


/**
    Return an NSArray of three debugging overlays. These overlays will show:
        1. the PDF Page Box that was selected for this floor.
        2. the \c boundingMapRect used to define the rendering of this floorplan
            by \c MKMapView.
        3. the \c boundingMapRectIncludingRotations used to define the rendering
            of this floorplan.

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
            + The \c boundingMapRect is based on the PDF Page Box, so the best
                way to adjust the \c boundingMapRect is to get a more accurate
                PDF Page Box.
            + Note: In this sample code app we use the \c boundingMapRect also
                to determine the limits where zoom/scroll bounce-back takes
                place.

    For more information, see enum \c CGPDFBox and 
    \c AAPLFloorplanOverlay \c initWithFloorplanURL:... \c PDFBox:
*/
+ (nonnull NSArray<id<MKOverlay>> *)createDebuggingOverlaysForMapView:(MKMapView *)mapView aboutFloorplan:(AAPLFloorplanOverlay *)floorplan;

@end

#pragma mark AAPLViewController

@implementation AAPLViewController

- (IBAction)resetCamera:(id)sender {
    [self.visibleMapRegionDelegate mapViewResetCameraToFloorplan:self.mapView];
}

- (IBAction)toggleDebugVisuals:(id)sender {
    if (![sender isKindOfClass:[UISwitch class]]) {
        return;
    }

    UISwitch *senderSwitch = (UISwitch *)sender;
    
    if (self.mapKitTilesetRevealed) {
        if (senderSwitch.isOn) {
            [self showFloorplan];
        }
        else {
            [self hideFloorplan];
        }
    }
    else {
        if (senderSwitch.isOn) {
            [self showDebugVisuals];
        }
        else {
            [self hideDebugVisuals];
        }
    }
}

- (IBAction)revealMapKitTileset:(id)sender {
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.debuggingAnnotations];

    // Show labels for restaurants, schools, etc.
    self.mapView.showsPointsOfInterest = YES;

    // Show building outlines.
    self.mapView.showsBuildings = YES;
    self.mapKitTilesetRevealed = YES;

    // Set switch to off.
    [self.debugVisualsSwitch setOn:NO animated:YES];
    [self showDebugVisuals];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mapKitTilesetRevealed = NO;

    self.locationManager = [[CLLocationManager alloc] init];

    // === Configure our floorplan

    /*
        We setup a pair of anchors that will define how the "floorplan image"
        maps to geographic co-ordinates.
    */
    AAPLGeoAnchor anchor1 = {
        .latitudeLongitude = CLLocationCoordinate2DMake(37.770419, -122.465726),
        .PDFPoint = CGPointMake(26.2, 86.4)
    };

    AAPLGeoAnchor anchor2 = {
        .latitudeLongitude = CLLocationCoordinate2DMake(37.769288, -122.466376),
        .PDFPoint = CGPointMake(570.1, 317.7)
    };

    AAPLGeoAnchorPair anchorPair = {
        .fromAnchor = anchor1,
        .toAnchor = anchor2
    };

    /*
        Pick a triangle on your PDF that you would like to highlight in yellow.
        Feel free to try regions with more than three edges, up to you.
     */
    CGPoint pdfTriangleRegionToHighlight[AAPL_HIGHLIGHT_REGION_COUNT] = {
        /*
            Note that these coordinates are given in PDF coordinates, but they
            will show up on just fine on MapKit in MapKit coordinates.
         */
        CGPointMake(205.0, 335.3),
        CGPointMake(205.0, 367.3),
        CGPointMake(138.5, 367.3)
    };

    // === Initialize our assets

    /*
        We have to specify subdirectory here since we copy our folder reference
        during "Copy Bundle Resources" section under target settings build
        phases.
     */
    NSURL *pdfUrl = [[NSBundle mainBundle] URLForResource:@"floorplan_overlay_floor0" withExtension:@"pdf" subdirectory:@"Floorplans"];

    self.floorplan0 = [[AAPLFloorplanOverlay alloc] initWithFloorplanURL:pdfUrl PDFBox:kCGPDFTrimBox anchors:anchorPair forFloorAtLevel:0];

    self.visibleMapRegionDelegate =
        [[AAPLVisibleMapRegionDelegate alloc]
             initWithFloorplanBounds:self.floorplan0.boundingMapRectIncludingRotations
             pdfBoundingBox:self.floorplan0.floorplanPDFBox
             centerOfFloorplan:self.floorplan0.coordinate
             floorplanUprightMKMapCameraHeading:self.floorplan0.floorplanUprightMKMapCameraHeading
         ];

#ifdef USE_DEBUG_ANNOTATIONS
    // The following are provided for debugging.
    self.debuggingOverlays = [AAPLViewController createDebuggingOverlaysForMapView:self.mapView aboutFloorplan:self.floorplan0];
    self.debuggingAnnotations = [AAPLViewController createDebuggingAnnotationsForMapView:self.mapView aboutFloorplan:self.floorplan0];
#endif

    // Turn on AAPLFloorplanOverlayRenderer's diagnostic visuals.
    self.showsPDFDiagnosticVisuals = YES;

    // === Initialize our view

    self.hideBackgroundOverlayAlpha = 1.0;
    // disable tileset.
    [self.mapView addOverlay:[AAPLHideBackgroundOverlay hideBackgroundOverlay] level:MKOverlayLevelAboveRoads];

    // Draw the floorplan!
    [self.mapView addOverlay:self.floorplan0];

    // Highlight our region (originally specified in PDF coordinates) in yellow!
    MKPolygon *customHighlightRegion = [self.floorplan0 polygonFromCustomPDFPath:pdfTriangleRegionToHighlight count:AAPL_HIGHLIGHT_REGION_COUNT];
    customHighlightRegion.title = @"Hello World";
    customHighlightRegion.subtitle = @"This custom region will be highlighted in Yellow!";
    [self.mapView addOverlay:customHighlightRegion];

    /*
        By default, we listen to the scroll & zoom events to make sure that if
        the user scrolls/zooms too far away from the floorplan, we automatically
        bounce back.

        To disable this behavior, comment out the following line.
     */
    self.snapsMapViewToFloorplan = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    /*
        For additional debugging, you may prefer to use non-satellite (standard)
        view instead of satellite view. If so, uncomment the line below.

        However, satellite view allows you to zoom in more closely than
        non-satellite view so you probably do not want to leave it this way
        in production.
     */
    //self.mapView.mapType = MKMapTypeStandard;
}

- (BOOL)shouldAutorotate {
    return NO;
}

/// Respond to CoreLocation updates.
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation NS_AVAILABLE(10_9, 4_0) {
    CLLocation *location = userLocation.location;

    // CLLocation updates will not always have floor information...
    if (location.floor != nil) {
        NSLog(@"Location (Floor %@): %@", location.floor, location.description);
        // ...but when they do, take note!
        self.lastFloor = location.floor;
        NSLog(@"We are on floor %ld", (long)self.lastFloor.level);
    }
}


/// Request authorization if needed.
- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView {
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            // Ask the user for permission to use location.
            [self.locationManager requestWhenInUseAuthorization];
            break;

        case kCLAuthorizationStatusDenied:
            NSLog(@"Please authorize location services for this app under Settings > Privacy.");
            break;
        
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusRestricted:
            // Nothing to do.
            break;
    }
}

/// Helper method that shows the floorplan.
-  (void)showFloorplan {
    [self.mapView addOverlay:self.floorplan0];
}

/// Helper function that hides the floorplan.
- (void)hideFloorplan {
    [self.mapView removeOverlay:self.floorplan0];
}

/// Helper function that shows the debug visuals.
- (void)showDebugVisuals {
    // Make the background transparent to reveal, slightly the underlying grid.
    self.hideBackgroundOverlayAlpha = 0.5;
    // Show debugging bounding boxes.
    [self.mapView addOverlays:self.debuggingOverlays level: MKOverlayLevelAboveRoads];
    // Show debugging pins.
    [self.mapView addAnnotations:self.debuggingAnnotations];
}

/// Helper function that hides the debug visuals.
- (void)hideDebugVisuals {
    [self.mapView removeAnnotations:self.debuggingAnnotations];
    [self.mapView removeOverlays:self.debuggingOverlays];
    self.hideBackgroundOverlayAlpha = 1.0;
}

/**
    Check for when the \c MKMapView is zoomed or scrolled in case we need to
    bounce back to the floorplan.
    If, instead, you're using e.g. \c MKUserTrackingModeFollow then you'll want
    to disable \c snapsMapViewToFloorplan since it will conflict with the
    user-follow scroll/zoom.
*/
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (self.snapsMapViewToFloorplan) {
        [self.visibleMapRegionDelegate mapView:mapView regionDidChangeAnimated:animated];
    }
}

/// Produce each type of renderer that might exist in our mapView.
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {

    if ([overlay isKindOfClass:[AAPLFloorplanOverlay class]]) {
        AAPLFloorplanOverlayRenderer *renderer = [[AAPLFloorplanOverlayRenderer alloc] initWithOverlay:overlay];
        return renderer;
    }

    if ([overlay isKindOfClass:[AAPLHideBackgroundOverlay class]]) {
        MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];

        /*
            AAPLHideBackgroundOverlay covers the entire world, so this means
            all of MapKit tiles will be replaced with a solid white background.
         */
        renderer.fillColor = [[UIColor whiteColor] colorWithAlphaComponent:self.hideBackgroundOverlayAlpha];

        // no border.
        renderer.lineWidth = 0.0;
        renderer.strokeColor = [[UIColor whiteColor] colorWithAlphaComponent:0.0];

        return renderer;
    }

    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygon *polygon = (MKPolygon *)overlay;

        /*
            A quick and dirty MKPolygon renderer for addDebuggingOverlays and
            our custom highlight region.

            In production, you'll want to implement this more cleanly:
            "However, if each overlay uses different colors or drawing
            attributes, you should find a way to initialize that information
            using the annotation object, rather than having a large decision
            tree in mapView:rendererForOverlay:"

            See "Creating Overlay Renderers from Your Delegate Object" for more.
         */

        if ([polygon.title isEqualToString:@"Hello World"]) {
            MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:polygon];
            renderer.fillColor = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
            renderer.strokeColor = [[UIColor yellowColor] colorWithAlphaComponent:0.0];
            renderer.lineWidth = 0.0;
            return renderer;
        }

        if ([polygon.title isEqualToString:@"debug"]) {
            MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:polygon];
            renderer.fillColor = [[UIColor grayColor] colorWithAlphaComponent:0.1];
            renderer.strokeColor = [[UIColor cyanColor] colorWithAlphaComponent:0.5];
            renderer.lineWidth = 2.0;
            return renderer;
        }
    }

    return nil;
}

/// Produce each type of annotation view that might exist in our MapView.
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    /*
        For now, all we have are some quick and dirty pins for viewing debug
        annotations.
        To learn more about showing annotations, see "Annotating Maps" doc
     */
    if ([annotation.title isEqualToString:@"red"]) {
        MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] init];
        pinView.pinTintColor = [UIColor redColor];
        pinView.canShowCallout = YES;
        return pinView;
    }

    if ([annotation.title isEqualToString:@"green"]) {
        MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] init];
        pinView.pinTintColor = [UIColor greenColor];
        pinView.canShowCallout = YES;
        return pinView;
    }

    if ([annotation.title isEqualToString:@"purple"]) {
        MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc] init];
        pinView.pinTintColor = [UIColor purpleColor];
        pinView.canShowCallout = YES;
        return pinView;
    }

    return nil;
}

+ (nonnull NSArray<id<MKAnnotation>> *)createDebuggingAnnotationsForMapView:(MKMapView *)mapView aboutFloorplan:(AAPLFloorplanOverlay *)floorplan {
    // Drop a red pin on the fromAnchor latitudeLongitude location.
    MKPointAnnotation *fromAnchor = [[MKPointAnnotation alloc] init];
    fromAnchor.title = @"red";
    fromAnchor.subtitle = @"fromAnchor should be here";
    fromAnchor.coordinate = floorplan.anchors.fromAnchor.latitudeLongitude;
    
    // Drop a green pin on the toAnchor latitudeLongitude location.
    MKPointAnnotation *toAnchor = [[MKPointAnnotation alloc] init];
    toAnchor.title = @"green";
    toAnchor.subtitle = @"toAnchor should be here";
    toAnchor.coordinate = floorplan.anchors.toAnchor.latitudeLongitude;

    // Drop a purple pin showing the (0.0 pt, 0.0 pt) location of the PDF.
    MKPointAnnotation *pdfOrigin = [[MKPointAnnotation alloc] init];
    pdfOrigin.title = @"purple";
    pdfOrigin.subtitle = @"This is the 0.0, 0.0 coordinate of your PDF";
    pdfOrigin.coordinate = MKCoordinateForMapPoint(floorplan.PDFOrigin);

    return @[
        fromAnchor,
        toAnchor,
        pdfOrigin
    ];
}

+ (nonnull NSArray<id<MKOverlay>> *)createDebuggingOverlaysForMapView:(MKMapView *)mapView aboutFloorplan:(AAPLFloorplanOverlay *)floorplan {
    MKPolygon *floorplanPDFBox = floorplan.polygonFromFloorplanPDFBoxCorners;
    floorplanPDFBox.title = @"debug";
    floorplanPDFBox.subtitle = @"PDF Page Box";

    MKPolygon *floorplanBoundingMapRect = floorplan.polygonFromBoundingMapRect;
    floorplanBoundingMapRect.title = @"debug";
    floorplanBoundingMapRect.subtitle = @"boundingMapRect";

    MKPolygon *floorplanBoundingMapRectIncludingRotations = floorplan.polygonFromBoundingMapRectIncludingRotations;
    floorplanBoundingMapRect.title = @"debug";
    floorplanBoundingMapRect.subtitle = @"boundingMapRectIncludingRotations";
    
    return @[
        floorplanPDFBox,
        floorplanBoundingMapRect,
        floorplanBoundingMapRectIncludingRotations
    ];
}

@end

#pragma mark - Functions related to AAPLVisibleMapRegionDelegate

/**
    @param a an \c MKMapSize object.
    @return The area of an \c MKMapSize.
 */
static double AAPLMKMapSizeArea(MKMapSize a) {
    return a.height * a.width;
}

/**
    @param a point A.
    @param b point B.
    @return The hypotenuse defined by two.
 */
static double AAPLCGPointHypot(CGPoint a, CGPoint b) {
    return hypot(b.x - a.x, b.y - a.y);
}

/**
    Resets the camera orientation to the given centerpoint with the given
    heading/orientation.

    @param mapView MapView which needs to be re-centered.
    @param center new centerpoint.
    @param heading orientation to use.
 */
static void resetCameraOrientation(MKMapView *mapView, CLLocationCoordinate2D center, CLLocationDirection heading) {
    MKMapCamera *newCamera = [mapView.camera copy];
    
    // Center the floorplan...
    newCamera.centerCoordinate = center;

    // ...and rotate so the floorplan is upright.
    newCamera.heading = heading;
    [mapView setCamera:newCamera animated:YES];
}

/**
    @return YES if the floorplan doesn't fill the screen
    @param mapView MapView to check
    @param floorplanBoundingMapRect \c MKMapRect that defines the floorplan's boundaries
 */
static BOOL floorplanDoesNotFillScreen(MKMapView *mapView, MKMapRect floorplanBoundingMapRect) {
    if (MKMapRectContainsRect(floorplanBoundingMapRect, mapView.visibleMapRect)) {
        // Your view is already entirely inside the floorplan. Nothing to do.
        return NO;
    }


    // The specific part of the floorplan that is currently visible.
    MKMapRect visiblePartOfFloorplan = MKMapRectIntersection(floorplanBoundingMapRect, mapView.visibleMapRect);

    /*
        The floorplan does not fill your screen in either direction. You must have
        scrolled or zoomed out too far.
    */
    return visiblePartOfFloorplan.size.width < mapView.visibleMapRect.size.width &&
           visiblePartOfFloorplan.size.height < mapView.visibleMapRect.size.height;
}

/**
    Helper function for \c clampZoomToFloorplan().
    @return the MapCamera altitude required to bounce back the MapCamera zoom
    back onto the floorplan. if no zoom adjustment is needed, returns NAN.
    @param mapView The \c MKMapView we're looking at.
    @param floorplanBoundingMapRect bounding rectangle of the floorplan.
 */
static double getZoomAdjustment(MKMapView *mapView, MKMapRect floorplanBoundingMapRect) {
    double mapViewVisibleMapRectArea = AAPLMKMapSizeArea(mapView.visibleMapRect.size);

    MKMapRect maxZoomedOut = [mapView mapRectThatFits:floorplanBoundingMapRect];
    double maxZoomedOutArea = AAPLMKMapSizeArea(maxZoomedOut.size);


    if (maxZoomedOutArea < mapViewVisibleMapRectArea) {
        // You have zoomed out too far?

        double zoomFactor = sqrt(maxZoomedOutArea / mapViewVisibleMapRectArea);
        CLLocationDistance currentAltitude = mapView.camera.altitude;
        CLLocationDistance newAltitude = currentAltitude * zoomFactor;

        // getUsableAltitude(newAltitude, detectZoomLevel);
        CLLocationDistance newAltitudeUsable = newAltitude;

        /*
            NOTE: MapKit's internal zoom level counter is by powers of two, so a
            0.5x buffer here is safe and should prevent pulsing when we're near 
            the maximum zoom level.

            Assumption: We will never see a lowestGoodAltitude smaller than 0.5x
            a stable MapKit altitude.
         */
        if (newAltitudeUsable < currentAltitude) {
            // Zoom back in.
            return newAltitudeUsable;
        }
    }

    // No change. Return NAN.
    return NAN;
}

/**
    Detect whether the user has zoomed away from the floorplan and, if so,
    bounce back.

    @return `YES` if we needed to bounce back.
    @param mapView mapview we're working on.
    @param floorplanBoundingMapRect bounds of the floorplan.
    @param floorplanCenter center of the floorplan.
 */
static BOOL clampZoomToFloorplan(MKMapView *mapView, MKMapRect floorplanBoundingMapRect, CLLocationCoordinate2D floorplanCenter) {

    if (floorplanDoesNotFillScreen(mapView, floorplanBoundingMapRect)) {
        // Clamp!

        CLLocationDistance newAltitude = getZoomAdjustment(mapView, floorplanBoundingMapRect);

        if (!isnan(newAltitude)) {
            // We have a zoom change to make!

            MKMapCamera *newCamera = [mapView.camera copy];
            newCamera.altitude = newAltitude;

            // Since we've zoomed out enough to see the entire floorplan anyway, let's re-center to make sure the entire floorplan is actually on-screen.
            newCamera.centerCoordinate = floorplanCenter;

            [mapView setCamera:newCamera animated:YES];

            // DONE
            return YES;
        }
    }

    // No zoom correction took place.
    return NO;
}

/**
    Detect whether the user has scrolled away from the floorplan, and if so,
    bounce back.

    @param mapView The MapView to scroll
    @param floorplanBoundingMapRect A map rect that must be "in view" when the
    scrolling is complete. We will only scroll until this map rect
    enters the view.
    @param optionalCameraHeading If you give valid \c CLLocationDirection, we
    will also adjust the camera heading. If you give an invalid
    \c CLLocationDirection (e.g. -1.0), we'll keep whatever heading the
    camera already has.
 */
static void clampScrollToFloorplan(MKMapView *mapView, AAPLMKMapRectRotated floorplanBoundingPDFBoxRect, CLLocationDirection optionalCameraHeading) {

    BOOL rotationNeeded = 0.0 <= optionalCameraHeading && optionalCameraHeading < 360.0;

    /*
        Assuming we are zoomed at the correct level, we still can't see the
        floorplan. You have scrolled too far?
    */

    MKMapPoint visibleMapRectMid = {
        .x = MKMapRectGetMidX(mapView.visibleMapRect),
        .y = MKMapRectGetMidY(mapView.visibleMapRect)
    };

    MKMapPoint visibleMapRectOriginProposed = AAPLMKMapRectRotatedNearestPoint(floorplanBoundingPDFBoxRect, visibleMapRectMid);

    double dxOffset = visibleMapRectOriginProposed.x - visibleMapRectMid.x;
    double dyOffset = visibleMapRectOriginProposed.y - visibleMapRectMid.y;

    // Okay, now we know the "proposed" scroll adjustment...

    CGPoint visibleMapRectMidPixels = [mapView convertCoordinate:MKCoordinateForMapPoint(visibleMapRectMid) toPointToView:mapView];
    CGPoint visibleMapRectProposedPixels = [mapView convertCoordinate:MKCoordinateForMapPoint(visibleMapRectOriginProposed) toPointToView:mapView];

    double scrollDistancePixels = AAPLCGPointHypot(visibleMapRectProposedPixels, visibleMapRectMidPixels);

    /*
        ... but is it more than 1.0 screen pixel worth? (Otherwise the user
        probably wouldn't even notice).

        NOTE: Due to rounding errors it's hard to get exactly
        scrollDistancePixels == 0.0 anyway, so doing a check like this improves
        general responsiveness overall.
    */
    BOOL scrollNeeded = scrollDistancePixels > 1.0;

    if (rotationNeeded || scrollNeeded) {
        MKMapCamera *newCamera = [mapView.camera copy];
        if (rotationNeeded) {
            // Rotation the camera (e.g. to make the floorplan upright).
            newCamera.heading = optionalCameraHeading;
        }

        if (scrollNeeded) {
            // Scroll back toward the floorplan.
            MKMapPoint cameraCenter = MKMapPointForCoordinate(mapView.camera.centerCoordinate);
            cameraCenter.x += dxOffset;
            cameraCenter.y += dyOffset;
            newCamera.centerCoordinate = MKCoordinateForMapPoint(cameraCenter);
        }

        [mapView setCamera:newCamera animated:YES];
    }

}

#pragma mark - AAPLVisibleMapRegionDelegate

@interface AAPLVisibleMapRegionDelegate ()

/// Set to YES if you would want reset the MapCamera to center on the floorplan.
@property BOOL needsCameraOrientationReset;

@end

@implementation AAPLVisibleMapRegionDelegate

@synthesize boundingMapRectIncludingRotations;
@synthesize boundingPDFBox;
@synthesize floorplanCenter;
@synthesize floorplanUprightMKMapCameraHeading;

- (instancetype)initWithFloorplanBounds:(MKMapRect)boundingMapRectWithRotations pdfBoundingBox:(AAPLMKMapRectRotated)pdfBoundingBox centerOfFloorplan:(CLLocationCoordinate2D)centerOfFloorplan floorplanUprightMKMapCameraHeading:(CLLocationDirection)heading {

    self = [super init];

    if (self) {
        boundingMapRectIncludingRotations = boundingMapRectWithRotations;
        boundingPDFBox = pdfBoundingBox;
        floorplanCenter = centerOfFloorplan;
        floorplanUprightMKMapCameraHeading = heading;

        _lastAltitude = NAN;

        _needsCameraOrientationReset = YES;
    }

    return self;
}

- (void)mapViewResetCameraToFloorplan:(MKMapView *)mapView {
    resetCameraOrientation(mapView, floorplanCenter, floorplanUprightMKMapCameraHeading);
}

// Catch regionDidChange events to ensure that we can always see the floorplan.
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MKMapCamera * camera = mapView.camera;

    BOOL didClampZoom = NO;

    // Has the zoom level stabilized?
    if (_lastAltitude != camera.altitude) {
        // Not yet! Someone is changing the zoom!

        _lastAltitude = camera.altitude;

        // Auto-zoom the camera to fit the floorplan.
        didClampZoom = clampZoomToFloorplan(mapView, boundingMapRectIncludingRotations, floorplanCenter);
    }

    if (!didClampZoom) {
        // Once the zoom level has stabilized, auto-scroll if needed.
        clampScrollToFloorplan(mapView, boundingPDFBox, (self.needsCameraOrientationReset) ? floorplanUprightMKMapCameraHeading : NAN);
        self.needsCameraOrientationReset = NO;
    }
}

@end

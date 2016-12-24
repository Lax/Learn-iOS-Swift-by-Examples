# Footprint: Indoor Location with Core Location

Display device location against a custom floorplan PDF.
 * First, we will draw your floorplan inside MapKit so that it matches its real-world Latitude/Longitude values.
 * Then, using Core Location, we will take the position in Latitude/Longitude and display it in MapKit.

We will demonstrate how to do the conversions between Geographic coordinate systems (Latitude/Longitude), floorplan PDF coordinate systems (x,y), and MapKit coordinates.

Note: For this sample to show a real location & floor number, you must have a floorplan for a venue that is Indoor Positioning enabled and the device will need to be in that venue. If you are not in a venue, try emulating a position in the venue using "Custom Location" in the simulator. Otherwise, the user's location will be shown far from the default floorplan and venue displayed in this app. Additionally, to ensure that user location is actually visible, you will need to enable it in the Attribute Inspector on the Map View in Main.storyboard. From there, the user would need to either allow the app to use their location from Settings or select "Allow" when prompted by the app the first time it is run.

## AAPLViewController

This is your main view controller class which handles most of the display functionality. Three IBActions are available from the storyboard:

To help with debugging we’ve added a toolbar at the bottom to provide some common operations.
* Close (remove the AAPLHideBackgroundOverlay to reveal the underlying base maps, as you would see in a typical “outdoor” app that uses MKMapView — most importantly, this allows you to verify the real-world coordinates of the AAPLGeoAnchorPoints that you set in AAPLViewController)
* Rotate (restore the origin camera view, centered on the floorplan and, most importantly, with the "floorplan facing up” — instead of "North facing up” which is the default when you use MKMapView out-of-the-box)
* Debug (toggle debugging visuals on/off — shows additional overlays and annotations that correspond to the various internal variables inside the code. Use this as a reference when debugging anchor points, overlays, or any other rendering/interaction provided in this sample code. If Close has been pressed, this also toggles the floorplan on and off so it can be seen over the underlying maps)

## AAPLVisibleMapRegionDelegate

This handles the case where the user zooms or scrolls too far away from the floorplan by automatically "bouncing back" when this happens.

## Converters and Renderers

### AAPLCoordinateConvereter

This is used as a converter from the coordinates in the PDF image of the floorplan to geographic coordinates. This may be modified to work with raster images such as JPEGs and PNGs but this is not recommended as they won't render as clearly. See comments for more information

### AAPLFloorplanOverlay

This is used to describe the floorplan of an indoor venue and is based upon MKOverlay

### AAPLFloorplanOverlayRenderer

This is used to render an AAPLFloorplanOverlay onto a map view and also handles some debugging tasks

### AAPLHideBackgroundOverlay

This is used to hide MapKit's underlying map tiles so that only our floorplan is visible

## Using Your Own Floorplan
If you have a venue floorplan you would like to use, make the following changes:

Step \#1: Replace (or add) `floorplan_overlay_floor0.pdf` in `Floorplans`. If necessary, update the filename in `AAPLViewController.m` `viewDidLoad`

Step \#2: Look for the `AAPLGeoAnchorPair` struct in `AAPLViewController.m` `viewDidLoad` and set them to your own values. Pick any two points on the floorplan (in PDF x,y) as well as their corresponding real-world locations (in Latitude/Longitude)

Step \#3: Follow the code comments of `drawDiagnosticVisuals` in `AAPLFloorplanOverlayRenderer.m` to verify that your (x,y) values from Step \#2 are correct.

Step \#4: Follow the code comments of `setDebuggingAnnotationsOfMapView`: in `AAPLViewController.m` to verify that your (Latitude/Longitude) values from Step \#2 are correct.

## Requirements

### Build

Xcode 7.0, iOS 9 or later

### Runtime

Xcode 7.0 Simulator (OS X 10.10.3)
iOS 9 or later

Copyright (C) 2014-2015 Apple Inc. All rights reserved.

/**
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Primary view controller for what is displayed by the application. In this class we configure an MKMapView to display a floorplan, recieve location updates to determine floor number, as well as provide a few helpful debugging annotations.
    
                We will also show how to highlight a region that you have defined in PDF coordinates but not Latitude  Longitude.
*/

@import UIKit;

/**
    Primary view controller for what is displayed by the application.

    In this class we configure an \c MKMapView to display a floorplan, recieve
    location updates to determine floor number, as well as provide a few helpful
    debugging annotations.

    We will also show how to highlight a region that you have defined in PDF
    coordinates but not Latitude & Longitude.
*/
@interface AAPLViewController : UIViewController
@end

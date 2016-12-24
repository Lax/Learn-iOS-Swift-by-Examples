/**
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class provides an MKOverlay that can be used to hide MapKit's underlaying map tiles.
*/

@import MapKit;

/**
    This class provides an \c MKOverlay that can be used to hide MapKit's
    underlaying map tiles.
*/
@interface AAPLHideBackgroundOverlay : MKPolygon

/// @return an \c AAPLHideBackgroundOverlay object that covers the world
+ (instancetype)hideBackgroundOverlay;

@end

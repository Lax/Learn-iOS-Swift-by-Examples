/**
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class provides an MKOverlay that can be used to hide MapKit's underlaying map tiles.
*/

#import "AAPLHideBackgroundOverlay.h"

@implementation AAPLHideBackgroundOverlay

+ (instancetype)hideBackgroundOverlay {
    MKMapPoint corners[4];
    corners[0] = MKMapPointMake(MKMapRectGetMaxX(MKMapRectWorld), MKMapRectGetMaxY(MKMapRectWorld));
    corners[1] = MKMapPointMake(MKMapRectGetMinX(MKMapRectWorld), MKMapRectGetMaxY(MKMapRectWorld));
    corners[2] = MKMapPointMake(MKMapRectGetMinX(MKMapRectWorld), MKMapRectGetMinY(MKMapRectWorld));
    corners[3] = MKMapPointMake(MKMapRectGetMaxX(MKMapRectWorld), MKMapRectGetMinY(MKMapRectWorld));

    return [AAPLHideBackgroundOverlay polygonWithPoints:corners count:4];
}

/**
    @return YES to tell MapKit to hide its underlying map tiles, as long as
        this overlay is visible (which, as you can see above, is everywhere in
        the world), effectively hiding all map tiles and replacing them with a
        solid colored \c MKPolygon.
 */
- (BOOL)canReplaceMapContent {
    return YES;
}

@end

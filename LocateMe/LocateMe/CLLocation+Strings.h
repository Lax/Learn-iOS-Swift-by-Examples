/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:

This is an Objective C category on the CLLocation class that extends the class by adding some convenience methods for presenting localized string representations of various properties.

*/

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (Strings)

- (NSString *)localizedCoordinateString;
- (NSString *)localizedAltitudeString;
- (NSString *)localizedHorizontalAccuracyString;
- (NSString *)localizedVerticalAccuracyString;
- (NSString *)localizedCourseString;
- (NSString *)localizedSpeedString;

@end

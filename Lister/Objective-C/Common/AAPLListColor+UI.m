/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Enhancements for the \c AAPLListColor enumeration that add the ability to obtain a platform-specific color object from the enumeration value.
*/

#import "AAPLListColor+UI.h"

#if TARGET_OS_IPHONE
#define AAPLAppColor UIColor
#elif TARGET_OS_MAC
#define AAPLAppColor NSColor
#endif

AAPLAppColor *AAPLColorFromListColor(AAPLListColor listColor) {
    static AAPLAppColor *_grayColor = nil;
    static AAPLAppColor *_blueColor = nil;
    static AAPLAppColor *_greenColor = nil;
    static AAPLAppColor *_yellowColor = nil;
    static AAPLAppColor *_orangeColor = nil;
    static AAPLAppColor *_redColor = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _grayColor = [AAPLAppColor darkGrayColor];
        _blueColor = [AAPLAppColor colorWithRed:0.42 green:0.70 blue:0.88 alpha:1];
        _greenColor = [AAPLAppColor colorWithRed:0.71 green:0.84 blue:0.31 alpha:1];
        _yellowColor = [AAPLAppColor colorWithRed:0.95 green:0.88 blue:0.15 alpha:1];
        _orangeColor = [AAPLAppColor colorWithRed:0.96 green:0.63 blue:0.20 alpha:1];
        _redColor = [AAPLAppColor colorWithRed:0.96 green:0.42 blue:0.42 alpha:1];
    });

    switch (listColor) {
        case AAPLListColorGray:     return _grayColor;
        case AAPLListColorBlue:     return _blueColor;
        case AAPLListColorGreen:    return _greenColor;
        case AAPLListColorYellow:   return _yellowColor;
        case AAPLListColorOrange:   return _orangeColor;
        case AAPLListColorRed:      return _redColor;
    }

    return nil;
}

#undef AAPLAppColor
/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  Enhancements for the AAPLListColor enumeration that add the ability to obtain a platform-specific color object from the enumeration value.
              
 */

@import Foundation;
#import "AAPLList.h"

#if TARGET_OS_IPHONE

@import UIKit;
#define AAPLAppColor UIColor

#elif TARGET_OS_MAC

@import Cocoa;
#define AAPLAppColor NSColor

#endif

AAPLAppColor *AAPLColorFromListColor(AAPLListColor listColor);

#undef AAPLAppColor
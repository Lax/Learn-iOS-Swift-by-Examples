/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Application specific colors.
*/

#import "UIColor+AAPLApplicationSpecific.h"

@implementation UIColor (AAPLApplicationSpecific)

+ (UIColor *)aapl_applicationGreenColor {
    return [UIColor colorWithRed:0.255 green:0.804 blue:0.470 alpha:1];
}

+ (UIColor *)aapl_applicationBlueColor {
    return [UIColor colorWithRed:0.333 green:0.784 blue:1 alpha:1];
}

+ (UIColor *)aapl_applicationPurpleColor {
    return [UIColor colorWithRed:0.659 green:0.271 blue:0.988 alpha:1];
}

@end

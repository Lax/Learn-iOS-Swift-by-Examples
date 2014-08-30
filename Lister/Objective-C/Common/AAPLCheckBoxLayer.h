/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A CALayer subclass that draws a check box within its layer. This is shared between ListerKit and ListerKitOSX to draw their respective AAPLCheckBox controls.
            
*/

@import QuartzCore;

@interface AAPLCheckBoxLayer : CALayer

@property CGColorRef tintColor;

@property (getter=isChecked) BOOL checked;

@property CGFloat strokeFactor;
@property CGFloat insetFactor;
@property CGFloat markInsetFactor;

@end

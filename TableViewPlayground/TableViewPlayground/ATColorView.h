/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A basic NSView subclass that supports having an animatable background color (NOTE: the animation only works when the view is layer backed).
 */

@import Cocoa;

@interface ATColorView : NSControl

@property (strong, nonatomic) NSColor *backgroundColor;
@property BOOL drawBorder;

@end

/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Exposes game controller action button type functionality with screen-rendered buttons.
 */

#import <Foundation/Foundation.h>

#import "AAPLPadOverlay.h"
#import "AAPLButtonOverlay.h"

@interface AAPLControlOverlay : SKNode

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

@property (nonatomic, retain) AAPLPadOverlay* leftPad;
@property (nonatomic, retain) AAPLPadOverlay* rightPad;
@property (nonatomic, retain) AAPLButtonOverlay* buttonA;
@property (nonatomic, retain) AAPLButtonOverlay* buttonB;

@end

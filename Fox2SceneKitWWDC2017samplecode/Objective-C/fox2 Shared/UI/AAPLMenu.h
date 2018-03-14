/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Custom `SKNode` based menu.
 */

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

#import "AAPLButton.h"
#import "AAPLSlider.h"

@class AAPLMenu;

@protocol AAPLMenuDelegate <NSObject>

- (void)fStopChanged:(CGFloat)value;
- (void)focusDistanceChanged:(CGFloat)value;
- (void)debugMenuSelectCameraAtIndex:(NSUInteger)index;

@end

@interface AAPLMenu : SKNode

@property (nonatomic, weak) id<AAPLMenuDelegate> delegate;

- (id)initWithSize:(CGSize)size;
- (void)showMenu;

@end

/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Support class for action buttons.
 */

#import <SpriteKit/SpriteKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AAPLButtonOverlay;

@protocol AAPLButtonOverlayDelegate <NSObject>

- (void)willPressButtonOverlay:(AAPLButtonOverlay*)button;
- (void)didPressButtonOverlay:(AAPLButtonOverlay*)button;

@end

@interface AAPLButtonOverlay : SKNode

// Default 25, 25
@property (nonatomic, assign) CGSize size;

@property (nonatomic, weak, nullable) id<AAPLButtonOverlayDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithText:(NSString *)text NS_DESIGNATED_INITIALIZER;

NS_ASSUME_NONNULL_END

@end

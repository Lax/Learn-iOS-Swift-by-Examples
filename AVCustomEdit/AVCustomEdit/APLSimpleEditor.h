/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Simple editor sets up an AVMutableComposition using supplied clips and time ranges. It also sets up an AVVideoComposition to perform custom compositor rendering.
 */

#import <Foundation/Foundation.h>

#import <CoreMedia/CMTime.h>

@class AVPlayerItem, AVAssetExportSession;

@interface APLSimpleEditor : NSObject

// Set these properties before building the composition objects.
@property (nonatomic, copy) NSArray *clips; // array of AVURLAssets
@property (nonatomic, copy) NSArray *clipTimeRanges; // array of CMTimeRanges stored in NSValues.

@property (nonatomic) NSInteger transitionType;
@property (nonatomic) CMTime transitionDuration;

// Builds the composition and videoComposition
- (void)buildCompositionObjectsForPlayback:(BOOL)forPlayback;

- (AVAssetExportSession*)assetExportSessionWithPreset:(NSString*)presetName;

- (AVPlayerItem *)playerItem;

@end

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Main class used to demonstrate reading/writing of assets.
 */

@import AppKit;
@import CoreMedia;
@import AVFoundation;

@class AAPLSampleBufferChannel;
@class AAPLProgressPanelController;

@interface AAPLDocument : NSDocument
{
@private
	IBOutlet NSView				*frameView;
	IBOutlet NSPopUpButton		*filterPopUpButton;

	AVAsset						*asset;
	AVAssetImageGenerator		*imageGenerator;
	CMTimeRange					timeRange;
	NSInteger					filterTag;
	dispatch_queue_t			serializationQueue;
	
	// Only accessed on the main thread
	NSURL						*outputURL;
	BOOL						writingSamples;
	AAPLProgressPanelController	*progressPanelController;

	// All of these are createed, accessed, and torn down exclusively on the serializaton queue
	AVAssetReader				*assetReader;
	AVAssetWriter				*assetWriter;
	AAPLSampleBufferChannel		*audioSampleBufferChannel;
	AAPLSampleBufferChannel		*videoSampleBufferChannel;
	BOOL						cancelled;	
}

@property (nonatomic, retain) AVAsset *asset;
@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic, copy) NSURL *outputURL;

@property (nonatomic, retain) IBOutlet NSView *frameView;
@property (nonatomic, retain) IBOutlet NSPopUpButton *filterPopUpButton;

- (IBAction)start:(id)sender;
- (IBAction)cancel:(id)sender;
@property (nonatomic, getter=isWritingSamples) BOOL writingSamples;

@end

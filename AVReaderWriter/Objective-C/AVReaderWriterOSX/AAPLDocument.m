/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Main class used to demonstrate reading/writing of assets.
 */

#import "AAPLDocument.h"
#import "AAPLProgressPanelController.h"

@protocol AAPLSampleBufferChannelDelegate;

@interface AAPLSampleBufferChannel : NSObject
{
@private
	AVAssetReaderOutput		*assetReaderOutput;
	AVAssetWriterInput		*assetWriterInput;
	
	dispatch_block_t		completionHandler;
	dispatch_queue_t		serializationQueue;
	BOOL					finished;  // only accessed on serialization queue
}
- (id)initWithAssetReaderOutput:(AVAssetReaderOutput *)assetReaderOutput assetWriterInput:(AVAssetWriterInput *)assetWriterInput;
@property (nonatomic, readonly) NSString *mediaType;
- (void)startWithDelegate:(id <AAPLSampleBufferChannelDelegate>)delegate completionHandler:(dispatch_block_t)completionHandler;  // delegate is retained until completion handler is called.  Completion handler is guaranteed to be called exactly once, whether reading/writing finishes, fails, or is cancelled.  Delegate may be nil.
- (void)cancel;
@end


@protocol AAPLSampleBufferChannelDelegate <NSObject>
@required
- (void)sampleBufferChannel:(AAPLSampleBufferChannel *)sampleBufferChannel didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end


@interface AAPLDocument () <AAPLSampleBufferChannelDelegate, AAPLProgressPanelControllerDelegate>
- (void)setPreviewLayerContents:(id)contents gravity:(NSString *)gravity;
// These three methods are always called on the serialization dispatch queue
- (BOOL)setUpReaderAndWriterReturningError:(NSError **)outError;  // make sure "tracks" key of asset is loaded before calling this
- (BOOL)startReadingAndWritingReturningError:(NSError **)outError;
- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error;
@end


@implementation AAPLDocument

+ (NSArray *)readableTypes
{
	return [AVURLAsset audiovisualTypes];
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
	return YES;
}

- (id)init
{
    self = [super init];
    
	if (self)
	{
		NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
		serializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    }
    
	return self;
}

- (void)dealloc
{
	[asset release];
	[imageGenerator release];
	[outputURL release];
	[progressPanelController setDelegate:nil];
	[progressPanelController release];
	[frameView release];
	[filterPopUpButton release];
	
	[assetReader release];
	[assetWriter release];
	[audioSampleBufferChannel release];
	[videoSampleBufferChannel release];
	if (serializationQueue)
		dispatch_release(serializationQueue);
	
	[super dealloc];
}

- (NSString *)windowNibName
{
	return @"AAPLDocument";
}

@synthesize frameView=frameView;
@synthesize filterPopUpButton=filterPopUpButton;

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	
	// Create a layer and set it on the view.  We will display video frames by setting the contents of the layer.
	CALayer *localFrameLayer = [CALayer layer];
	NSView *localFrameView = [self frameView];
	[localFrameView setLayer:localFrameLayer];
	[localFrameView setWantsLayer:YES];
	
	// Generate an image of some sort to use as a preview
	AVAsset *localAsset = [self asset];
	[localAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^{
		if ([localAsset statusOfValueForKey:@"tracks" error:NULL] != AVKeyValueStatusLoaded)
			return;
		
		NSArray *visualTracks = [localAsset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
		NSArray *audibleTracks = [localAsset tracksWithMediaCharacteristic:AVMediaCharacteristicAudible];
		if ([visualTracks count] > 0)
		{
			// Grab the first frame from the asset and display it
			[imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:kCMTimeZero]] completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
				if (result == AVAssetImageGeneratorSucceeded)
					[self setPreviewLayerContents:(id)image gravity:kCAGravityResizeAspect];
				else
					[self setPreviewLayerContents:[NSImage imageNamed:@"ErrorLoading2x"] gravity:kCAGravityCenter];
			}];
		}
		else if ([audibleTracks count] > 0)
		{
			[self setPreviewLayerContents:[NSImage imageNamed:@"AudioOnly2x"] gravity:kCAGravityCenter];
		}
		else
		{
			[self setPreviewLayerContents:[NSImage imageNamed:@"ErrorLoading2x"] gravity:kCAGravityCenter];
		}
	}];
}

- (void)setPreviewLayerContents:(id)contents gravity:(NSString *)gravity
{
	CALayer *localFrameLayer = [[self frameView] layer];
	
	[CATransaction begin];  // need a transaction since we are not executing on the main thread
	{
		[localFrameLayer setContents:contents];
		[localFrameLayer setContentsGravity:gravity];
	}
	[CATransaction commit];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	NSDictionary *assetOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
	AVAsset *localAsset = [AVURLAsset URLAssetWithURL:url options:assetOptions];
	[self setAsset:localAsset];
	if (localAsset)
		imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:localAsset];
	
	return (localAsset != nil);
}

- (void)close
{
	[self cancel:self];
	
	[super close];
}

@synthesize asset=asset;
@synthesize timeRange=timeRange;
@synthesize writingSamples=writingSamples;
@synthesize outputURL=outputURL;

- (IBAction)start:(id)sender
{
	cancelled = NO;
	
	// Let the user choose an output file, then start the process of writing samples
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:AVFileTypeQuickTimeMovie]];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton)
			[self performSelector:@selector(startProgressSheetWithURL:) withObject:[savePanel URL] afterDelay:0.0];  // avoid starting a new sheet while in the old sheet's completion handler
	}];
}

- (void)startProgressSheetWithURL:(NSURL *)localOutputURL
{
	[self setOutputURL:localOutputURL];
	[self setWritingSamples:YES];
	filterTag = [[self filterPopUpButton] selectedTag];
	
	progressPanelController = [[AAPLProgressPanelController alloc] initWithWindowNibName:@"AAPLProgressPanel"];
	[progressPanelController setDelegate:self];
	
	[NSApp beginSheet:[progressPanelController window] modalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(progressPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	
	AVAsset *localAsset = [self asset];
	[localAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObjects:@"tracks", @"duration", nil] completionHandler:^{
		// Dispatch the setup work to the serialization queue, to ensure this work is serialized with potential cancellation
		dispatch_async(serializationQueue, ^{
			// Since we are doing these things asynchronously, the user may have already cancelled on the main thread.  In that case, simply return from this block
			if (cancelled)
				return;
			
			BOOL success = YES;
			NSError *localError = nil;
			
			success = ([localAsset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
			if (success)
				success = ([localAsset statusOfValueForKey:@"duration" error:&localError] == AVKeyValueStatusLoaded);
			
			if (success)
			{
				[self setTimeRange:CMTimeRangeMake(kCMTimeZero, [localAsset duration])];

				// AVAssetWriter does not overwrite files for us, so remove the destination file if it already exists
				NSFileManager *fm = [NSFileManager defaultManager];
				NSString *localOutputPath = [localOutputURL path];
				if ([fm fileExistsAtPath:localOutputPath])
					success = [fm removeItemAtPath:localOutputPath error:&localError];
			}
			
			// Set up the AVAssetReader and AVAssetWriter, then begin writing samples or flag an error
			if (success)
				success = [self setUpReaderAndWriterReturningError:&localError];
			if (success)
				success = [self startReadingAndWritingReturningError:&localError];
			if (!success)
				[self readingAndWritingDidFinishSuccessfully:success withError:localError];
		});
	}];
}

- (void)progressPanelControllerDidCancel:(AAPLProgressPanelController *)localProgressPanelController
{
	[self cancel:nil];
}

- (void)progressPanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[progressPanelController setDelegate:nil];
	[progressPanelController release];
	progressPanelController = nil;
}

- (BOOL)setUpReaderAndWriterReturningError:(NSError **)outError
{
	BOOL success = YES;
	NSError *localError = nil;
	AVAsset *localAsset = [self asset];
	NSURL *localOutputURL = [self outputURL];
	
	// Create asset reader and asset writer
	assetReader = [[AVAssetReader alloc] initWithAsset:asset error:&localError];
	success = (assetReader != nil);
	if (success)
	{
		assetWriter = [[AVAssetWriter alloc] initWithURL:localOutputURL fileType:AVFileTypeQuickTimeMovie error:&localError];
		success = (assetWriter != nil);
	}

	// Create asset reader outputs and asset writer inputs for the first audio track and first video track of the asset
	if (success)
	{
		AVAssetTrack *audioTrack = nil, *videoTrack = nil;
		
		// Grab first audio track and first video track, if the asset has them
		NSArray *audioTracks = [localAsset tracksWithMediaType:AVMediaTypeAudio];
		if ([audioTracks count] > 0)
			audioTrack = [audioTracks objectAtIndex:0];
		NSArray *videoTracks = [localAsset tracksWithMediaType:AVMediaTypeVideo];
		if ([videoTracks count] > 0)
			videoTrack = [videoTracks objectAtIndex:0];
		
		if (audioTrack)
		{
			// Decompress to Linear PCM with the asset reader
			NSDictionary *decompressionAudioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
														nil];
			AVAssetReaderOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:decompressionAudioSettings];
			[assetReader addOutput:output];
			
			AudioChannelLayout stereoChannelLayout = {
				.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
				.mChannelBitmap = 0,
				.mNumberChannelDescriptions = 0
			};
			NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];

			// Compress to 128kbps AAC with the asset writer
			NSDictionary *compressionAudioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
													  [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
													  [NSNumber numberWithInteger:128000], AVEncoderBitRateKey,
													  [NSNumber numberWithInteger:44100], AVSampleRateKey,
													  channelLayoutAsData, AVChannelLayoutKey,
													  [NSNumber numberWithUnsignedInteger:2], AVNumberOfChannelsKey,
													  nil];
			AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:[audioTrack mediaType] outputSettings:compressionAudioSettings];
			[assetWriter addInput:input];
			
			// Create and save an instance of AAPLSampleBufferChannel, which will coordinate the work of reading and writing sample buffers
			audioSampleBufferChannel = [[AAPLSampleBufferChannel alloc] initWithAssetReaderOutput:output assetWriterInput:input];
		}
		
		if (videoTrack)
		{
			// Decompress to ARGB with the asset reader
			NSDictionary *decompressionVideoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB], (id)kCVPixelBufferPixelFormatTypeKey,
														[NSDictionary dictionary], (id)kCVPixelBufferIOSurfacePropertiesKey,
														nil];
			AVAssetReaderOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:decompressionVideoSettings];
			[assetReader addOutput:output];
			
			// Get the format description of the track, to fill in attributes of the video stream that we don't want to change
			CMFormatDescriptionRef formatDescription = NULL;
			NSArray *formatDescriptions = [videoTrack formatDescriptions];
			if ([formatDescriptions count] > 0)
				formatDescription = (CMFormatDescriptionRef)[formatDescriptions objectAtIndex:0];
			
			// Grab track dimensions from format description
			CGSize trackDimensions = {
				.width = 0.0,
				.height = 0.0,
			};
			if (formatDescription)
				trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
			else
				trackDimensions = [videoTrack naturalSize];

			// Grab clean aperture, pixel aspect ratio from format description
			NSDictionary *compressionSettings = nil;
			if (formatDescription)
			{
				NSDictionary *cleanAperture = nil;
				NSDictionary *pixelAspectRatio = nil;
				CFDictionaryRef cleanApertureFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_CleanAperture);
				if (cleanApertureFromCMFormatDescription)
				{
					cleanAperture = [NSDictionary dictionaryWithObjectsAndKeys:
									 CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureWidth), AVVideoCleanApertureWidthKey,
									 CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHeight), AVVideoCleanApertureHeightKey,
									 CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHorizontalOffset), AVVideoCleanApertureHorizontalOffsetKey,
									 CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureVerticalOffset), AVVideoCleanApertureVerticalOffsetKey,
									 nil];
				}
				CFDictionaryRef pixelAspectRatioFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_PixelAspectRatio);
				if (pixelAspectRatioFromCMFormatDescription)
				{
					pixelAspectRatio = [NSDictionary dictionaryWithObjectsAndKeys:
										CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing), AVVideoPixelAspectRatioHorizontalSpacingKey,
										CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing), AVVideoPixelAspectRatioVerticalSpacingKey,
										nil];
				}
				
				if (cleanAperture || pixelAspectRatio)
				{
					NSMutableDictionary *mutableCompressionSettings = [NSMutableDictionary dictionary];
					if (cleanAperture)
						[mutableCompressionSettings setObject:cleanAperture forKey:AVVideoCleanApertureKey];
					if (pixelAspectRatio)
						[mutableCompressionSettings setObject:pixelAspectRatio forKey:AVVideoPixelAspectRatioKey];
					compressionSettings = mutableCompressionSettings;
				}
			}
			
			// Compress to H.264 with the asset writer
			NSMutableDictionary *videoSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
															 AVVideoCodecH264, AVVideoCodecKey,
															 [NSNumber numberWithDouble:trackDimensions.width], AVVideoWidthKey,
															 [NSNumber numberWithDouble:trackDimensions.height], AVVideoHeightKey,
															 nil];
			if (compressionSettings)
				[videoSettings setObject:compressionSettings forKey:AVVideoCompressionPropertiesKey];
			
			AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:[videoTrack mediaType] outputSettings:videoSettings];
			[assetWriter addInput:input];
			
			// Create and save an instance of AAPLSampleBufferChannel, which will coordinate the work of reading and writing sample buffers
			videoSampleBufferChannel = [[AAPLSampleBufferChannel alloc] initWithAssetReaderOutput:output assetWriterInput:input];
		}
	}
	
	if (outError)
		*outError = localError;
	
	return success;
}

- (BOOL)startReadingAndWritingReturningError:(NSError **)outError
{
	BOOL success = YES;
	NSError *localError = nil;

	// Instruct the asset reader and asset writer to get ready to do work
	success = [assetReader startReading];
	if (!success)
		localError = [assetReader error];
	if (success)
	{
		success = [assetWriter startWriting];
		if (!success)
			localError = [assetWriter error];
	}
	
	if (success)
	{
		dispatch_group_t dispatchGroup = dispatch_group_create();
		
		// Start a sample-writing session
		[assetWriter startSessionAtSourceTime:[self timeRange].start];
		
		// Start reading and writing samples
		if (audioSampleBufferChannel)
		{
			// Only set audio delegate for audio-only assets, else let the video channel drive progress
			id <AAPLSampleBufferChannelDelegate> delegate = nil;
			if (!videoSampleBufferChannel)
				delegate = self;

			dispatch_group_enter(dispatchGroup);
			[audioSampleBufferChannel startWithDelegate:delegate completionHandler:^{
				dispatch_group_leave(dispatchGroup);
			}];
		}
		if (videoSampleBufferChannel)
		{
			dispatch_group_enter(dispatchGroup);
			[videoSampleBufferChannel startWithDelegate:self completionHandler:^{
				dispatch_group_leave(dispatchGroup);
			}];
		}
		
		// Set up a callback for when the sample writing is finished
		dispatch_group_notify(dispatchGroup, serializationQueue, ^{
			BOOL finalSuccess = YES;
			NSError *finalError = nil;
			
			if (cancelled)
			{
				[assetReader cancelReading];
				[assetWriter cancelWriting];
			}
			else
			{
				if ([assetReader status] == AVAssetReaderStatusFailed)
				{
					finalSuccess = NO;
					finalError = [assetReader error];
				}
				
				if (finalSuccess)
				{
					finalSuccess = [assetWriter finishWriting];
					if (!finalSuccess)
						finalError = [assetWriter error];
				}
			}

			[self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
		});
		
		dispatch_release(dispatchGroup);
	}
	
	if (outError)
		*outError = localError;
	
	return success;
}

- (void)cancel:(id)sender
{
	// Dispatch cancellation tasks to the serialization queue to avoid races with setup and teardown
	dispatch_async(serializationQueue, ^{
		[audioSampleBufferChannel cancel];
		[videoSampleBufferChannel cancel];
		cancelled = YES;
	});
}

- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error
{
	if (!success)
	{
		[assetReader cancelReading];
		[assetWriter cancelWriting];
	}
	
	// Tear down ivars
	[assetReader release];
	assetReader = nil;
	[assetWriter release];
	assetWriter = nil;
	[audioSampleBufferChannel release];
	audioSampleBufferChannel = nil;
	[videoSampleBufferChannel release];
	videoSampleBufferChannel = nil;
	cancelled = NO;
	
	// Dispatch UI-related tasks to the main queue
	dispatch_async(dispatch_get_main_queue(), ^{
		// Order out and end the progress panel
		NSWindow *progressPanel = [progressPanelController window];
		[progressPanel orderOut:self];
		[NSApp endSheet:progressPanel];
		 
		if (!success)
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setAlertStyle:NSCriticalAlertStyle];
			[alert setMessageText:[error localizedDescription]];
			NSString *informativeText = [error localizedRecoverySuggestion];
			informativeText = informativeText ? informativeText : [error localizedFailureReason]; // No recovery suggestion, then at least tell the user why it failed.
			[alert setInformativeText:informativeText]; 
			
			[alert beginSheetModalForWindow:[self windowForSheet]
							  modalDelegate:self
							 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
								contextInfo:NULL];
			[alert release];
		}
		[self setWritingSamples:NO];
	});
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	// Do nothing
}

static double progressOfSampleBufferInTimeRange(CMSampleBufferRef sampleBuffer, CMTimeRange timeRange)
{
	CMTime progressTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
	progressTime = CMTimeSubtract(progressTime, timeRange.start);
	CMTime sampleDuration = CMSampleBufferGetDuration(sampleBuffer);
	if (CMTIME_IS_NUMERIC(sampleDuration))
		progressTime= CMTimeAdd(progressTime, sampleDuration);
	return CMTimeGetSeconds(progressTime) / CMTimeGetSeconds(timeRange.duration);
}

static void removeARGBColorComponentOfPixelBuffer(CVPixelBufferRef pixelBuffer, size_t componentIndex)
{
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	
	size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
	size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
	static const size_t bytesPerPixel = 4;  // constant for ARGB pixel format
	unsigned char *base = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
	for (size_t row = 0; row < bufferHeight; ++row)
	{		
		for (size_t column = 0; column < bufferWidth; ++column)
		{
			unsigned char *pixel = base + (row * bytesPerRow) + (column * bytesPerPixel);
			pixel[componentIndex] = 0;
		}
	}
	
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

+ (size_t)componentIndexFromFilterTag:(NSInteger)filterTag
{
	return (size_t)filterTag;  // we set up the tags in the popup button to correspond directly with the index they modify
}

- (void)sampleBufferChannel:(AAPLSampleBufferChannel *)sampleBufferChannel didReadSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
	CVPixelBufferRef pixelBuffer = NULL;
	
	// Calculate progress (scale of 0.0 to 1.0)
	double progress = progressOfSampleBufferInTimeRange(sampleBuffer, [self timeRange]);
	
	// Grab the pixel buffer from the sample buffer, if possible
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	if (imageBuffer && (CFGetTypeID(imageBuffer) == CVPixelBufferGetTypeID()))
	{
		pixelBuffer = (CVPixelBufferRef)imageBuffer;
		if (filterTag >= 0)  // -1 means "no filtering, please"
			removeARGBColorComponentOfPixelBuffer(pixelBuffer, [[self class] componentIndexFromFilterTag:filterTag]);
	}
	
	[progressPanelController setPixelBuffer:pixelBuffer forProgress:progress];
}

@end


@interface AAPLSampleBufferChannel ()
- (void)callCompletionHandlerIfNecessary;  // always called on the serialization queue
@end

@implementation AAPLSampleBufferChannel

- (id)initWithAssetReaderOutput:(AVAssetReaderOutput *)localAssetReaderOutput assetWriterInput:(AVAssetWriterInput *)localAssetWriterInput
{
	self = [super init];
	
	if (self)
	{
		assetReaderOutput = [localAssetReaderOutput retain];
		assetWriterInput = [localAssetWriterInput retain];
		
		finished = NO;
		NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
		serializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
	}
	
	return self;
}

- (void)dealloc
{
	[assetReaderOutput release];
	[assetWriterInput release];
	if (serializationQueue)
		dispatch_release(serializationQueue);
	[completionHandler release];
	
	[super dealloc];
}

- (NSString *)mediaType
{
	return [assetReaderOutput mediaType];
}

- (void)startWithDelegate:(id <AAPLSampleBufferChannelDelegate>)delegate completionHandler:(dispatch_block_t)localCompletionHandler
{
	completionHandler = [localCompletionHandler copy];  // released in -callCompletionHandlerIfNecessary

	[assetWriterInput requestMediaDataWhenReadyOnQueue:serializationQueue usingBlock:^{
		if (finished)
			return;
		
		BOOL completedOrFailed = NO;
		
		// Read samples in a loop as long as the asset writer input is ready
		while ([assetWriterInput isReadyForMoreMediaData] && !completedOrFailed)
		{
			CMSampleBufferRef sampleBuffer = [assetReaderOutput copyNextSampleBuffer];
			if (sampleBuffer != NULL)
			{
				if ([delegate respondsToSelector:@selector(sampleBufferChannel:didReadSampleBuffer:)])
					[delegate sampleBufferChannel:self didReadSampleBuffer:sampleBuffer];
				
				BOOL success = [assetWriterInput appendSampleBuffer:sampleBuffer];
				CFRelease(sampleBuffer);
				sampleBuffer = NULL;
				
				completedOrFailed = !success;
			}
			else
			{
				completedOrFailed = YES;
			}
		}
		
		if (completedOrFailed)
			[self callCompletionHandlerIfNecessary];
	}];
}

- (void)cancel
{
	dispatch_async(serializationQueue, ^{
		[self callCompletionHandlerIfNecessary];
	});
}

- (void)callCompletionHandlerIfNecessary
{
	// Set state to mark that we no longer need to call the completion handler, grab the completion handler, and clear out the ivar
	BOOL oldFinished = finished;
	finished = YES;

	if (oldFinished == NO)
	{
		[assetWriterInput markAsFinished];  // let the asset writer know that we will not be appending any more samples to this input

		dispatch_block_t localCompletionHandler = [completionHandler retain];
		[completionHandler release];
		completionHandler = nil;

		if (localCompletionHandler)
		{
			localCompletionHandler();
			[localCompletionHandler release];
		}
	}
}

@end

/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Main window controller for the sample app.
 */

#import "AAPLProgressPanelController.h"

@import QuartzCore;

@interface AAPLProgressPanelController ()
@property (nonatomic, retain) CALayer *frameLayer;
@end

@implementation AAPLProgressPanelController

- (void)dealloc
{
	[frameLayer release];
	[frameView release];
	[progressIndicator release];
	[interestingProgressValues release];

	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	// Create a layer and set it on the view.  We will display video frames by adding sublayers as we go
	CALayer *localFrameLayer = [CALayer layer];
	[self setFrameLayer:localFrameLayer];
	NSView *localFrameView = [self frameView];
	[localFrameView setLayer:localFrameLayer];
	[localFrameView setWantsLayer:YES];
}

@synthesize progressIndicator=progressIndicator;
@synthesize frameView=frameView;
@synthesize frameLayer=frameLayer;
@synthesize delegate=delegate;

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer forProgress:(double)progress
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self progressIndicator] setDoubleValue:progress];
	});
	
	if (pixelBuffer == NULL)
		return;
	
	CALayer *localFrameLayer = [self frameLayer];
	
	// Calculate size of image
	CGSize frameLayerSize = [localFrameLayer frame].size;
	double imageLayerWidth = (double)CVPixelBufferGetWidth(pixelBuffer) * frameLayerSize.height / (double)CVPixelBufferGetHeight(pixelBuffer);
	double imageLayerHeight = frameLayerSize.height;

	// Calculate position of image in the progress bar
	double expectedImageCount = ceil(frameLayerSize.width / imageLayerWidth) + 2.0;
	double progressValueForFinalImage = (expectedImageCount - 1) / expectedImageCount;
	double imageLayerXPos = progress * (frameLayerSize.width - imageLayerWidth) / progressValueForFinalImage;
	double imageLayerYPos = 0.0;
	
	// If we haven't already done so, decide the set of progress values for which we will display an image
	if (!interestingProgressValues)
	{
		interestingProgressValues = [[NSMutableArray alloc] init];

		double progressDisplayInterval = 1.0 / expectedImageCount;
		for (NSInteger i = 0; i < (NSInteger)expectedImageCount; ++i)
			[interestingProgressValues addObject:[NSNumber numberWithDouble:((double)i * progressDisplayInterval)]];
	}
	
	// Determine whether we will display this frame
	BOOL displayThisFrame = NO;
	if ([interestingProgressValues count] > 0)
	{
		NSNumber *nextInterestingProgressValue = [interestingProgressValues objectAtIndex:0];
		// If we have progressed beyond the next progress value, make a note that we should display this one
		if (progress >= [nextInterestingProgressValue doubleValue])
		{
			displayThisFrame = YES;
			[interestingProgressValues removeObjectAtIndex:0];
		}
	}
	
	// If so, add a sublayer to the frame layer with the pixel buffer as its contents
	if (displayThisFrame)
	{
		CALayer *imageLayer = [[CALayer alloc] init];

		// Make contents for this layer
		NSImage *image = nil;
		id contents = (id)CVPixelBufferGetIOSurface(pixelBuffer);  // try IOSurface first
		if (!contents)
		{
			// Fall back to creating an NSImage from the image buffer, via CIImage
			CIImage *ciImage = [[CIImage alloc] initWithCVImageBuffer:pixelBuffer];
			NSCIImageRep *imageRep = [[NSCIImageRep alloc] initWithCIImage:ciImage];
			[ciImage release];
			image = [[NSImage alloc] initWithSize:[imageRep size]];
			[image addRepresentation:imageRep];
			[imageRep release];
				
			contents = image;
		}
		
		// Set contents, frame, and initial opacity
		[CATransaction begin];  // need an explicit transaction since we may not be executing on the main thread
		{
			[imageLayer setContents:contents];
			[imageLayer setFrame:CGRectMake(imageLayerXPos, imageLayerYPos, imageLayerWidth, imageLayerHeight)];
			[imageLayer setOpacity:0.0];
			[localFrameLayer addSublayer:imageLayer];
		}
		[CATransaction commit];

		// Animate opacity from 0.0 -> 1.0
		[CATransaction begin];
		{
			[CATransaction setAnimationDuration:1.5];
			[imageLayer setOpacity:1.0];
		}
		[CATransaction commit];
		
		[image release];
		[imageLayer release];
	}
}

- (IBAction)cancel:(id)sender
{
	id <AAPLProgressPanelControllerDelegate> localDelegate = [self delegate];
	if (localDelegate && [localDelegate respondsToSelector:@selector(progressPanelControllerDidCancel:)])
		[localDelegate progressPanelControllerDidCancel:self];
}

@end

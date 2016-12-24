/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Main window controller for the sample app.
 */

@import AppKit;
@import CoreMedia;

@protocol AAPLProgressPanelControllerDelegate;

@interface AAPLProgressPanelController : NSWindowController
{
@private
	id <AAPLProgressPanelControllerDelegate> delegate;

	IBOutlet NSView							*frameView;
	IBOutlet NSProgressIndicator			*progressIndicator;
	CALayer									*frameLayer;
	
	NSMutableArray							*interestingProgressValues;
}

@property (nonatomic, retain) IBOutlet NSView *frameView;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, assign) id <AAPLProgressPanelControllerDelegate> delegate;

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer forProgress:(double)progress; // progress should be in the range 0.0 to 1.0
- (IBAction)cancel:(id)sender;

@end


@protocol AAPLProgressPanelControllerDelegate <NSObject>
@optional
- (void)progressPanelControllerDidCancel:(AAPLProgressPanelController *)progressPanelController;
@end

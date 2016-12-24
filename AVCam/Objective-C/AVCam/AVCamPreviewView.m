/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Application preview view.
*/

@import AVFoundation;

#import "AVCamPreviewView.h"

@implementation AVCamPreviewView

+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
	return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session
{
	return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
	self.videoPreviewLayer.session = session;
}

@end

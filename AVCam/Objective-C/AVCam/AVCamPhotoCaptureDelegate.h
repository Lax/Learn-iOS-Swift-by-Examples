/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Photo capture delegate.
*/

@import AVFoundation;

@interface AVCamPhotoCaptureDelegate : NSObject<AVCapturePhotoCaptureDelegate>

- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)requestedPhotoSettings willCapturePhotoAnimation:(void (^)())willCapturePhotoAnimation capturingLivePhoto:(void (^)( BOOL capturing ))capturingLivePhoto completed:(void (^)( AVCamPhotoCaptureDelegate *photoCaptureDelegate ))completed;

@property (nonatomic, readonly) AVCapturePhotoSettings *requestedPhotoSettings;

@end

/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	(Borrowed from aurioTouch sample code) This class demonstrates the audio APIs used to capture audio data from the microphone and play it out to the speaker. It also demonstrates how to play system sounds
*/

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioController : NSObject

@property (nonatomic, assign) BOOL muteAudio;
@property (nonatomic, assign, readonly) BOOL audioChainIsBeingReconstructed;

- (OSStatus)startIOUnit;
- (OSStatus)stopIOUnit;

@end

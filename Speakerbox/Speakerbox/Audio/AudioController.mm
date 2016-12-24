/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	(Borrowed from aurioTouch sample code) This class demonstrates the audio APIs used to capture audio data from the microphone and play it out to the speaker. It also demonstrates how to play system sounds
*/

#import "AudioController.h"

// Framework includes
#import <AVFoundation/AVAudioSession.h>

// Utility file includes
#import "CAXException.h"
#import "CAStreamBasicDescription.h"


struct CallbackData {
    AudioUnit               rioUnit;
    BOOL*                   muteAudio;
    BOOL*                   audioChainIsBeingReconstructed;
    
    CallbackData(): rioUnit(NULL), muteAudio(NULL), audioChainIsBeingReconstructed(NULL) {}
} cd;

// Render callback function
static OSStatus	performRender (void                         *inRefCon,
                               AudioUnitRenderActionFlags 	*ioActionFlags,
                               const AudioTimeStamp 		*inTimeStamp,
                               UInt32 						inBusNumber,
                               UInt32 						inNumberFrames,
                               AudioBufferList              *ioData)
{
    OSStatus err = noErr;
    if (*cd.audioChainIsBeingReconstructed == NO)
    {
        // we are calling AudioUnitRender on the input bus of Apple Voice Processing IO
        // this will store the audio data captured by the microphone in ioData
        err = AudioUnitRender(cd.rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
        
        // mute audio if needed
        if (*cd.muteAudio)
        {
            for (UInt32 i=0; i<ioData->mNumberBuffers; ++i)
                memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
        }
    }
    
    return err;
}


@interface AudioController () {
    AudioUnit               _rioUnit;
    BOOL                    _audioChainIsBeingReconstructed;
}

- (void)setupAudioSession;
- (void)setupIOUnit;
- (void)setupAudioChain;

@end

@implementation AudioController

@synthesize muteAudio = _muteAudio;

- (id)init
{
    if (self = [super init]) {
        _muteAudio = YES;
        [self setupAudioChain];
    }
    return self;
}


- (void)handleInterruption:(NSNotification *)notification
{
    try {
        UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
        NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
            [self stopIOUnit];
        }
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
            // make sure to activate the session
            NSError *error = nil;
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            if (nil != error) NSLog(@"AVAudioSession set active failed with error: %@", error);
            
            [self startIOUnit];
        }
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
}


- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)handleMediaServerReset:(NSNotification *)notification
{
    NSLog(@"Media server has reset");
    _audioChainIsBeingReconstructed = YES;
    
    usleep(25000); //wait here for some time to ensure that we don't delete these objects while they are being accessed elsewhere
    
    // rebuild the audio chain
    [self setupAudioChain];
    [self startIOUnit];
    
    _audioChainIsBeingReconstructed = NO;
}

- (void)setupAudioSession
{
    try {
        // Configure the audio session
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
        // we are going to play and record so we pick that category
        NSError *error = nil;
        [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's audio category");

        // set the mode to voice chat
        [sessionInstance setMode:AVAudioSessionModeVoiceChat error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's audio mode");

        // set the buffer duration to 5 ms
        NSTimeInterval bufferDuration = .005;
        [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's I/O buffer duration");
        
        // set the session's sample rate
        [sessionInstance setPreferredSampleRate:44100 error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's preferred sample rate");
        
        // add interruption handler
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:sessionInstance];
        
        // we don't do anything special in the route change notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRouteChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:sessionInstance];
        
        // if media services are reset, we need to rebuild our audio chain
        [[NSNotificationCenter defaultCenter]	addObserver:	self
                                                 selector:	@selector(handleMediaServerReset:)
                                                     name:	AVAudioSessionMediaServicesWereResetNotification
                                                   object:	sessionInstance];
    }
    
    catch (CAXException &e) {
        NSLog(@"Error returned from setupAudioSession: %d: %s", (int)e.mError, e.mOperation);
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupAudioSession");
    }
    
    return;
}


- (void)setupIOUnit
{
    try {
        // Create a new instance of Apple Voice Processing IO
        
        AudioComponentDescription desc;
        desc.componentType = kAudioUnitType_Output;
        desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;
        
        AudioComponent comp = AudioComponentFindNext(NULL, &desc);
        XThrowIfError(AudioComponentInstanceNew(comp, &_rioUnit), "couldn't create a new instance of Apple Voice Processing IO");
        
        //  Enable input and output on Apple Voice Processing IO
        //  Input is enabled on the input scope of the input element
        //  Output is enabled on the output scope of the output element
        
        UInt32 one = 1;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)), "could not enable input on Apple Voice Processing IO");
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one)), "could not enable output on Apple Voice Processing IO");
        
        // Explicitly set the input and output client formats
        // sample rate = 44100, num channels = 1, format = 32 bit floating point
        
        CAStreamBasicDescription ioFormat = CAStreamBasicDescription(44100, 1, CAStreamBasicDescription::kPCMFormatFloat32, false);
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &ioFormat, sizeof(ioFormat)), "couldn't set the input client format on Apple Voice Processing IO");
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &ioFormat, sizeof(ioFormat)), "couldn't set the output client format on Apple Voice Processing IO");
        
        // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number
        // of samples it will be asked to produce on any single given call to AudioUnitRender
        UInt32 maxFramesPerSlice = 4096;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32)), "couldn't set max frames per slice on Apple Voice Processing IO");
        
        // Get the property value back from Apple Voice Processing IO. We are going to use this value to allocate buffers accordingly
        UInt32 propSize = sizeof(UInt32);
        XThrowIfError(AudioUnitGetProperty(_rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize), "couldn't get max frames per slice on Apple Voice Processing IO");
        
        // We need references to certain data in the render callback
        // This simple struct is used to hold that information
        
        cd.rioUnit = _rioUnit;
        cd.muteAudio = &_muteAudio;
        cd.audioChainIsBeingReconstructed = &_audioChainIsBeingReconstructed;
        
        // Set the render callback on Apple Voice Processing IO
        AURenderCallbackStruct renderCallback;
        renderCallback.inputProc = performRender;
        renderCallback.inputProcRefCon = NULL;
        XThrowIfError(AudioUnitSetProperty(_rioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, sizeof(renderCallback)), "couldn't set render callback on Apple Voice Processing IO");
        
        // Initialize the Apple Voice Processing IO instance
        XThrowIfError(AudioUnitInitialize(_rioUnit), "couldn't initialize Apple Voice Processing IO instance");
    }
    
    catch (CAXException &e) {
        NSLog(@"Error returned from setupIOUnit: %d: %s", (int)e.mError, e.mOperation);
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupIOUnit");
    }
    
    return;
}

- (void)setupAudioChain
{
    [self setupAudioSession];
    [self setupIOUnit];
}

- (OSStatus)startIOUnit
{
    OSStatus err = AudioOutputUnitStart(_rioUnit);
    if (err) NSLog(@"couldn't start Apple Voice Processing IO: %d", (int)err);
    return err;
}

- (OSStatus)stopIOUnit
{
    OSStatus err = AudioOutputUnitStop(_rioUnit);
    if (err) NSLog(@"couldn't stop Apple Voice Processing IO: %d", (int)err);
    return err;
}

- (BOOL)audioChainIsBeingReconstructed
{
    return _audioChainIsBeingReconstructed;
}

- (void)dealloc
{
    [super dealloc];
}

@end

/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
An AUAudioUnit subclass implementing a simple instrument.
*/

#ifndef InstrumentDemo_h
#define InstrumentDemo_h

#import <AudioToolbox/AudioToolbox.h>

#define FourCCChars(CC) ((int)(CC)>>24)&0xff, ((int)(CC)>>16)&0xff, ((int)(CC)>>8)&0xff, (int)(CC)&0xff

@interface AUv3InstrumentDemo : AUAudioUnit

@end

#endif /* InstrumentDemo_h */

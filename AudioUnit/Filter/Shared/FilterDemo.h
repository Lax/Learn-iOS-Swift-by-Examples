/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
An AUAudioUnit subclass implementing a low-pass filter with resonance. Illustrates parameter management and rendering, including in-place processing and buffer management.
*/

#ifndef FilterDemo_h
#define FilterDemo_h

#import <AudioToolbox/AudioToolbox.h>

@class FilterDemoViewController;

#define FourCCChars(CC) ((int)(CC)>>24)&0xff, ((int)(CC)>>16)&0xff, ((int)(CC)>>8)&0xff, (int)(CC)&0xff

@interface AUv3FilterDemo : AUAudioUnit

@property (weak) FilterDemoViewController* filterDemoViewController;

- (NSArray<NSNumber *> *)magnitudesForFrequencies:(NSArray<NSNumber *> *)frequencies;

@end

#endif /* FilterDemo_h */

/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller for the InstrumentDemo audio unit. Manages the interactions between a InstrumentView and the audio unit's parameters.
*/

#ifndef InstrumentDemoViewController_h
#define InstrumentDemoViewController_h

#import <CoreAudioKit/AUViewController.h>

@class AUv3InstrumentDemo;

@interface InstrumentDemoViewController : AUViewController <AUAudioUnitFactory>

@property (nonatomic)AUv3InstrumentDemo *audioUnit;

@end

#endif /* InstrumentDemoViewController_h */

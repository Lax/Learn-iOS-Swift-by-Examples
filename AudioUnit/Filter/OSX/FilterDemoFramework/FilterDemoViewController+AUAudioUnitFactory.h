/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
'FilterDemoViewController' is the app extension's principal class, responsible for creating both the audio unit and its view.
            The principal class of a UI v3 audio unit extension must derive from AUViewController and implement the AUAudioUnitFactory protocol.
*/

#ifndef FilterDemoViewController_h
#define FilterDemoViewController_h

#import <CoreAudioKit/AUViewController.h>

@class AUv3FilterDemo;

@interface FilterDemoViewController : AUViewController <AUAudioUnitFactory>

@property (nonatomic)AUv3FilterDemo *audioUnit;

// Redirected from AUAudioUnit
- (void)handleSelectViewConfiguration:(AUAudioUnitViewConfiguration *)viewConfiguration;

@end

#endif /* FilterDemoViewController_h */

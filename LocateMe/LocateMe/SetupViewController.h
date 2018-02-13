/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:

Displayed by either a GetLocationViewController or a TrackLocationViewController, this view controller is presented modally and communicates back to the presenting controller using a simple delegate protocol. The protocol sends setupViewController:didFinishSetupWithInfo: to its delegate with a dictionary containing a desired accuracy and either a timeout or a distance filter value. A custom UIPickerView specifies the desired accuracy. A slider is shown for setting the timeout or distance filter. This view controller can be initialized using either of two nib files: GetLocationSetupView.xib or TrackLocationSetupView.xib. These nibs have nearly identical layouts, but differ in the labels and attributes for the slider.

*/

#import <UIKit/UIKit.h>

// Keys for the dictionary provided to the delegate.
extern NSString * const kSetupInfoKeyAccuracy;
extern NSString * const kSetupInfoKeyDistanceFilter;
extern NSString * const kSetupInfoKeyTimeout;

@class SetupViewController;

@protocol SetupViewControllerDelegate <NSObject>
@required
- (void)setupViewController:(SetupViewController *)controller didFinishSetupWithInfo:(NSDictionary *)setupInfo;
@end

#pragma mark -

@interface SetupViewController : UIViewController

@property (nonatomic, unsafe_unretained) id <SetupViewControllerDelegate> delegate;

@end
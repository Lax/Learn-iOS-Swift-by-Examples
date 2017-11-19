/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UIViewController subclasses which handles setup, playback and export of AVMutableComposition along with other user interactions like scrubbing, toggling play/pause, selecting transition type.
 */

#import <UIKit/UIKit.h>
#import "APLTransitionTypeController.h"

@class AVPlayer, AVPlayerItem, APLSimpleEditor, APLPlayerView;

@interface APLViewController : UIViewController <UIGestureRecognizerDelegate, APLTransitionTypePickerDelegate, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate>

@end

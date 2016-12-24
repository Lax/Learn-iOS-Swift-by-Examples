/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View containing an AVPlayerLayer.
*/

@import UIKit;

@class AVPlayer;

@interface AAPLPlayerView : UIView
@property AVPlayer *player;
@property (readonly) AVPlayerLayer *playerLayer;
@end

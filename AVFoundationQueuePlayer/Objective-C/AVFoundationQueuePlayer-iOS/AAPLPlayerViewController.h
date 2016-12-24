/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller containing a player view and basic playback controls.
*/

@import UIKit;


@class AAPLPlayerView;

@interface AAPLPlayerViewController : UIViewController

@property (readonly) AVQueuePlayer *player;

/*
    @{
        NSURL(asset URL) : @{
            NSString(title) : NSString,
            NSString(thumbnail) : UIImage
        }
    }
*/
@property NSMutableDictionary *loadedAssets;

@property CMTime currentTime;
@property (readonly) CMTime duration;
@property float rate;

@end

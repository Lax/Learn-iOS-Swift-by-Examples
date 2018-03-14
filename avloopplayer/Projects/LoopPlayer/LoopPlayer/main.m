/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Command line tool for playing audiovisual media in a loop.
 */

@import Foundation;
@import AVFoundation;
@import CoreMedia;

static void* const AVLoopPlayerQueuePlayerStatusObservationContext = (void*)&AVLoopPlayerQueuePlayerStatusObservationContext;
static void* const AVLoopPlayerCurrentItemObservationContext = (void*)&AVLoopPlayerCurrentItemObservationContext;
static void* const AVLoopPlayerCurrentItemStatusObservationContext = (void*)&AVLoopPlayerCurrentItemStatusObservationContext;

@interface AVLoopPlayer : NSObject
{
@private
	AVQueuePlayer *_queuePlayer;
	BOOL _addedObservers;
}

- (void)playbackInLoopWithURL:(NSURL *)URL;
- (void)stopPlayback;

@end

@implementation AVLoopPlayer

- (id)init
{
	self = [super init];
	if (self)
	{
		_queuePlayer = [[AVQueuePlayer alloc] init];
	}
	
	return self;
}

- (void)startObservingPlayerAndItem
{
	if (_addedObservers == NO)
	{
		[_queuePlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:AVLoopPlayerQueuePlayerStatusObservationContext];
		[_queuePlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionOld context:AVLoopPlayerCurrentItemObservationContext];
		[_queuePlayer addObserver:self forKeyPath:@"currentItem.status" options:NSKeyValueObservingOptionNew context:AVLoopPlayerCurrentItemStatusObservationContext];
		_addedObservers = YES;
	}
}

- (void)stopObservingPlayerAndItem
{
	if (_addedObservers)
	{
		[_queuePlayer removeObserver:self forKeyPath:@"status" context:AVLoopPlayerQueuePlayerStatusObservationContext];
		[_queuePlayer removeObserver:self forKeyPath:@"currentItem" context:AVLoopPlayerCurrentItemObservationContext];
		[_queuePlayer removeObserver:self forKeyPath:@"currentItem.status" context:AVLoopPlayerCurrentItemStatusObservationContext];
		_addedObservers = NO;
	}
}

- (void)playbackInLoopWithURL:(NSURL *)URL
{
	AVURLAsset *asset = [AVURLAsset assetWithURL:URL];
	
	[asset loadValuesAsynchronouslyForKeys:@[@"duration", @"playable"] completionHandler:^{
        /*
         The asset invokes its completion handler on an arbitrary queue when 
         loading is complete. Because we want to access our AVQueuePlayer in our 
         ensuing set-up, we must dispatch our handler to the main queue.
         */
		dispatch_async(dispatch_get_main_queue(), ^{
			NSError *durationError, *playableError;
			/* 
             Check to make sure duration and playable properties are loaded 
             before accessing them.
             */
			AVKeyValueStatus durationStatus = [asset statusOfValueForKey:@"duration" error:&durationError];
			AVKeyValueStatus playableStatus = [asset statusOfValueForKey:@"playable" error:&playableError];

			if (durationStatus == AVKeyValueStatusLoaded && playableStatus == AVKeyValueStatusLoaded )
			{
				if (CMTIME_COMPARE_INLINE([asset duration], >=, CMTimeMake(1,100)) && [asset isPlayable])
				{
                    /*
                     Based on the duration of the asset, we decide the number of 
                     player items to add to demonstrate gapless playback of the 
                     same asset.
                     */
					NSUInteger countOfPlayerItems = (1.0 / CMTimeGetSeconds([asset duration])) + 2;
					for (NSUInteger idx = 0; idx < countOfPlayerItems; ++idx)
					{
						AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
						if (playerItem)
						{
							[_queuePlayer insertItem:playerItem afterItem:nil];
						}
					}
					
					[self startObservingPlayerAndItem];
					[_queuePlayer play];
				}
				else
				{
					NSLog(@"Can't loop. Asset duration too short(%1.3f sec) or not playable(isPlayable: %s)",
							CMTimeGetSeconds([asset duration]), ([asset isPlayable]?"YES":"NO"));
				}
			}
			else
			{
				if (durationStatus == AVKeyValueStatusFailed)
					NSLog(@"Failed to load duration property for asset: %@ with error: %@", asset, durationError);

				if (playableStatus == AVKeyValueStatusFailed)
					NSLog(@"Failed to load playable property for asset: %@ with error: %@", asset, playableError);
			}
		});
	}];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)changeDictionary context:(void *)context
{
	if (context == AVLoopPlayerQueuePlayerStatusObservationContext)
	{
		AVPlayerStatus newPlayerStatus = (AVPlayerStatus)[[changeDictionary objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
        if (newPlayerStatus == AVPlayerStatusFailed) {
			AVQueuePlayer *player = (AVQueuePlayer *)object;
			NSLog(@"End looping since player has failed with error %@", player.error);
			[self stopPlayback];
        }

	}
	else if (context == AVLoopPlayerCurrentItemObservationContext)
	{
		AVQueuePlayer *player = (AVQueuePlayer *)object;
		
		if ([[player items] count] == 0)
		{
			NSLog(@"Play queue emptied out due to bad player item. End looping.");
			[self stopPlayback];
		}
		else
		{
			// Append the previous current item to the player's queue.
			AVPlayerItem *itemRemoved = changeDictionary[NSKeyValueChangeOldKey];
			
            /*
             An initial change from a nil currentItem yields NSNull here. Check 
             to make sure the class is AVPlayerItem before appending it to the 
             end of the queue.
             */
			if ([itemRemoved isKindOfClass:[AVPlayerItem class]])
			{
				[itemRemoved seekToTime:kCMTimeZero];
				[self stopObservingPlayerAndItem];
				[player insertItem:itemRemoved afterItem:nil];
				[self startObservingPlayerAndItem];
			}
		}
	}
	else if (context == AVLoopPlayerCurrentItemStatusObservationContext)
	{
		AVPlayerItemStatus newItemStatus = (AVPlayerItemStatus)[[changeDictionary objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
        if (newItemStatus == AVPlayerItemStatusFailed) {
			AVQueuePlayer *player = (AVQueuePlayer *)object;
			NSLog(@"End looping since player item has failed with error %@", player.currentItem.error);
			[self stopPlayback];
        }
	}
}

- (void)stopPlayback
{
	[_queuePlayer pause];
	[self stopObservingPlayerAndItem];
	[_queuePlayer removeAllItems];
}

@end

int main(int argc, const char * argv[])
{
	@autoreleasepool
	{
		if (argc != 2)
		{
			NSLog(@"Usage: %s <path-to-movie>",argv[0]);
			return 1;
		}
		
		NSString *filePath = [[NSString alloc] initWithUTF8String:argv[1]];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		AVLoopPlayer *player = [[AVLoopPlayer alloc] init];
		[player playbackInLoopWithURL:fileURL];
		
		// Play for at least 3 seconds.
		NSDate *timeOut = [NSDate dateWithTimeIntervalSinceNow:3.0];
		[[NSRunLoop mainRunLoop] runUntilDate:timeOut];
		
		[player stopPlayback];
		
		return 0;
	}
	return 0;
}

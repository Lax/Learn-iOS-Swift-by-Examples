/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View controller containing a player view and basic playback controls.
*/


@import Foundation;
@import AVFoundation;
@import CoreMedia.CMTime;
#import "AAPLPlayerViewController.h"
#import "AAPLPlayerView.h"
#import "AAPLQueuedItemCollectionViewCell.h"


// Private properties
@interface AAPLPlayerViewController ()
{
    AVQueuePlayer *_player;
    AVURLAsset *_asset;

    /*
        A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
        method.
    */
    id<NSObject> _timeObserverToken;
    AVPlayerItem *_playerItem;
}

@property (readonly) AVPlayerLayer *playerLayer;

@property NSMutableDictionary *assetTitlesAndThumbnailsByURL;

// Formatter to provide formatted value for seconds displayed in `startTimeLabel` and `durationLabel`.
@property (readonly) NSDateComponentsFormatter *timeRemainingFormatter;

@property (weak) IBOutlet UISlider *timeSlider;
@property (weak) IBOutlet UILabel *startTimeLabel;
@property (weak) IBOutlet UILabel *durationLabel;
@property (weak) IBOutlet UIButton *rewindButton;
@property (weak) IBOutlet UIButton *playPauseButton;
@property (weak) IBOutlet UIButton *fastForwardButton;
@property (weak) IBOutlet UIButton *clearButton;
@property (weak) IBOutlet UICollectionView *collectionView;
@property (weak) IBOutlet UILabel *queueLabel;
@property (weak) IBOutlet AAPLPlayerView *playerView;

@end

@implementation AAPLPlayerViewController

// MARK: - View Controller

/*
	KVO context used to differentiate KVO callbacks for this class versus other
	classes in its class hierarchy.
*/
static int AAPLPlayerViewControllerKVOContext = 0;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    /*
        Update the UI when these player properties change.
    
        Use the context parameter to distinguish KVO for our particular observers and not
        those destined for a subclass that also happens to be observing these properties.
    */
    [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];
    [self addObserver:self forKeyPath:@"player.currentItem" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&AAPLPlayerViewControllerKVOContext];

    self.playerView.playerLayer.player = self.player;

    /*
        Read the list of assets we'll be using from a JSON file.
    */
    [self asynchronouslyLoadURLAssetsWithManifestURL:[[NSBundle mainBundle] URLForResource:@"MediaManifest" withExtension:@"json"]];

    // Use a weak self variable to avoid a retain cycle in the block.
    AAPLPlayerViewController __weak *weakSelf = self;
    _timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double timeElapsed = CMTimeGetSeconds(time);
        
        weakSelf.timeSlider.value = timeElapsed;
        weakSelf.startTimeLabel.text = [weakSelf createTimeString: timeElapsed];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if (_timeObserverToken) {
        [self.player removeTimeObserver:_timeObserverToken];
        _timeObserverToken = nil;
    }

    [self.player pause];

    [self removeObserver:self forKeyPath:@"player.currentItem.duration" context:&AAPLPlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.rate" context:&AAPLPlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:&AAPLPlayerViewControllerKVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem" context:&AAPLPlayerViewControllerKVOContext];
}


// MARK: - Properties

// Will attempt load and test these asset keys before playing
+ (NSArray *)assetKeysRequiredToPlay {
    return @[@"playable", @"hasProtectedContent"];
}

- (AVQueuePlayer *)player {
    if (!_player) {
        _player = [[AVQueuePlayer alloc] init];
    }
    return _player;
}

- (CMTime)currentTime {
    return self.player.currentTime;
}

- (void)setCurrentTime:(CMTime)newCurrentTime {
    [self.player seekToTime:newCurrentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (CMTime)duration {
    return self.player.currentItem ? self.player.currentItem.duration : kCMTimeZero;
}

- (float)rate {
    return self.player.rate;
}

- (void)setRate:(float)newRate {
    self.player.rate = newRate;
}

- (AVPlayerLayer *)playerLayer {
    return self.playerView.playerLayer;
}

- (NSDateComponentsFormatter *)timeRemainingFormatter {
    NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
    formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    
    return formatter;
}

// MARK: - Asset Loading

/*
    Prepare an AVAsset for use on a background thread. When the minimum set 
    of properties we require (`assetKeysRequiredToPlay`) are loaded then add
    the asset to the `assetTitlesAndThumbnails` dictionary. We'll use that 
    dictionary to populate the "Add Item" button popover.
*/
- (void)asynchronouslyLoadURLAsset:(AVURLAsset *)asset title:(NSString *)title thumbnailResourceName:(NSString *)thumbnailResourceName {

    /*
        Using AVAsset now runs the risk of blocking the current thread (the
        main UI thread) whilst I/O happens to populate the properties. It's 
        prudent to defer our work until the properties we need have been loaded.
    */
    [asset loadValuesAsynchronouslyForKeys:AAPLPlayerViewController.assetKeysRequiredToPlay completionHandler:^{

        /*
            The asset invokes its completion handler on an arbitrary queue.
            To avoid multiple threads using our internal state at the same time
            we'll elect to use the main thread at all times, let's dispatch
            our handler to the main queue.
        */
        dispatch_async(dispatch_get_main_queue(), ^{
            
            /*
                This method is called when the `AVAsset` for our URL has 
                completed the loading of the values of the specified array 
                of keys.
            */
            
            /*
                Test whether the values of each of the keys we need have been
                successfully loaded.
            */
            for (NSString *key in self.class.assetKeysRequiredToPlay) {
                NSError *error = nil;
                if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                    NSString *stringFormat = NSLocalizedString(@"error.asset_%@_key_%@_failed.description", @"Can't use this AVAsset because one of it's keys failed to load");

                    NSString *message = [NSString localizedStringWithFormat:stringFormat, title, key];

                    [self handleErrorWithMessage:message error:error];

                    return;
                }
            }

            // We can't play this asset.
            if (!asset.playable || asset.hasProtectedContent) {
                NSString *stringFormat = NSLocalizedString(@"error.asset_%@_not_playable.description", @"Can't use this AVAsset because it isn't playable or has protected content");

                NSString *message = [NSString localizedStringWithFormat:stringFormat, title];

                [self handleErrorWithMessage:message error:nil];

                return;
            }

            /*
                We can play this asset. Create a new AVPlayerItem and make it
                our player's current item.
            */
            if (!self.loadedAssets)
                self.loadedAssets = [NSMutableDictionary dictionary];
            self.loadedAssets[title] = asset;

            NSString *path = [[NSBundle mainBundle] pathForResource:[thumbnailResourceName stringByDeletingPathExtension] ofType:[thumbnailResourceName pathExtension]];
            UIImage *thumbnail = [[UIImage alloc] initWithContentsOfFile:path];
            if (!self.assetTitlesAndThumbnailsByURL) {
                self.assetTitlesAndThumbnailsByURL = [NSMutableDictionary dictionary];
            }
            self.assetTitlesAndThumbnailsByURL[asset.URL] = @{ @"title" : title, @"thumbnail" : thumbnail };
        });
    }];
}

/*
    Read the asset URLs, titles and thumbnail resource names from a JSON manifest
    file - then load each asset.
*/
- (void)asynchronouslyLoadURLAssetsWithManifestURL:(NSURL *)jsonURL
{
    NSArray *assetsArray = nil;

    NSData *jsonData = [[NSData alloc] initWithContentsOfURL:jsonURL];
    if (jsonData) {
        assetsArray = (NSArray *)[NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        if (!assetsArray) {
            [self handleErrorWithMessage:NSLocalizedString(@"error.json_parse_failed.description", @"Failed to parse the assets manifest JSON") error:nil];
        }
    }
    else {
        [self handleErrorWithMessage:NSLocalizedString(@"error.json_open_failed.description", @"Failed to open the assets manifest JSON") error:nil];
    }
    
    for (NSDictionary *assetDict in assetsArray) {
    
        NSURL *mediaURL = nil;
        NSString *optionalResourceName = assetDict[@"mediaResourceName"];
        NSString *optionalURLString = assetDict[@"mediaURL"];
        if (optionalResourceName) {
            mediaURL = [[NSBundle mainBundle] URLForResource:[optionalResourceName stringByDeletingPathExtension] withExtension:optionalResourceName.pathExtension];
        }
        else if (optionalURLString) {
            mediaURL = [NSURL URLWithString:optionalURLString];
        }

        [self asynchronouslyLoadURLAsset:[AVURLAsset URLAssetWithURL:mediaURL options:nil]
                                   title:assetDict[@"title"]
                   thumbnailResourceName:assetDict[@"thumbnailResourceName"]];
    }
}

// MARK: - IBActions

- (IBAction)playPauseButtonWasPressed:(UIButton *)sender {
    if (self.player.rate != 1.0) {
        // Not playing foward; so play.
        if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.duration)) {
            // At end; so got back to beginning.
            self.currentTime = kCMTimeZero;
        }
        [self.player play];
    } else {
        // Playing; so pause.
        [self.player pause];
    }
}

- (IBAction)rewindButtonWasPressed:(UIButton *)sender {
    self.rate = MAX(self.player.rate - 2.0, -2.0); // rewind no faster than -2.0
}

- (IBAction)fastForwardButtonWasPressed:(UIButton *)sender {
    self.rate = MIN(self.player.rate + 2.0, 2.0); // fast forward no faster than 2.0
}

- (IBAction)timeSliderDidChange:(UISlider *)sender {
    self.currentTime = CMTimeMakeWithSeconds(sender.value, 1000);
}

- (void)presentModalPopoverAlertController:(UIAlertController *)alertController sender:(UIButton *)sender {
    alertController.modalPresentationStyle = UIModalPresentationPopover;

    alertController.popoverPresentationController.sourceView = sender;
    alertController.popoverPresentationController.sourceRect = sender.bounds;
    alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;

    [self presentViewController:alertController animated:true completion:nil];
}

- (IBAction)addItemToQueueButtonPressed:(UIButton *)sender {

    NSString *alertTitle = NSLocalizedString(@"popover.title.addItem", @"Title of popover that adds items to the queue");
    NSString *alertMessage = NSLocalizedString(@"popover.message.addItem", @"Message on popover that adds items to the queue");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Populate the sheet with the titles of the assets we have loaded.
    for (NSString *loadedAssetTitle in self.loadedAssets.allKeys) {
        AVAsset *loadedAsset = self.loadedAssets[loadedAssetTitle];
        AAPLPlayerViewController __weak *weakSelf = self;
        [alertController addAction:[UIAlertAction actionWithTitle:loadedAssetTitle style:UIAlertActionStyleDefault handler:
            ^(UIAlertAction *action){
                NSArray *oldItemsArray = [weakSelf.player items];
                AVPlayerItem *newPlayerItem = [AVPlayerItem playerItemWithAsset:loadedAsset];
                [weakSelf.player insertItem:newPlayerItem afterItem:nil];
                [weakSelf queueDidChangeFromArray:oldItemsArray toArray:[self.player items]];
            }]];
    }

    NSString *cancelActionTitle = NSLocalizedString(@"popover.title.cancel", @"Title of popover cancel action");
    [alertController addAction:[UIAlertAction actionWithTitle:cancelActionTitle style:UIAlertActionStyleCancel handler:nil]];

    [self presentModalPopoverAlertController:alertController sender:sender];
}

- (IBAction)clearQueueButtonWasPressed:(UIButton *)sender {

    NSString *alertTitle = NSLocalizedString(@"popover.title.clear", @"Title of popover that clears the queue");
    NSString *alertMessage = NSLocalizedString(@"popover.message.clear", @"Message on popover that clears the queue");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleActionSheet];

    AAPLPlayerViewController __weak *weakSelf = self;
    [alertController addAction:[UIAlertAction actionWithTitle:@"Clear Queue" style:UIAlertActionStyleDestructive handler:
        ^(UIAlertAction *action){
            NSArray *oldItemsArray = [weakSelf.player items];
            [weakSelf.player removeAllItems];
            [weakSelf queueDidChangeFromArray:oldItemsArray toArray:[self.player items]];
        }]];

    NSString *cancelActionTitle = NSLocalizedString(@"popover.title.cancel", @"Title of popover cancel action");
    [alertController addAction:[UIAlertAction actionWithTitle:cancelActionTitle style:UIAlertActionStyleCancel handler:nil]];

    [self presentModalPopoverAlertController:alertController sender:sender];
}

// MARK: - KV Observation

// Update our UI when player or player.currentItem changes
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if (context != &AAPLPlayerViewControllerKVOContext) {
        // KVO isn't for us.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([keyPath isEqualToString:@"player.currentItem"]) {
        [self queueDidChangeFromArray:nil toArray:[self.player items]];

    }
    else if ([keyPath isEqualToString:@"player.currentItem.duration"]) {
        // Update timeSlider and enable/disable controls when duration > 0.0

        // Handle NSNull value for NSKeyValueChangeNewKey, i.e. when player.currentItem is nil
        NSValue *newDurationAsValue = change[NSKeyValueChangeNewKey];
        CMTime newDuration = [newDurationAsValue isKindOfClass:[NSValue class]] ? newDurationAsValue.CMTimeValue : kCMTimeZero;
        BOOL hasValidDuration = CMTIME_IS_NUMERIC(newDuration) && newDuration.value != 0;
        double currentTime = hasValidDuration ? CMTimeGetSeconds(self.currentTime) : 0.0;
        double newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0;

        self.timeSlider.maximumValue = newDurationSeconds;
        self.timeSlider.value = currentTime;
        self.rewindButton.enabled = hasValidDuration;
        self.playPauseButton.enabled = hasValidDuration;
        self.fastForwardButton.enabled = hasValidDuration;
        self.timeSlider.enabled = hasValidDuration;
        self.startTimeLabel.enabled = hasValidDuration;
        self.startTimeLabel.text = [self createTimeString:currentTime];
        self.durationLabel.enabled = hasValidDuration;
        self.durationLabel.text = [self createTimeString:newDurationSeconds];
    }
    else if ([keyPath isEqualToString:@"player.rate"]) {
        // Update playPauseButton image

        double newRate = [change[NSKeyValueChangeNewKey] doubleValue];
        UIImage *buttonImage = (newRate == 1.0) ? [UIImage imageNamed:@"PauseButton"] : [UIImage imageNamed:@"PlayButton"];
        [self.playPauseButton setImage:buttonImage forState:UIControlStateNormal];

    }
    else if ([keyPath isEqualToString:@"player.currentItem.status"]) {
        // Display an error if status becomes Failed

        // Handle NSNull value for NSKeyValueChangeNewKey, i.e. when player.currentItem is nil
        NSNumber *newStatusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus newStatus = [newStatusAsNumber isKindOfClass:[NSNumber class]] ? newStatusAsNumber.integerValue : AVPlayerItemStatusUnknown;
        
        if (newStatus == AVPlayerItemStatusFailed) {
            [self handleErrorWithMessage:self.player.currentItem.error.localizedDescription error:self.player.currentItem.error];
        }

    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// Trigger KVO for anyone observing our properties affected by player and player.currentItem
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"duration"]) {
        return [NSSet setWithArray:@[ @"player.currentItem.duration" ]];
    } else if ([key isEqualToString:@"currentTime"]) {
        return [NSSet setWithArray:@[ @"player.currentItem.currentTime" ]];
    } else if ([key isEqualToString:@"rate"]) {
        return [NSSet setWithArray:@[ @"player.rate" ]];
    } else {
        return [super keyPathsForValuesAffectingValueForKey:key];
    }
}

// player.items is not KV observable so we need to call this function every time the queue changes
- (void)queueDidChangeFromArray:(NSArray *)oldPlayerItems toArray:(NSArray *)newPlayerItems {

    if (newPlayerItems.count == 0) {
        self.queueLabel.text = NSLocalizedString(@"label.queue.empty", @"Queue is empty");
    }
    else {
        NSString *stringFormat = NSLocalizedString(@"label.queue.%lu items", @"Queue of n item(s)");

        self.queueLabel.text = [NSString localizedStringWithFormat:stringFormat, newPlayerItems.count];
    }
    
    BOOL isQueueEmpty = newPlayerItems.count == 0;
    self.clearButton.enabled = !isQueueEmpty;

    [self.collectionView reloadData];
}

// MARK: - Error Handling

- (void)handleErrorWithMessage:(NSString *)message error:(NSError *)error {
    NSLog(@"Error occurred with message: %@, error: %@.", message, error);

    NSString *alertTitle = NSLocalizedString(@"alert.error.title", @"Alert title for errors");
    NSString *defaultAlertMessage = NSLocalizedString(@"error.default.description", @"Default error message when no NSError provided");
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:alertTitle message:message ?: defaultAlertMessage  preferredStyle:UIAlertControllerStyleAlert];

    NSString *alertActionTitle = NSLocalizedString(@"alert.error.actions.OK", @"OK on error alert");
    UIAlertAction *action = [UIAlertAction actionWithTitle:alertActionTitle style:UIAlertActionStyleDefault handler:nil];
    [controller addAction:action];

    [self presentViewController:controller animated:YES completion:nil];
}

// MARK: UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.player items].count;
}

- (NSDictionary *)titleAndThumbnailForPlayerItemAtIndexPath:(NSIndexPath *)indexPath {
    AVPlayerItem *item = [self.player items][[indexPath indexAtPosition:1]];
    return self.assetTitlesAndThumbnailsByURL[[(AVURLAsset *)item.asset URL]];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    AAPLQueuedItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemCell" forIndexPath:indexPath];

    NSDictionary *titleAndThumbnail = [self titleAndThumbnailForPlayerItemAtIndexPath:indexPath];
    cell.label.text = titleAndThumbnail[@"title"];
    cell.backgroundView = [[UIImageView alloc] initWithImage:titleAndThumbnail[@"thumbnail"]];

    return cell;
}

// MARK: Convenience

- (NSString *)createTimeString:(double)time {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.second = (NSInteger)fmax(0.0, time);
    
    return [self.timeRemainingFormatter stringFromDateComponents:components];
}

@end

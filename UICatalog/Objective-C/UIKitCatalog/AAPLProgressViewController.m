/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UIProgressView.
*/

#import "AAPLProgressViewController.h"

/*!
    The KVO context for `ProgressViewController` instances. This provides a stable
    address to use as the `context` parameter for KVO observation methods.
 */
static void *AAPLProgressViewControllerContext = &AAPLProgressViewControllerContext;

@interface AAPLProgressViewController()

@property (nonatomic, weak) IBOutlet UIProgressView *defaultStyleProgressView;
@property (nonatomic, weak) IBOutlet UIProgressView *barStyleProgressView;
@property (nonatomic, weak) IBOutlet UIProgressView *tintedProgressView;
@property (nonatomic, strong) IBOutletCollection(UIProgressView) NSArray *progressViews;

/*!
    An `NSProgress` object who's `fractionCompleted` is observed using KVO to
    update the `UIProgressView`s' `progress` properties.
 */
@property (nonatomic, strong) NSProgress *progress;

/*!
    A repeating timer that, when fired, updates the `NSProgress` object's
    `completedUnitCount` property.
 */
@property (nonatomic, strong) NSTimer *updateTimer;

@end


#pragma mark -

@implementation AAPLProgressViewController

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self != nil) {
        self.progress = [NSProgress  progressWithTotalUnitCount:10];
        [self.progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:AAPLProgressViewControllerContext];
    }
    
    return self;
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:@"fractionCompleted"];
}

#pragma mark - Configuration

- (void)configureDefaultStyleProgressView {
    self.defaultStyleProgressView.progressViewStyle = UIProgressViewStyleDefault;
}

- (void)configureBarStyleProgressView {
    self.barStyleProgressView.progressViewStyle = UIProgressViewStyleBar;
}

- (void)configureTintedProgressView {
    self.tintedProgressView.progressViewStyle = UIProgressViewStyleDefault;

    self.tintedProgressView.trackTintColor = [UIColor aapl_applicationBlueColor];
    self.tintedProgressView.progressTintColor = [UIColor aapl_applicationPurpleColor];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultStyleProgressView];
    [self configureBarStyleProgressView];
    [self configureTintedProgressView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Reset the completed progress of the `UIProgressView`s.
    for (UIProgressView *progressView in self.progressViews) {
        [progressView setProgress:0.0 animated:NO];
    }
    
    /*
        Reset the `completedUnitCount` of the `NSProgress` object and create
        a repeating timer to increment it over time.
     */
    self.progress.completedUnitCount = 0;
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerDidFire) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // Stop the timer from firing.
    [self.updateTimer invalidate];
}

#pragma mark - Key Value Observing (KVO)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // Check if this is the KVO notification for our `NSProgress` object.
    if (context == AAPLProgressViewControllerContext && object == self.progress && [keyPath isEqualToString:@"fractionCompleted"]) {
        // Update the progress views.
        for (UIProgressView *progressView in self.progressViews) {
            [progressView setProgress:self.progress.fractionCompleted animated:YES];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Convenience

- (void)timerDidFire {
    /*
        Update the `completedUnitCount` of the `NSProgress` object if it's
        not completed. Otherwise, stop the timer.
     */
    if (self.progress.completedUnitCount < self.progress.totalUnitCount) {
        self.progress.completedUnitCount += 1;
    }
    else {
        [self.updateTimer invalidate];
    }
}

@end

/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller for the FilterDemo audio unit. Manages the interactions between a FilterView and the audio unit's parameters.
*/

#import <Cocoa/Cocoa.h>
#import <FilterDemoFramework/FilterDemo.h>
#import "FilterDemoViewController+AUAudioUnitFactory.h"
#import "FilterDemoViewController_Internal.h"
#import "FilterView.h"

@interface FilterDemoViewController () {

    // These are moved in and out of the container view, so we want to hold on to them
    __strong IBOutlet NSView* smallView;
    __strong IBOutlet NSView* largeView;

    __weak IBOutlet FilterView  *filterView;
    __weak IBOutlet NSTextField *frequencyLabel;
    __weak IBOutlet NSTextField *resonanceLabel;

    __weak IBOutlet NSTextField *frequencyLabelSmallView;
    __weak IBOutlet NSTextField *resonanceLabelSmallView;

    bool smallViewActive;
    AUParameter *cutoffParameter;
    AUParameter *resonanceParameter;
    AUParameterObserverToken parameterObserverToken;
}

-(IBAction) setCutoff:(id)sender;
-(IBAction) setResonance:(id)sender;
@end

@implementation FilterDemoViewController

#pragma mark <AUAudioUnitFactory>

/* 
 The principal class of a UI v3 audio unit extension must derive from AUViewController and implement the AUAudioUnitFactory protocol.
 
 - createAudioUnitWithComponentDescription:error: should create and return an instance of its audio unit.
 
 This method will be called only once per instance of the factory.
 
 Note that in non-ARC code, "create" methods return unretained objects (unlike "create" C functions); the implementor should return an object with reference count 1 but autoreleased.
*/

- (AUv3FilterDemo *)createAudioUnitWithComponentDescription:(AudioComponentDescription)desc
                                                      error:(NSError **)error {
    self.audioUnit = [[AUv3FilterDemo alloc] initWithComponentDescription:desc error:error];
    return self.audioUnit;
}

#pragma mark-
#pragma mark: AUViewController

- (id)init {
    self = [super initWithNibName:@"FilterDemoViewController"
                           bundle:[NSBundle bundleForClass:NSClassFromString(@"FilterDemoViewController")]];
    return self;
}

- (void)dealloc {
    filterView.delegate = nil;
    [self disconnectViewWithAU];
    NSLog(@"FilterDemoViewController Dealloc\n");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    filterView.delegate = self;

    if (_audioUnit) {
        [self connectViewWithAU];
        _audioUnit.filterDemoViewController = self;
    }

    // We will set our constraints manually
    smallView.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    largeView.translatesAutoresizingMaskIntoConstraints = NO;

    smallViewActive = false;
}

#pragma mark-

- (AUv3FilterDemo *)getAudioUnit {
    return _audioUnit;
}

- (void)setAudioUnit:(AUv3FilterDemo *)audioUnit {
    _audioUnit = audioUnit;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isViewLoaded]) {
            [self connectViewWithAU];
            _audioUnit.filterDemoViewController = self;
        }
    });
}

#pragma mark-

/*
 The "allParameterValues" pseudo-property is used to issue KVO notifications in response to certain events where potentially all parameter values are invalidated. This includes changes to currentPreset, fullState, and fullStateForDocument.
*/
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void *)context {
    
    NSLog(@"FilterDemoViewControler allParameterValues key path changed: %s\n", keyPath.UTF8String);

    dispatch_async(dispatch_get_main_queue(), ^{
        
        filterView.frequency = cutoffParameter.value;
        filterView.resonance = resonanceParameter.value;
        
        [self updateLabelsWithFrequency:[cutoffParameter stringFromValue: nil] resonance:[resonanceParameter stringFromValue: nil]];
        [self updateFilterViewFrequencyAndMagnitudes];
    });
}

#pragma mark-

- (void)updateLabelsWithFrequency:(NSString *)frequencyString resonance:(NSString *)resonanceString {
    if (frequencyString) {
        frequencyLabel.stringValue = frequencyString;
        frequencyLabelSmallView.stringValue = frequencyString;
    }

    if (resonanceString) {
        resonanceLabel.stringValue = resonanceString;
        resonanceLabelSmallView.stringValue = resonanceString;
    }
}

- (void)connectViewWithAU {
    AUParameterTree *paramTree = _audioUnit.parameterTree;
    
    if (paramTree) {
        cutoffParameter = [paramTree valueForKey: @"cutoff"];
        resonanceParameter = [paramTree valueForKey: @"resonance"];
        
        // prevent retain cycle in parameter observer
        __weak FilterDemoViewController *weakSelf = self;
        __weak AUParameter *weakCutoffParameter = cutoffParameter;
        __weak AUParameter *weakResonanceParameter = resonanceParameter;
        parameterObserverToken = [paramTree tokenByAddingParameterObserver:^(AUParameterAddress address, AUValue value) {
            __strong FilterDemoViewController *strongSelf = weakSelf;
            __strong AUParameter *strongCutoffParameter = weakCutoffParameter;
            __strong AUParameter *strongResonanceParameter = weakResonanceParameter;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (address == strongCutoffParameter.address){
                    strongSelf->filterView.frequency = value;
                    [strongSelf updateLabelsWithFrequency:[strongCutoffParameter stringFromValue: nil] resonance:nil];

                } else if (address == strongResonanceParameter.address) {
                    strongSelf->filterView.resonance = value;
                    [strongSelf updateLabelsWithFrequency:nil resonance:[strongResonanceParameter stringFromValue: nil]];
                }
                
                [strongSelf updateFilterViewFrequencyAndMagnitudes];
            });
        }];
        
        filterView.frequency = cutoffParameter.value;
        filterView.resonance = resonanceParameter.value;

        [self updateLabelsWithFrequency:[cutoffParameter stringFromValue: nil] resonance:[resonanceParameter stringFromValue: nil]];

        [_audioUnit addObserver:self forKeyPath:@"allParameterValues"
                            options:NSKeyValueObservingOptionNew
                            context:parameterObserverToken];

        // Initial drawing of the graph
        [self updateFilterViewFrequencyAndMagnitudes];
    } else {
        NSLog(@"paramTree is NULL!\n");
    }
}

- (void)disconnectViewWithAU {
    if (parameterObserverToken) {
        [_audioUnit.parameterTree removeParameterObserver:parameterObserverToken];
        [_audioUnit removeObserver:self forKeyPath:@"allParameterValues" context:parameterObserverToken];
        parameterObserverToken = 0;
    }
}

#pragma mark -

- (void)updateFilterViewFrequencyAndMagnitudes {
    if (!_audioUnit) return;
    
    NSArray *frequencies = [filterView frequencyDataForDrawing];
    NSArray *magnitudes  = [_audioUnit magnitudesForFrequencies:frequencies];
    
    [filterView setMagnitudes: magnitudes];
}

#pragma mark -
#pragma mark: <FilterViewDelegate>

- (void)filterViewDidChange:(FilterView *)sender frequency:(double)frequency {
    cutoffParameter.value = frequency;

    [self updateFilterViewFrequencyAndMagnitudes];
}

- (void)filterViewDidChange:(FilterView *)sender resonance:(double)resonance {
    resonanceParameter.value = resonance;

    [self updateFilterViewFrequencyAndMagnitudes];
}

- (void)filterViewDataDidChange:(FilterView *)sender {
    [self updateFilterViewFrequencyAndMagnitudes];
}

#pragma mark: Actions

- (IBAction)setCutoff:(id)sender {
    if (sender == frequencyLabel)
        cutoffParameter.value = frequencyLabel.floatValue;

    if (sender == frequencyLabelSmallView)
        cutoffParameter.value = frequencyLabelSmallView.floatValue;

    [self updateFilterViewFrequencyAndMagnitudes];
}

- (IBAction)setResonance:(id)sender {
    if (sender == resonanceLabel)
        resonanceParameter.value = resonanceLabel.floatValue;

    if (sender == resonanceLabelSmallView)
        resonanceParameter.value = resonanceLabelSmallView.floatValue;

    [self updateFilterViewFrequencyAndMagnitudes];
}

#pragma mark: React to host calls via AUAudioUnit

- (void)handleSelectViewConfiguration:(AUAudioUnitViewConfiguration *)viewConfiguration
{
    if (viewConfiguration.width == 400 && viewConfiguration.height == 100) {
        // small view requested
        if (smallViewActive)
        {
            return; // already active, nothing to do
        }
    } else {
       // large view requested
       if (!smallViewActive)
       {
           return; // already active, nothing to do
       }
    }

    NSView *viewToAdd = smallViewActive ? largeView : smallView;
    NSView *currentView = smallViewActive ? smallView : largeView;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.hidden = YES;

        [currentView removeFromSuperview];
        [self.view addSubview:viewToAdd];

        NSDictionary *views = NSDictionaryOfVariableBindings(viewToAdd);

        if (viewToAdd == largeView) {
            // Add constraints to fill out container completely with no padding
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[viewToAdd(>=500)]-0-|" options:0 metrics:nil views:views]];
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[viewToAdd(>=800)]-0-|" options:0 metrics:nil views:views]];
        } else {
            // Tha smallview should stay on top, and the margin should expand
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[viewToAdd(>=100)]-|" options:0 metrics:nil views:views]];
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[viewToAdd(>=400)]-|" options:0 metrics:nil views:views]];
        }

        self.view.hidden = NO;
    });

    smallViewActive = !smallViewActive;
}

@end

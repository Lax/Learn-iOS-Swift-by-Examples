/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller which registers an AUAudioUnit subclass in-process for easy development, connects sliders and text fields to its parameters, and embeds the audio unit's view into a subview. Uses SimplePlayEngine to audition the effect.
*/

#import "ViewController.h"
#import "AppDelegate.h"
#import "FilterDemoFramework.h"
#import "FilterDemo-Swift.h"
#import <CoreAudioKit/AUViewController.h>
#import <CoreGraphics/CGBase.h>
#import "FilterDemoViewController+AUAudioUnitFactory.h"

#define kMinHertz 12.0f
#define kMaxHertz 20000.0f

@interface ViewController () {
    IBOutlet NSButton *playButton;
    IBOutlet NSButton *toggleViewsButton;
    
    IBOutlet NSSlider *cutoffSlider;
    IBOutlet NSSlider *resonanceSlider;
    
    IBOutlet NSTextField *cutoffTextField;
    IBOutlet NSTextField *resonanceTextField;
    
    FilterDemoViewController *auV3ViewController;
    IBOutlet NSLayoutConstraint *horizontalViewSizeConstraint;
    IBOutlet NSLayoutConstraint *verticalViewSizeConstraint;
    BOOL smallViewMode;
    
    SimplePlayEngine *playEngine;
    
    AUParameter *cutoffParameter;
    AUParameter *resonanceParameter;
    
    AUParameterObserverToken parameterObserverToken;
    NSArray<AUAudioUnitPreset *> *factoryPresets;

    NSArray<AUAudioUnitViewConfiguration*> *viewConfigurations;
}
@property (weak) IBOutlet NSView *containerView;

-(IBAction)togglePlay:(id)sender;
-(IBAction)changedCutoff:(id)sender;
-(IBAction)changedResonance:(id)sender;

-(void)handleMenuSelection:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    [self embedPlugInView];
    
    smallViewMode = NO;
    AudioComponentDescription desc;
    /*  Supply the correct AudioComponentDescription based on your AudioUnit type, manufacturer and creator.
     
        You need to supply matching settings in the AUAppExtension info.plist under:
         
        NSExtension
            NSExtensionAttributes
                AudioComponents
                    Item 0
                        type
                        subtype
                        manufacturer
         
         If you do not do this step, your AudioUnit will not work!!!
     */
    // MARK: AudioComponentDescription Important!
    // Ensure that you update the AudioComponentDescription for your AudioUnit type, manufacturer and creator type.
    desc.componentType = 'aufx';
    desc.componentSubType = 'f1tR';
    desc.componentManufacturer = 'Demo';
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    [AUAudioUnit registerSubclass: AUv3FilterDemo.class
           asComponentDescription: desc
                             name: @"Demo: Local AUv3"
                          version: UINT32_MAX];
    
    playEngine = [[SimplePlayEngine alloc] initWithComponentType: desc.componentType componentsFoundCallback: nil];
    [playEngine selectAudioUnitWithComponentDescription2:desc completionHandler:^{
        [self connectParametersToControls];

        AUAudioUnitViewConfiguration *large = [[AUAudioUnitViewConfiguration alloc] initWithWidth:800.0f height:500.0f hostHasController:NO];
        AUAudioUnitViewConfiguration *small = [[AUAudioUnitViewConfiguration alloc] initWithWidth:400.0f height:100.0f hostHasController:YES];
        viewConfigurations = [NSArray arrayWithObjects:  large, small, nil];
        toggleViewsButton.enabled = ([auV3ViewController.audioUnit supportedViewConfigurations:viewConfigurations].count == 2);
    }];

    [cutoffSlider sendActionOn:NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseDown];
    [resonanceSlider sendActionOn:NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseDown];
    
    [self populatePresetMenu];
}

#pragma mark -

- (void)embedPlugInView {
    NSURL *builtInPlugInURL = [[NSBundle mainBundle] builtInPlugInsURL];
    NSURL *pluginURL = [builtInPlugInURL URLByAppendingPathComponent: @"FilterDemoAppExtension.appex"];
    NSBundle *appExtensionBundle = [NSBundle bundleWithURL: pluginURL];
    
    auV3ViewController = [[FilterDemoViewController alloc] initWithNibName: @"FilterDemoViewController"
                                                                    bundle: appExtensionBundle];
    
    NSView *view = auV3ViewController.view;
    view.frame = _containerView.bounds;
    
    [_containerView addSubview: view];
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    
    horizontalViewSizeConstraint.constant = view.fittingSize.width;
    verticalViewSizeConstraint.constant = view.fittingSize.height;
    smallViewMode = NO;
}

-(void) connectParametersToControls {
    AUParameterTree *parameterTree = playEngine.testAudioUnit.parameterTree;
    
    auV3ViewController.audioUnit = (AUv3FilterDemo *)playEngine.testAudioUnit;
    cutoffParameter = [parameterTree valueForKey: @"cutoff"];
    resonanceParameter = [parameterTree valueForKey: @"resonance"];
    
    __weak ViewController *weakSelf = self;
    parameterObserverToken = [parameterTree tokenByAddingParameterObserver:^(AUParameterAddress address, AUValue value) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong ViewController *strongSelf = weakSelf;
            
            if (address == cutoffParameter.address)
                [strongSelf updateCutoff];
            else if (address == resonanceParameter.address)
                [strongSelf updateResonance];
        });
    }];
    
    [self updateCutoff];
    [self updateResonance];
}

#pragma mark-
#pragma mark: <NSWindowDelegate>

- (void)windowWillClose:(NSNotification *)notification {
    // Main applicaiton window closing, we're done
    [playEngine.testAudioUnit.parameterTree removeParameterObserver:parameterObserverToken];
    [playEngine stopPlaying];
    
    playEngine = nil;
    auV3ViewController = nil;
}

#pragma mark-

static double logValueForNumber(double number) {
    return log(number)/log(2);
}

static double frequencyValueForSliderLocation(double location) {
    double value = powf(2, location); // (this gives us 2^0->2^9)
    value = (value - 1) / 511;        // (normalize based on rage of 2^9-1)

    // map to frequency range
    value *= (kMaxHertz - kMinHertz);
    
    return value + kMinHertz;
}

-(void) updateCutoff {
    cutoffTextField.stringValue = [cutoffParameter stringFromValue:nil];
    
    double cutoffValue = cutoffParameter.value;
    
    // normalize the value from 0-1
    double normalizedValue = ((cutoffValue - kMinHertz) / (kMaxHertz - kMinHertz));
    
    // map to 2^0 - 2^9 (slider range)
    normalizedValue = (normalizedValue * 511.0) + 1;
    
    double location = logValueForNumber(normalizedValue);
    cutoffSlider.doubleValue = location;
}

-(void) updateResonance {
    resonanceTextField.stringValue = [resonanceParameter stringFromValue: nil];
    resonanceSlider.doubleValue = resonanceParameter.value;
    
	[resonanceTextField setNeedsDisplay: YES];
    [resonanceSlider setNeedsDisplay: YES];
}

#pragma mark-
#pragma mark: Actions

-(IBAction)togglePlay:(id)sender {
    BOOL isPlaying = [playEngine togglePlay];
    
    [playButton setTitle: isPlaying ? @"Stop" : @"Play"];
}

- (IBAction)toggleViews:(id)sender {
        AUAudioUnitViewConfiguration *newViewConf = smallViewMode ? viewConfigurations[0] : viewConfigurations[1];

        // Hide to avoid any flickering
        _containerView.hidden = YES;

        [auV3ViewController.audioUnit selectViewConfiguration:newViewConf];
        horizontalViewSizeConstraint.constant = newViewConf.width;
        verticalViewSizeConstraint.constant = newViewConf.height;
        smallViewMode = !smallViewMode;

        // The updates in selectViewConfiguration are dispatched to the main queue, so lets queue our un-hide to make sure the changes finished before we show the container.
        dispatch_async(dispatch_get_main_queue(), ^() {
            _containerView.hidden = NO;
        });
}

-(IBAction)changedCutoff:(id)sender {
    if (sender == cutoffTextField)
        cutoffParameter.value = ((NSControl *)sender).doubleValue;
    else if (sender == cutoffSlider) {
        // map to frequency value
        double value = frequencyValueForSliderLocation(((NSControl *)sender).doubleValue);
        cutoffParameter.value = value;
    }
}

-(IBAction)changedResonance:(id)sender {
    if (sender == resonanceSlider || sender == resonanceTextField)
        resonanceParameter.value = ((NSControl *)sender).doubleValue;
}

#pragma mark-
#pragma mark Application Preset Menu

-(void)populatePresetMenu {
    NSApplication *app = [NSApplication sharedApplication];
    NSMenu *presetMenu = [[app.mainMenu itemWithTag:666] submenu];
    
    factoryPresets = auV3ViewController.audioUnit.factoryPresets;
    
    for (AUAudioUnitPreset *thePreset in factoryPresets) {
        NSString *keyEquivalent = @"";
        
        if (thePreset.number <= 10) {
            long keyValue = ((thePreset.number < 10) ? (long)(thePreset.number + 1) : 0);
            keyEquivalent =[NSString stringWithFormat: @"%ld", keyValue];
        }
        
        NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:thePreset.name
                                                         action:@selector(handleMenuSelection:)
                                                  keyEquivalent:keyEquivalent];
        newItem.tag = thePreset.number;
        [presetMenu addItem:newItem];
    }
    
    AUAudioUnitPreset *currentPreset = auV3ViewController.audioUnit.currentPreset;
    [presetMenu itemAtIndex: currentPreset.number].state = NSOnState;
}

-(void)handleMenuSelection:(NSMenuItem *)sender {
    
    for (NSMenuItem *menuItem in [sender.menu itemArray]) {
        menuItem.state = NSOffState;
    }
    
    sender.state = NSOnState;
    auV3ViewController.audioUnit.currentPreset = [factoryPresets objectAtIndex:sender.tag];
}

@end

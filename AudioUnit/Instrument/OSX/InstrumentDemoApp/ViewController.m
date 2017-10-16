/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller which registers an AUAudioUnit subclass in-process for easy development, connects sliders and text fields to its parameters, and embeds the audio unit's view into a subview. Uses SimplePlayEngine to audition the effect.
*/

#import "ViewController.h"
#import "AppDelegate.h"

#import "InstrumentDemoFramework.h"
#import "InstrumentDemoApp-Swift.h"
#import <CoreAudioKit/AUViewController.h>
#import "InstrumentDemoViewController+AUAudioUnitFactory.h"

@interface ViewController () {
    IBOutlet NSButton *playButton;
    
    InstrumentDemoViewController *auV3ViewController;
    
    SimplePlayEngine *playEngine;
}
-(IBAction)togglePlay:(id)sender;

@property (weak) IBOutlet NSView *containerView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self embedPlugInView];

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
    desc.componentType = kAudioUnitType_MusicDevice;
    desc.componentSubType = 'sin3';
    desc.componentManufacturer = 'Demo';
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;

    [AUAudioUnit registerSubclass: AUv3InstrumentDemo.class
           asComponentDescription: desc
                             name: @"Demo: Local InstrumentDemo"
                          version: UINT32_MAX];
    
    playEngine = [[SimplePlayEngine alloc] initWithComponentType: desc.componentType componentsFoundCallback: nil];
    [playEngine selectAudioUnitWithComponentDescription2:desc completionHandler:^{
        [self connectParametersToControls];
    }];
}

- (void)windowWillClose:(NSNotification *)notification {
    [playEngine stopPlaying];
    
    playEngine = nil;
    auV3ViewController = nil;
}

-(void) embedPlugInView {
    NSURL *builtInPlugInURL = [[NSBundle mainBundle] builtInPlugInsURL];
    NSURL *pluginURL = [builtInPlugInURL URLByAppendingPathComponent: @"InstrumentDemoAppExtension.appex"];
    NSBundle *appExtensionBundle = [NSBundle bundleWithURL: pluginURL];
    
    auV3ViewController = [[InstrumentDemoViewController alloc] initWithNibName: @"InstrumentDemoViewController"
                                                                        bundle: appExtensionBundle];
    
    NSView *view = auV3ViewController.view;
    view.frame = _containerView.bounds;
    
    [_containerView addSubview: view];
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-[view]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)];
    [_containerView addConstraints: constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-[view]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)];
    [_containerView addConstraints: constraints];
}

-(void) connectParametersToControls {
    auV3ViewController.audioUnit = (AUv3InstrumentDemo *)playEngine.testAudioUnit;
}

-(IBAction)togglePlay:(id)sender {
    BOOL isPlaying = [playEngine togglePlay];
    
    [playButton setTitle: isPlaying ? @"Stop" : @"Play"];
}

@end
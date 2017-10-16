/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller for the InstrumentDemo audio unit. Manages the interactions between a InstrumentView and the audio unit's parameters.
*/

#import <Cocoa/Cocoa.h>
#import "InstrumentDemoViewController+AUAudioUnitFactory.h"
#import <InstrumentDemoFramework/InstrumentDemo.h>

@interface InstrumentDemoViewController () {
    __weak IBOutlet NSSlider    *attackSlider;
    __weak IBOutlet NSSlider    *releaseSlider;

    __weak IBOutlet NSTextField *attackField;
    __weak IBOutlet NSTextField *releaseField;
    
    AUParameter *attackParameter;
    AUParameter *releaseParameter;
    AUParameterObserverToken parameterObserverToken;
}

-(IBAction) attackValueChanged:(id) sender;
-(IBAction) releaseValueChanged:(id) sender;

@end

@implementation InstrumentDemoViewController

#pragma mark: <AUAudioUnitFactory>

/* 
 The principal UI class of a v3 audio unit extension must derive from AUViewController and implement the AUAudioUnitFactory protocol.
 
    - createAudioUnitWithComponentDescription:error: should create and return an instance of its audio unit.
 
 This method will be called only once per instance of the factory.
 
 Note that in non-ARC code, "create" methods return unretained objects (unlike "create" C functions); the implementor should return an object with reference count 1 but autoreleased.
*/

- (AUv3InstrumentDemo *) createAudioUnitWithComponentDescription:(AudioComponentDescription)desc
                                                           error:(NSError **)error {
    self.audioUnit = [[AUv3InstrumentDemo alloc] initWithComponentDescription:desc error:error];
    return self.audioUnit;
}

#pragma mark-
#pragma mark: AUViewController

- (id)init {
    self = [super initWithNibName:@"InstrumentDemoViewController"
                           bundle:[NSBundle bundleForClass:NSClassFromString(@"InstrumentDemoViewController")]];
    return self;
}

- (void)dealloc {
    if (parameterObserverToken) {
        [_audioUnit.parameterTree removeParameterObserver:parameterObserverToken];
        parameterObserverToken = 0;
    }
    NSLog(@"InstrumentDemoViewController Dealloc\n");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_audioUnit) {
        [self connectViewWithAU];
    }
    
    self.preferredContentSize = NSMakeSize(480, 122);
    
    [attackSlider sendActionOn:NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseDown];
    [releaseSlider sendActionOn:NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseDown];
}

#pragma mark-

-(void)setAudioUnit:(AUv3InstrumentDemo *)audioUnit {
    _audioUnit = audioUnit;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isViewLoaded]) {
            [self connectViewWithAU];
        }
    });
}

#pragma mark-

-(void)connectViewWithAU {
    AUParameterTree *paramTree = _audioUnit.parameterTree;

    if (paramTree) {
        attackParameter = [paramTree valueForKey: @"attack"];
        releaseParameter = [paramTree valueForKey: @"release"];

        __weak InstrumentDemoViewController *weakSelf = self;
        __weak AUParameter *weakAttackParameter = attackParameter;
        __weak AUParameter *weakReleaseParameter = releaseParameter;
        parameterObserverToken = [paramTree tokenByAddingParameterObserver:^(AUParameterAddress address, AUValue value) {
            __strong InstrumentDemoViewController *strongSelf = weakSelf;
            __strong AUParameter *strongAttackParameter = weakAttackParameter;
            __strong AUParameter *strongReleaseParameter = weakReleaseParameter;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (address == strongAttackParameter.address) {
                    [strongSelf updateAttack];
                } else if (address == strongReleaseParameter.address) {
                    [strongSelf updateRelease];
                }
            });
        }];
        
        [self updateAttack];
        [self updateRelease];
    } else {
        NSLog(@"paramTree is NULL!\n");
    }
}

#pragma mark-

-(void)updateAttack {
    attackField.stringValue = [attackParameter stringFromValue: nil];
    attackSlider.floatValue = (log10f(attackParameter.value) + 3.0) * 100.0f;
}

-(void)updateRelease {
    releaseField.stringValue = [releaseParameter stringFromValue: nil];
    releaseSlider.floatValue = (log10f(releaseParameter.value) + 3.0) * 100.0f;
}

#pragma mark: Actions

-(IBAction)attackValueChanged:(id) sender {
    if (sender == attackField) {
        attackParameter.value = attackField.floatValue;
    } else if (sender == attackSlider) {
        attackParameter.value = powf(10.0, attackSlider.floatValue * 0.01 - 3.0);
    }
}

-(IBAction)releaseValueChanged:(id) sender {
    if (sender == releaseField) {
        releaseParameter.value = releaseField.floatValue;
    } else if (sender == releaseSlider) {
        releaseParameter.value = powf(10.0, releaseSlider.floatValue * 0.01 - 3.0);
    }
}

@end

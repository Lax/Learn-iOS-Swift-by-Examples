/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
An AUAudioUnit subclass implementing a low-pass filter with resonance. Illustrates parameter management and rendering, including in-place processing and buffer management.
*/

#import "FilterDemo.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/AUViewController.h>
#import "FilterDSPKernel.hpp"
#import "BufferedAudioBus.hpp"
#import "FilterDemoViewController+AUAudioUnitFactory.h"

#pragma mark AUv3FilterDemo (Presets)

static const UInt8 kNumberOfPresets = 3;
static const NSInteger kDefaultFactoryPreset = 0;

typedef struct FactoryPresetParameters {
    AUValue cutoffValue;
    AUValue resonanceValue;
} FactoryPresetParameters;

static const FactoryPresetParameters presetParameters[kNumberOfPresets] = {
    // preset 0
    {
        400.0f,//FilterParamCutoff,
         -5.0f,//FilterParamResonance
    },
    
    // preset 1
    {
        6000.0f,//FilterParamCutoff,
          15.0f,//FilterParamResonance
    },
    
    // preset 2
    {
        1000.0f,//FilterParamCutoff,
           5.0f,//FilterParamResonance
    }
};

static AUAudioUnitPreset* NewAUPreset(NSInteger number, NSString *name) {
    AUAudioUnitPreset *aPreset = [AUAudioUnitPreset new];
    aPreset.number = number;
    aPreset.name = name;
    return aPreset;
}

#pragma mark - AUv3FilterDemo : AUAudioUnit

@interface AUv3FilterDemo ()

@property AUAudioUnitBus *outputBus;
@property AUAudioUnitBusArray *inputBusArray;
@property AUAudioUnitBusArray *outputBusArray;

@end

@implementation AUv3FilterDemo {
	// C++ members need to be ivars; they would be copied on access if they were properties.
    FilterDSPKernel  _kernel;
    BufferedInputBus _inputBus;

    NSInteger        _currentFactoryPresetIndex;
}
@synthesize parameterTree  = _parameterTree;
@synthesize factoryPresets = _factoryPresets;
@synthesize currentPreset  = _currentPreset;

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription
                                     options:(AudioComponentInstantiationOptions)options
                                       error:(NSError **)outError {
    
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    if (self == nil) { return nil; }
    
    // componentFlags 0x0000001e == SandboxSafe(2) + IsV3AudioUnit(4) + RequiresAsyncInstantiation(8) + CanLoadInProcess(0x10)
    NSLog(@"AUv3FilterDemo initWithComponentDescription:\n componentType: %c%c%c%c\n componentSubType: %c%c%c%c\n componentManufacturer: %c%c%c%c\n componentFlags: %#010x",
          FourCCChars(componentDescription.componentType),
          FourCCChars(componentDescription.componentSubType),
          FourCCChars(componentDescription.componentManufacturer),
          componentDescription.componentFlags);
    
    NSLog(@"Process Name: %s PID: %d\n", [[[NSProcessInfo processInfo] processName] UTF8String],
                                         [[NSProcessInfo processInfo] processIdentifier]);
	
	// Initialize a default format for the busses.
    AVAudioFormat *defaultFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];

	// Create a DSP kernel to handle the signal processing.
	_kernel.init(defaultFormat.channelCount, defaultFormat.sampleRate);
	
	// Create a parameter object for the cutoff frequency.
	AUParameter *cutoffParam = [AUParameterTree createParameterWithIdentifier:@"cutoff" name:@"Cutoff"
			address:FilterParamCutoff
			min:12.0 max:20000.0 unit:kAudioUnitParameterUnit_Hertz unitName:nil
			flags: kAudioUnitParameterFlag_IsReadable |
                   kAudioUnitParameterFlag_IsWritable |
                   kAudioUnitParameterFlag_CanRamp
            valueStrings:nil dependentParameters:nil];
	
	// Create a parameter object for the filter resonance.
	AUParameter *resonanceParam = [AUParameterTree createParameterWithIdentifier:@"resonance" name:@"Resonance"
			address:FilterParamResonance
			min:-20.0 max:20.0 unit:kAudioUnitParameterUnit_Decibels unitName:nil
			flags: kAudioUnitParameterFlag_IsReadable |
                   kAudioUnitParameterFlag_IsWritable |
                   kAudioUnitParameterFlag_CanRamp
            valueStrings:nil dependentParameters:nil];
	
	// Initialize default parameter values.
	cutoffParam.value = 20000.0;
	resonanceParam.value = 0.0;
	_kernel.setParameter(FilterParamCutoff, cutoffParam.value);
	_kernel.setParameter(FilterParamResonance, resonanceParam.value);
    
    // Create factory preset array.
	_currentFactoryPresetIndex = kDefaultFactoryPreset;
    _factoryPresets = @[NewAUPreset(0, @"First Preset"),
                        NewAUPreset(1, @"Second Preset"),
                        NewAUPreset(2, @"Third Preset")];
    
    /* 
       Audio unit hosts can fetch the parameter tree to discover a units parameters.
       KVO notifications are issued on this member to notify the host of changes to the set of available parameters.
    
       AUAudioUnit has an additional pseudo-property, "allParameterValues", on which KVO notifications are issued in
       response to certain events where potentially all parameter values are invalidated. This includes changes to
       currentPreset, fullState, and fullStateForDocument.
    */
    // Create the parameter tree.
    _parameterTree = [AUParameterTree createTreeWithChildren:@[cutoffParam, resonanceParam]];

	// Create the input and output busses.
	_inputBus.init(defaultFormat, 8);
    _outputBus = [[AUAudioUnitBus alloc] initWithFormat:defaultFormat error:nil];

	// Create the input and output bus arrays.
	_inputBusArray  = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeInput busses: @[_inputBus.bus]];
	_outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeOutput busses: @[_outputBus]];

	// Make a local pointer to the kernel to avoid capturing self.
	__block FilterDSPKernel *filterKernel = &_kernel;

	// implementorValueObserver is called when a parameter changes value.
	_parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        /* 
           This block, used only in an audio unit implementation, receives all externally-generated
           changes to parameter values. It should store the new value in its audio signal processing
           state (assuming that that state is separate from the AUParameter object).
        */
        filterKernel->setParameter(param.address, value);
	};
	
	// implementorValueProvider is called when the value needs to be refreshed.
	_parameterTree.implementorValueProvider = ^(AUParameter *param) {
        /* 
           The audio unit should return the current value for this parameter; the AUParameterNode
           will store the value.
        */
		return filterKernel->getParameter(param.address);
	};
	
	// implementorStringFromValueCallback is called to provide string representations of parameter values.
	_parameterTree.implementorStringFromValueCallback = ^(AUParameter *param, const AUValue *__nullable valuePtr) {
		// If value is nil, use the current value of the parameter.
        AUValue value = valuePtr == nil ? param.value : *valuePtr;
	
		switch (param.address) {
			case FilterParamCutoff:
				return [NSString stringWithFormat:@"%.f", value];
			
			case FilterParamResonance:
				return [NSString stringWithFormat:@"%.2f", value];
			
			default:
				return @"?";
		}
	};

	self.maximumFramesToRender = 512;
    
    // set default preset as current
    self.currentPreset = _factoryPresets[kDefaultFactoryPreset];

	return self;
}

-(void)dealloc {
    _factoryPresets = nil;
    NSLog(@"AUv3FilterDemo Dealloc\n");
}

#pragma mark - AUAudioUnit (Overrides)

// Subclassers must override this property's getter. Return the same object
// every time, since clients can install KVO observers on it.
- (AUAudioUnitBusArray *)inputBusses {
    return _inputBusArray;
}

// Subclassers must override this property's getter. Return the same object
// every time, since clients can install KVO observers on it.
- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation. Hosts must call this to initialize the AU before beginning to render.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
	if (![super allocateRenderResourcesAndReturnError:outError]) {
		return NO;
	}
	
    if (self.outputBus.format.channelCount != _inputBus.bus.format.channelCount) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:kAudioUnitErr_FailedInitialization userInfo:nil];
        }
        // Notify superclass that initialization was not successful
        self.renderResourcesAllocated = NO;
        
        return NO;
    }
	
	_inputBus.allocateRenderResources(self.maximumFramesToRender);
	
	_kernel.init(self.outputBus.format.channelCount, self.outputBus.format.sampleRate);
	_kernel.reset();
	
	return YES;
}

// Deallocate resources allocated by allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation. Hosts should call this after finishing rendering.
- (void)deallocateRenderResources {
	_inputBus.deallocateRenderResources();
    
    [super deallocateRenderResources];
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// Subclassers must provide a AUInternalRenderBlock (via a getter) to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
	/*
		Capture in locals to avoid ObjC member lookups. If "self" is captured in
        render, we're doing it wrong.
	*/
    // Specify captured objects are mutable.
	__block FilterDSPKernel *state = &_kernel;
	__block BufferedInputBus *input = &_inputBus;
    
    return ^AUAudioUnitStatus(
			 AudioUnitRenderActionFlags *actionFlags,
			 const AudioTimeStamp       *timestamp,
			 AVAudioFrameCount           frameCount,
			 NSInteger                   outputBusNumber,
			 AudioBufferList            *outputData,
			 const AURenderEvent        *realtimeEventListHead,
			 AURenderPullInputBlock      pullInputBlock) {
		AudioUnitRenderActionFlags pullFlags = 0;

		AUAudioUnitStatus err = input->pullInput(&pullFlags, timestamp, frameCount, 0, pullInputBlock);
		
        if (err != 0) { return err; }
		
		AudioBufferList *inAudioBufferList = input->mutableAudioBufferList;
		
        /*
         Important:
             If the caller passed non-null output pointers (outputData->mBuffers[x].mData), use those.
             
             If the caller passed null output buffer pointers, process in memory owned by the Audio Unit
             and modify the (outputData->mBuffers[x].mData) pointers to point to this owned memory.
             The Audio Unit is responsible for preserving the validity of this memory until the next call to render,
             or deallocateRenderResources is called.
             
             If your algorithm cannot process in-place, you will need to preallocate an output buffer
             and use it here.
         
             See the description of the canProcessInPlace property.
         */
        
        // If passed null output buffer pointers, process in-place in the input buffer.
		AudioBufferList *outAudioBufferList = outputData;
		if (outAudioBufferList->mBuffers[0].mData == nullptr) {
			for (UInt32 i = 0; i < outAudioBufferList->mNumberBuffers; ++i) {
				outAudioBufferList->mBuffers[i].mData = inAudioBufferList->mBuffers[i].mData;
			}
		}
		
		state->setBuffers(inAudioBufferList, outAudioBufferList);
		state->processWithEvents(timestamp, frameCount, realtimeEventListHead, nil /* MIDIOutEventBlock */);

		return noErr;
	};
}

#pragma mark- AUAudioUnit (Optional Properties)

- (AUAudioUnitPreset *)currentPreset {
    if (_currentPreset.number >= 0) {
        NSLog(@"Returning Current Factory Preset: %ld\n", (long)_currentFactoryPresetIndex);
        return [_factoryPresets objectAtIndex:_currentFactoryPresetIndex];
    } else {
        NSLog(@"Returning Current Custom Preset: %ld, %@\n", (long)_currentPreset.number, _currentPreset.name);
        return _currentPreset;
    }
}

- (void)setCurrentPreset:(AUAudioUnitPreset *)currentPreset {
    if (nil == currentPreset) { NSLog(@"nil passed to setCurrentPreset!"); return; }
    
    if (currentPreset.number >= 0) {
        // factory preset
        for (AUAudioUnitPreset *factoryPreset in _factoryPresets) {
            if (currentPreset.number == factoryPreset.number) {
                
                AUParameter *cutoffParameter = [self.parameterTree valueForKey: @"cutoff"];
                AUParameter *resonanceParameter = [self.parameterTree valueForKey: @"resonance"];
                
                cutoffParameter.value = presetParameters[factoryPreset.number].cutoffValue;
                resonanceParameter.value = presetParameters[factoryPreset.number].resonanceValue;
                
                // set factory preset as current
                _currentPreset = currentPreset;
                _currentFactoryPresetIndex = factoryPreset.number;
                NSLog(@"currentPreset Factory: %ld, %@\n", (long)_currentFactoryPresetIndex, factoryPreset.name);
                
                break;
            }
        }
    } else if (nil != currentPreset.name) {
        // set custom preset as current
        _currentPreset = currentPreset;
        NSLog(@"currentPreset Custom: %ld, %@\n", (long)_currentPreset.number, _currentPreset.name);
    } else {
        NSLog(@"setCurrentPreset not set! - invalid AUAudioUnitPreset\n");
    }
}

// Expresses whether an audio unit can process in place.
// In-place processing is the ability for an audio unit to transform an input signal to an
// output signal in-place in the input buffer, without requiring a separate output buffer.
// A host can express its desire to process in place by using null mData pointers in the output
// buffer list. The audio unit may process in-place in the input buffers.
// See the discussion of renderBlock.
// Partially bridged to the v2 property kAudioUnitProperty_InPlaceProcessing, the v3 property is not settable.
- (BOOL)canProcessInPlace {
    return YES;
}

#pragma mark -

- (NSArray<NSNumber *> *)magnitudesForFrequencies:(NSArray<NSNumber *> *)frequencies {
	FilterDSPKernel::BiquadCoefficients coefficients;

    double inverseNyquist = 2.0 / self.outputBus.format.sampleRate;
	
    coefficients.calculateLopassParams(_kernel.cutoffRamper.getUIValue(), _kernel.resonanceRamper.getUIValue());
	
    NSMutableArray<NSNumber *> *magnitudes = [NSMutableArray arrayWithCapacity:frequencies.count];
	
    for (NSNumber *number in frequencies) {
		double frequency = [number doubleValue];
		double magnitude = coefficients.magnitudeForFrequency(frequency * inverseNyquist);

        [magnitudes addObject:@(magnitude)];
	}
	
    return [NSArray arrayWithArray:magnitudes];
}

#pragma mark - AUAudioUnit ViewController related

- (NSIndexSet *)supportedViewConfigurations:(NSArray<AUAudioUnitViewConfiguration *> *)availableViewConfigurations {
    NSMutableIndexSet *result = [NSMutableIndexSet indexSet];
    for (unsigned i = 0; i < [availableViewConfigurations count]; ++i)
    {
        // The two views we actually have
        if ((availableViewConfigurations[i].width >= 800 && availableViewConfigurations[i].height >= 500) ||
            (availableViewConfigurations[i].width <= 400 && availableViewConfigurations[i].height <= 100) ||
            // Full-screen size or our own window, always supported, we return our biggest view size in this case
            (availableViewConfigurations[i].width == 0 && availableViewConfigurations[i].height == 0)) {
            [result addIndex:i];
        }
    }

    return result;
}

- (void)selectViewConfiguration:(AUAudioUnitViewConfiguration *)viewConfiguration {
    return [self.filterDemoViewController handleSelectViewConfiguration:viewConfiguration];
}

@end

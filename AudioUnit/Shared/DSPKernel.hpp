/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Utility code to manage scheduled parameters in an audio unit implementation.
*/

#ifndef DSPKernel_h
#define DSPKernel_h

#import <AudioToolbox/AudioToolbox.h>
#import <algorithm>

template <typename T>
T clamp(T input, T low, T high) {
	return std::min(std::max(input, low), high);
}

// Put your DSP code into a subclass of DSPKernel.
class DSPKernel {
public:
	virtual void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) = 0;
	virtual void startRamp(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) = 0;
	
	// Override to handle MIDI events.
	virtual void handleMIDIEvent(AUMIDIEvent const& midiEvent) {}
	
	void processWithEvents(AudioTimeStamp const* timestamp, AUAudioFrameCount frameCount, AURenderEvent const* events, AUMIDIOutputEventBlock midiOut);

private:
	void handleOneEvent(AURenderEvent const* event);
	void performAllSimultaneousEvents(AUEventSampleTime now, AURenderEvent const*& event, AUMIDIOutputEventBlock midiOut);
};

#endif /* DSPKernel_h */

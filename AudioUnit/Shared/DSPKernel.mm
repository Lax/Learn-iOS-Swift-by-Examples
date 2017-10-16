/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Utility code to manage scheduled parameters in an audio unit implementation.
*/

#import "DSPKernel.hpp"

void DSPKernel::handleOneEvent(AURenderEvent const *event) {
	switch (event->head.eventType) {
		case AURenderEventParameter:
		case AURenderEventParameterRamp: {
			AUParameterEvent const& paramEvent = event->parameter;
			
			startRamp(paramEvent.parameterAddress, paramEvent.value, paramEvent.rampDurationSampleFrames);
			break;
		}
			
		case AURenderEventMIDI:
			handleMIDIEvent(event->MIDI);
			break;
		
		default:
			break;
	}
}

void DSPKernel::performAllSimultaneousEvents(AUEventSampleTime now, AURenderEvent const *&event, AUMIDIOutputEventBlock midiOut) {
	do {
		handleOneEvent(event);

        if (event->head.eventType == AURenderEventMIDI && midiOut)
        {
            midiOut(now, 0, event->MIDI.length, event->MIDI.data);
        }
        
		// Go to next event.
		event = event->head.next;
		
		// While event is not null and is simultaneous (or late).
	} while (event && event->head.eventSampleTime <= now);
}

/**
	This function handles the event list processing and rendering loop for you.
	Call it inside your internalRenderBlock.
*/
void DSPKernel::processWithEvents(AudioTimeStamp const *timestamp, AUAudioFrameCount frameCount, AURenderEvent const *events, AUMIDIOutputEventBlock midiOut) {

	AUEventSampleTime now = AUEventSampleTime(timestamp->mSampleTime);
	AUAudioFrameCount framesRemaining = frameCount;
	AURenderEvent const *event = events;
	
	while (framesRemaining > 0) {
		// If there are no more events, we can process the entire remaining segment and exit.
		if (event == nullptr) {
			AUAudioFrameCount const bufferOffset = frameCount - framesRemaining;
			process(framesRemaining, bufferOffset);
			return;
		}

        // **** start late events late.
		auto timeZero = AUEventSampleTime(0);
		auto headEventTime = event->head.eventSampleTime;
		AUAudioFrameCount const framesThisSegment = AUAudioFrameCount(std::max(timeZero, headEventTime - now));
		
		// Compute everything before the next event.
		if (framesThisSegment > 0) {
			AUAudioFrameCount const bufferOffset = frameCount - framesRemaining;
			process(framesThisSegment, bufferOffset);
							
			// Advance frames.
			framesRemaining -= framesThisSegment;

			// Advance time.
			now += AUEventSampleTime(framesThisSegment);
		}
		
		performAllSimultaneousEvents(now, event, midiOut);
	}
}


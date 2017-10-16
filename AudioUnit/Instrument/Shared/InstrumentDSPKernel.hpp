/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
A DSPKernel subclass implementing the realtime signal processing portion of the InstrumentDemo audio unit.
*/

#ifndef InstrumentDSPKernel_hpp
#define InstrumentDSPKernel_hpp

#import "DSPKernel.hpp"
#import <vector>

const double kTwoPi = 2.0 * M_PI;

enum {
	InstrumentParamAttack = 0,
	InstrumentParamRelease = 1
};

static inline double pow2(double x) {
	return x * x;
}

static inline double pow3(double x) {
	return x * x * x;
}

static inline double noteToHz(int noteNumber)
{
	return 440. * exp2((noteNumber - 69)/12.);
}

static inline double panValue(double x)
{
	x = clamp(x, -1., 1.);
	return cos(M_PI_2 * (.5 * x + .5));
}

/*
	InstrumentDSPKernel
	Performs our filter signal processing.
	As a non-ObjC class, this is safe to use from render thread.
*/
class InstrumentDSPKernel : public DSPKernel {
public:
    // MARK: Types
	struct NoteState {
		NoteState* next;
		NoteState* prev;
		InstrumentDSPKernel* kernel;
		
		enum { stageOff, stageAttack, stageSustain, stageRelease };
		double oscFreq = 0.;
		double oscPhase = 0.;
		double envLevel = 0.;
		double envSlope = 0.;
		double ampL = 0.;
		double ampR = 0.;
		
		int stage = stageOff;
		int envRampSamples = 0;
		
		void clear() {
			stage = stageOff;
			envLevel = 0.;
			oscPhase = 0.;
		}
		
		// linked list management
		void remove() {
			if (prev) prev->next = next;
			else kernel->playingNotes = next;
			
			if (next) next->prev = prev;

			prev = next = nullptr;
			
			--kernel->playingNotesCount;
		}
		
		void add() {
			prev = nullptr;
			next = kernel->playingNotes;
			if (next) next->prev = this;
			kernel->playingNotes = this;
			++kernel->playingNotesCount;
		}
		
		void noteOn(int noteNumber, int velocity)
		{
			if (velocity == 0) {
				if (stage == stageAttack || stage == stageSustain) {
					stage = stageRelease;
					envRampSamples = kernel->releaseSamples;
					envSlope = -envLevel / envRampSamples;
				}
			} else {
				if (stage == stageOff) { add(); }
				oscFreq = noteToHz(noteNumber) * kernel->frequencyScale;
				double pan = (noteNumber - 66.) / 42.; // pan from note number
				double amp = pow2(velocity / 127.) * .2; // amplitude from velocity
				ampL = amp * panValue(-pan);
				ampR = amp * panValue(pan);
				oscPhase = 0.;
				stage = stageAttack;
				envRampSamples = kernel->attackSamples;
				envSlope = (1.0 - envLevel) / envRampSamples;
			}
		}
		
		void run(int n, float* outL, float* outR)
		{
			int framesRemaining = n;
			while (framesRemaining) {
				switch (stage) {
					case stageOff :
						NSLog(@"stageOff on playingNotes list!");
						return;
					case stageAttack : {
						int framesThisTime = std::min(framesRemaining, envRampSamples);
						for (int i = 0; i < framesThisTime; ++i) {
							double x = envLevel * pow3(sin(oscPhase)); // cubing the sine adds 3rd harmonic.
							*outL++ += ampL * x;
							*outR++ += ampR * x;
							envLevel += envSlope;
							oscPhase += oscFreq;
							if (oscPhase >= kTwoPi) oscPhase -= kTwoPi;
						}
						framesRemaining -= framesThisTime;
						envRampSamples -= framesThisTime;
						if (envRampSamples == 0) {
							stage = stageSustain;
						}
						break;
					}
					case stageSustain : {
						for (int i = 0; i < framesRemaining; ++i) {
							double x = pow3(sin(oscPhase));
							*outL++ += ampL * x;
							*outR++ += ampR * x;
							oscPhase += oscFreq;
							if (oscPhase >= kTwoPi) oscPhase -= kTwoPi;
						}
						return;
					}
					case stageRelease : {
						int framesThisTime = std::min(framesRemaining, envRampSamples);
						for (int i = 0; i < framesThisTime; ++i) {
							double x = envLevel * pow3(sin(oscPhase));
							*outL++ += ampL * x;
							*outR++ += ampR * x;
							envLevel += envSlope;
							oscPhase += oscFreq;
						}
						envRampSamples -= framesThisTime;
						if (envRampSamples == 0) {
							clear();
							remove();
						}
						return;
					}
					default:
						NSLog(@"bad stage on playingNotes list!");
						return;
				}
			}
		}

	};
	
    // MARK: Member Functions

    InstrumentDSPKernel() {
		noteStates.resize(128);
		for (NoteState& state : noteStates) {
			state.kernel = this;
		}
	}
	
	void init(int channelCount, double inSampleRate) {
		sampleRate = float(inSampleRate);
		
		frequencyScale = 2. * M_PI / sampleRate;
	}
	
	void reset() {
		for (NoteState& state : noteStates) {
			state.clear();
		}
		playingNotes = nullptr;
		playingNotesCount = 0;

	}
	
	void setParameter(AUParameterAddress address, AUValue value) {
        switch (address) {
            case InstrumentParamAttack:
				attack = clamp(value, 0.001f, 10.f);
				attackSamples = sampleRate * attack;
				break;
                
            case InstrumentParamRelease:
				release = clamp(value, 0.001f, 10.f);
				releaseSamples = sampleRate * release;
				break;
        }
	}

	AUValue getParameter(AUParameterAddress address) {
        switch (address) {
            case InstrumentParamAttack:
                return attack;

            case InstrumentParamRelease:
                return release;
				
			default: return 0.0f;
        }
	}

	void startRamp(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) override {
		// The attack and release parameters are not ramped. 
		setParameter(address, value);
	}
	
	void setBuffers(AudioBufferList* outBufferList) {
		outBufferListPtr = outBufferList;
	}

	virtual void handleMIDIEvent(AUMIDIEvent const& midiEvent) override {
		if (midiEvent.length != 3) return;
		uint8_t status = midiEvent.data[0] & 0xF0;
		//uint8_t channel = midiEvent.data[0] & 0x0F; // works in omni mode.
		switch (status) {
			case 0x80 : { // note off
				uint8_t note = midiEvent.data[1];
				if (note > 127) break;
				noteStates[note].noteOn(note, 0);
				break;
			}
			case 0x90 : { // note on
				uint8_t note = midiEvent.data[1];
				uint8_t veloc = midiEvent.data[2];
				if (note > 127 || veloc > 127) break;
				noteStates[note].noteOn(note, veloc);
				break;
			}
			case 0xB0 : { // control
				uint8_t num = midiEvent.data[1];
				if (num == 123) { // all notes off
					NoteState* noteState = playingNotes;
					while (noteState) {
						noteState->clear();
						noteState = noteState->next;
					}
					playingNotes = nullptr;
					playingNotesCount = 0;
				}
				break;
			}
		}
	}
		
	void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {
		float* outL = (float*)outBufferListPtr->mBuffers[0].mData + bufferOffset;
		float* outR = (float*)outBufferListPtr->mBuffers[1].mData + bufferOffset;

		NoteState* noteState = playingNotes;
		while (noteState) {
			noteState->run(frameCount, outL, outR);
			noteState = noteState->next;
		}
		
		for (AUAudioFrameCount i = 0; i < frameCount; ++i) {
			outL[i] *= .1f;
			outR[i] *= .1f;
		}
	}
	
    // MARK: Member Variables

private:
	std::vector<NoteState> noteStates;
	
	float sampleRate = 44100.0;
	double frequencyScale = 2. * M_PI / sampleRate;
	
	AudioBufferList* outBufferListPtr = nullptr;

public:

	NoteState* playingNotes = nullptr;
	int playingNotesCount = 0;
	
	// Parameters.
	float attack = .01f;
	float release = .1f;

	int attackSamples   = sampleRate * attack;
	int releaseSamples  = sampleRate * release;
	
};

#endif /* InstrumentDSPKernel_hpp */

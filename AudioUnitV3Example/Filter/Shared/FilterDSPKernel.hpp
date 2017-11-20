/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
A DSPKernel subclass implementing the realtime signal processing portion of the FilterDemo audio unit.
*/

#ifndef FilterDSPKernel_hpp
#define FilterDSPKernel_hpp

#import "DSPKernel.hpp"
#import "ParameterRamper.hpp"
#import <vector>

static inline float convertBadValuesToZero(float x) {
	/*
		Eliminate denormals, not-a-numbers, and infinities.
		Denormals will fail the first test (absx > 1e-15), infinities will fail 
        the second test (absx < 1e15), and NaNs will fail both tests. Zero will
        also fail both tests, but since it will get set to zero that is OK.
	*/
		
	float absx = fabs(x);

    if (absx > 1e-15 && absx < 1e15) {
		return x;
	}

    return 0.0;
}


enum {
	FilterParamCutoff = 0,
	FilterParamResonance = 1
};

static inline double squared(double x) {
    return x * x;
}

/*
	FilterDSPKernel
	Performs our filter signal processing.
	As a non-ObjC class, this is safe to use from render thread.
*/
class FilterDSPKernel : public DSPKernel {
public:
    // MARK: Types
	struct FilterState {
		float x1 = 0.0;
		float x2 = 0.0;
		float y1 = 0.0;
		float y2 = 0.0;
		
		void clear() {
			x1 = 0.0;
			x2 = 0.0;
			y1 = 0.0;
			y2 = 0.0;
		}

		void convertBadStateValuesToZero() {
			/*
				These filters work by feedback. If an infinity or NaN should come 
                into the filter input, the feedback variables can become infinity 
                or NaN which will cause the filter to stop operating. This function
                clears out any bad numbers in the feedback variables.
			*/
			x1 = convertBadValuesToZero(x1);
			x2 = convertBadValuesToZero(x2);
			y1 = convertBadValuesToZero(y1);
			y2 = convertBadValuesToZero(y2);
		}
	};
	
	struct BiquadCoefficients {
		float a1 = 0.0;
		float a2 = 0.0;
		float b0 = 0.0;
		float b1 = 0.0;
		float b2 = 0.0;

		void calculateLopassParams(double frequency, double resonance) {
			/*
                The transcendental function calls here could be replaced with
                interpolated table lookups or other approximations.
            */
            
            // Convert from decibels to linear.
			double r = pow(10.0, 0.05 * -resonance);
			
			double k  = 0.5 * r * sin(M_PI * frequency);
			double c1 = (1.0 - k) / (1.0 + k);
			double c2 = (1.0 + c1) * cos(M_PI * frequency);
			double c3 = (1.0 + c1 - c2) * 0.25;
			
			b0 = float(c3);
			b1 = float(2.0 * c3);
			b2 = float(c3);
			a1 = float(-c2);
			a2 = float(c1);
		}
		
        // Arguments in Hertz.
		double magnitudeForFrequency( double inFreq) {
			// Cast to Double.
			double _b0 = double(b0);
			double _b1 = double(b1);
			double _b2 = double(b2);
			double _a1 = double(a1);
			double _a2 = double(a2);
		
			// Frequency on unit circle in z-plane.
			double zReal      = cos(M_PI * inFreq);
			double zImaginary = sin(M_PI * inFreq);
			
			// Zeros response.
			double numeratorReal = (_b0 * (squared(zReal) - squared(zImaginary))) + (_b1 * zReal) + _b2;
			double numeratorImaginary = (2.0 * _b0 * zReal * zImaginary) + (_b1 * zImaginary);
			
			double numeratorMagnitude = sqrt(squared(numeratorReal) + squared(numeratorImaginary));
			
			// Poles response.
			double denominatorReal = squared(zReal) - squared(zImaginary) + (_a1 * zReal) + _a2;
			double denominatorImaginary = (2.0 * zReal * zImaginary) + (_a1 * zImaginary);
			
			double denominatorMagnitude = sqrt(squared(denominatorReal) + squared(denominatorImaginary));
			
			// Total response.
			double response = numeratorMagnitude / denominatorMagnitude;

			return response;
		}
	};
	
    // MARK: Member Functions

    FilterDSPKernel() : cutoffRamper(400.0 / 44100.0), resonanceRamper(20.0)  {}
	
	void init(int channelCount, double inSampleRate) {
		channelStates.resize(channelCount);
		
		sampleRate = float(inSampleRate);
		nyquist = 0.5 * sampleRate;
		inverseNyquist = 1.0 / nyquist;
		dezipperRampDuration = (AUAudioFrameCount)floor(0.02 * sampleRate);
		cutoffRamper.init();
		resonanceRamper.init();
		
	}
	
	void reset() {
		cutoffRamper.reset();
		resonanceRamper.reset();
		for (FilterState& state : channelStates) {
			state.clear();
		}
	}
	
	void setParameter(AUParameterAddress address, AUValue value) {
        switch (address) {
            case FilterParamCutoff:
                //cutoffRamper.setUIValue(clamp(value * inverseNyquist, 0.0f, 0.99f));
				cutoffRamper.setUIValue(clamp(value * inverseNyquist, 0.0005444f, 0.9070295f));
				break;
                
            case FilterParamResonance:
                resonanceRamper.setUIValue(clamp(value, -20.0f, 20.0f));
				break;
        }
	}

	AUValue getParameter(AUParameterAddress address) {
        switch (address) {
            case FilterParamCutoff:
                // Return the goal. It is not thread safe to return the ramping value.
                //return (cutoffRamper.getUIValue() * nyquist);
                return roundf((cutoffRamper.getUIValue() * nyquist) * 100) / 100;

            case FilterParamResonance:
                return resonanceRamper.getUIValue();
				
			default: return 12.0f * inverseNyquist;
        }
	}

	void startRamp(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) override {
        switch (address) {
			case FilterParamCutoff:
				cutoffRamper.startRamp(clamp(value * inverseNyquist, 12.0f * inverseNyquist, 0.99f), duration);
				break;
			
			case FilterParamResonance:
				resonanceRamper.startRamp(clamp(value, -20.0f, 20.0f), duration);
				break;
		}
	}
	
	void setBuffers(AudioBufferList* inBufferList, AudioBufferList* outBufferList) {
		inBufferListPtr = inBufferList;
		outBufferListPtr = outBufferList;
	}
	
	void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {
		int channelCount = int(channelStates.size());
		
		cutoffRamper.dezipperCheck(dezipperRampDuration);
		resonanceRamper.dezipperCheck(dezipperRampDuration);
		
        // For each sample.
		for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
			/*
                The filter coefficients are updated every sample! This is very
                expensive. You probably want to do things differently.
            */
			double cutoff    = double(cutoffRamper.getAndStep());
			double resonance = double(resonanceRamper.getAndStep());
			coeffs.calculateLopassParams(cutoff, resonance);

            int frameOffset = int(frameIndex + bufferOffset);
			
			for (int channel = 0; channel < channelCount; ++channel) {
				FilterState& state = channelStates[channel];
				float* in  = (float*)inBufferListPtr->mBuffers[channel].mData  + frameOffset;
				float* out = (float*)outBufferListPtr->mBuffers[channel].mData + frameOffset;

				float x0 = *in;
				float y0 = (coeffs.b0 * x0) + (coeffs.b1 * state.x1) + (coeffs.b2 * state.x2) - (coeffs.a1 * state.y1) - (coeffs.a2 * state.y2);
				*out = y0;
				
				state.x2 = state.x1;
				state.x1 = x0;
				state.y2 = state.y1;
				state.y1 = y0;
			}
		}
		
        // Squelch any blowups once per cycle.
		for (int channel = 0; channel < channelCount; ++channel) {
			channelStates[channel].convertBadStateValuesToZero();
		}
	}
	
    // MARK: Member Variables

private:
	std::vector<FilterState> channelStates;
	BiquadCoefficients coeffs;
	
	float sampleRate = 44100.0;
	float nyquist = 0.5 * sampleRate;
	float inverseNyquist = 1.0 / nyquist;
	AUAudioFrameCount dezipperRampDuration;

	AudioBufferList* inBufferListPtr = nullptr;
	AudioBufferList* outBufferListPtr = nullptr;

public:

	// Parameters.
	ParameterRamper cutoffRamper;
	ParameterRamper resonanceRamper;
};

#endif /* FilterDSPKernel_hpp */

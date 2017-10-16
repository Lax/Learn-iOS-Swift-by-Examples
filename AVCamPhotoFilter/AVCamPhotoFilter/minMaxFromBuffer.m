/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Implements a function which extracts the smallest and largest values from a pixel buffer.
*/

#import "minMaxFromBuffer.h"
#import <Foundation/Foundation.h>
#import <simd/simd.h>

void minMaxFromPixelBuffer(CVPixelBufferRef pixelBuffer, float* minValue, float* maxValue, MTLPixelFormat pixelFormat)
{
	int width  		= (int)CVPixelBufferGetWidth(pixelBuffer);
	int height 		= (int)CVPixelBufferGetHeight(pixelBuffer);
	int bytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);

	CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	unsigned char* pixelBufferPointer = CVPixelBufferGetBaseAddress(pixelBuffer);
	__fp16* bufferP_F16 = (__fp16 *) pixelBufferPointer;
	float*  bufferP_F32 = (float  *) pixelBufferPointer;

	bool isFloat16 = (pixelFormat == MTLPixelFormatR16Float);
	uint32_t increment = isFloat16 ?  bytesPerRow/sizeof(__fp16) : bytesPerRow/sizeof(float);

	float min = MAXFLOAT;
	float max = -MAXFLOAT;

	for (int j=0; j < height; j++)
	{
		for (int i=0; i < width; i++)
		{
			float val = ( isFloat16 ) ?  bufferP_F16[i] :  bufferP_F32[i] ;
			if (!isnan(val)) {
				if (val>max) max = val;
				if (val<min) min = val;
			}
		}
		if ( isFloat16 ) {
			bufferP_F16 +=increment;
		}  else {
			bufferP_F32 +=increment;
		}
	}

	CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

	*minValue = min;
	*maxValue = max;
}

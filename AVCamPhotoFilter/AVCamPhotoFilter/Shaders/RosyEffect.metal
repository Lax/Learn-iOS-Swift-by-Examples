/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Shader that gives images a pink tint by zero-ing out the green value.
*/

#include <metal_stdlib>
using namespace metal;

// Compute kernel
kernel void rosyEffect(texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
					   texture2d<half, access::write> outputTexture [[ texture(1) ]],
					   uint2 gid [[thread_position_in_grid]])
{
	// Make sure we don't read or write outside of the texture
	if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) {
		return;
	}
	
	half4 inputColor = inputTexture.read(gid);
	
	// Set the output color to the input color minus the green component
	half4 outputColor = half4(inputColor.r, 0.0, inputColor.b, 1.0);
	
	outputTexture.write(outputColor, gid);
}

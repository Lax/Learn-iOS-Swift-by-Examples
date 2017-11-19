/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands.
#import "ShaderTypes.h"

// Vertex shader outputs and fragmentShader inputs.
typedef struct {
	// The [[position]] attribute qualifier of this member indicates this value is the clip space
	//   position of the vertex wen this structure is returned from the
	float4 clipSpacePosition [[position]];
	
	// Since this member does not have a special attribute qualifier, the rasterizer will
	//   interpolate its value with values of other vertices making up the triangle and
	//   pass that interpolated value to the fragment shader for each fragment in that triangle
	float4 texcoord;
	
} RasterizrData;

// Vertex Function
vertex RasterizrData
vertexShader(uint vertexID [[ vertex_id ]],
			 constant Vertex *vertexArray [[ buffer(BufferIndexVertices) ]],
			 constant vector_float2 *viewportSizePointer  [[ buffer(BufferIndexViewportSize) ]]) {
	RasterizrData out;
	
	// Index into our array of positions to get the current vertex
	//   Our positons are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
	//   the origin)
	float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
	
	// Get the size of the drawable so that we can convert to normalized device cooridnates,
	vector_float2 viewportSize = vector_float2(*viewportSizePointer);

	
	// THe output position of every vertex shader is in clip space (also known as normalized device
	//   coordinate space, or NDC).   A value of (-1.0, -1.0) in clip-space represents the
	//   lower-left corner of the viewport wheras (1.0, 1.0) represents the upper-right corner of
	//   the viewport.
	
	// In order to convert from positons in pixel space to positons in clip space we divice the
	//   pixel coordinates by the size of the viewport,
	out.clipSpacePosition.xy = pixelSpacePosition / viewportSize;
	
	// Set the z component of our clip space position 0 (since we're only rendering in
	//   2-Dimensions for this sample)
	out.clipSpacePosition.z = 0.0;
	
	// Set the w component to 1.0 since we don't need a perspective divide, which is also not
	//   necessary when rendering in 2-Dimensions
	out.clipSpacePosition.w = 1.0;
	
	// Pass our texture coord straight to our output texcoord.
	out.texcoord = vertexArray[vertexID].texcoord;
	
	return out;
}

// Fragment functions

fragment float4 triangleFragmentShader(constant vector_float4 *color [[ buffer(BufferIndexColor) ]]) {
	// We return the color we just set which will be written to our color attachment.
	return *color;
}

fragment half4 backgroundFragmentShader(RasterizrData in [[stage_in]],
										texture2d<half> colorMap [[ texture(TextureIndexColor) ]]) {
	constexpr sampler linearSampler(mip_filter::linear,
									mag_filter::linear,
									min_filter::linear);
	
	return colorMap.sample(linearSampler, in.texcoord.xy);
}



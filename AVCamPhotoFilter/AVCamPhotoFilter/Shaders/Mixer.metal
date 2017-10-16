/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Shader that blends two input textures.
*/

#include <metal_stdlib>
using namespace metal;

struct VertexIO
{
    float4 position [[position]];
    float2 textureCoord [[user(texturecoord)]];
};

struct mixerParameters
{
    float mixFactor;
};

vertex VertexIO vertexMixer(device float2 *pPosition [[ buffer(0) ]],
                                  uint index               [[ vertex_id ]])
{
    VertexIO outVertex;

    outVertex.position.xy  = pPosition[index];
    outVertex.position.z = 0;
    outVertex.position.w = 1.0;
	
	// Convert texture position to texture coordinates
    outVertex.textureCoord.xy = 0.5 + float2(0.5, -0.5) * outVertex.position.xy;

    return outVertex;
}

fragment half4 fragmentMixer(VertexIO         inputFragment    [[ stage_in ]],
                              texture2d<half> mixerInput0      [[ texture(0) ]],
                              texture2d<half> mixerInput1      [[ texture(1) ]],
                              const device    mixerParameters& mixerParameters [[ buffer(0) ]],
                              sampler         samplr           [[ sampler(0) ]])
{
    half4 input0 = mixerInput0.sample(samplr, inputFragment.textureCoord);
    half4 input1 = mixerInput1.sample(samplr, inputFragment.textureCoord);
	
	half4 output = mix(input0, input1, half(mixerParameters.mixFactor));

    return output;
}

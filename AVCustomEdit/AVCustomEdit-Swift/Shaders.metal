/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The vertex and fragment shaders.
 */

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

/*
 Vertex input/output structure for passing results
 from a vertex shader to a fragment shader.
*/
struct VertexInOut
{
    float4 position [[position]];
    float4 color;
    float2 texCoord [[user(texturecoord)]];
};

// Vertex shader for a textured quad.
vertex VertexInOut passthroughVertexShader(uint vid [[ vertex_id ]],
                                           constant float4* position [[ buffer(0) ]],
                                           constant packed_float4* color [[ buffer(1) ]],
                                           constant packed_float2* pTexCoords [[ buffer(2) ]])
{
    VertexInOut outVertex;

    // Copy the vertex, texture and color coordinates.
    outVertex.position =  position[vid];
    outVertex.color    =  color[vid];
    outVertex.texCoord =  pTexCoords[vid];
    
    return outVertex;
};

vertex VertexInOut vertexShader_DiagonalWipe(uint vid [[ vertex_id ]],
                                            constant float4* position [[ buffer(0) ]],
                                            constant packed_float4* color [[ buffer(1) ]],
                                            constant packed_float2* pTexCoords [[ buffer(2) ]])
{
    VertexInOut outVertex;

    outVertex.position =  position[vid];
    outVertex.color    =  color[vid];

    /*
     Invert the y texture coordinate -- this is a simple modification to prevent the frame 
     from being flipped while using the same algorithm from the ObjC/OpenGL target 
     'quadVertexCoordinates' function (see APLDiagonalWipeRenderer.m) to compute the vertex 
     data for the foreground frame.
    */
    outVertex.texCoord = pTexCoords[vid];
    outVertex.texCoord.y = 1.0 - outVertex.texCoord.y;

    return outVertex;
}

// Fragment shader for a textured quad.
fragment half4 texturedQuadFragmentShader(VertexInOut inFrag [[ stage_in ]],
                                          texture2d<half> tex2D [[ texture(0) ]])
{
    constexpr sampler quad_sampler;
    
    // Sample the texture to get the surface color at this point.
    half4 color = tex2D.sample(quad_sampler, inFrag.texCoord);
    
    return color;
}

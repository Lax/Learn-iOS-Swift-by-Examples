/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and C/ObjC/Swift sources.
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h> // for vector_float4

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls.
typedef enum BufferIndices
{
	BufferIndexVertices     = 0,
	BufferIndexViewportSize = 1,
	BufferIndexColor        = 2,
} VertexInputIndex;

// Structure defining the layout of each vertex.  Shared between C code filling in the vertex data
//   and Metal vertex shader consuming the vertices.
typedef struct {
	vector_float4 position;
	vector_float4 texcoord;
} Vertex;

// Texture index values shared between shader and C code to ensure Metal shader texture indices
//   match indices of Metal API texture set calls.
typedef enum TextureIndices {
	TextureIndexColor = 0,
} TextureIndices;

#endif /* ShaderTypes_h */

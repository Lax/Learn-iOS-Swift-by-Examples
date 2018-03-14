#include <simd/simd.h>

struct ObjectData
{
	matrix_float4x4 LocalToWorld;
	vector_float4 color;
	vector_float4 pad0;
	vector_float4 pad01;
	vector_float4 pad02;
	matrix_float4x4 pad1;
	matrix_float4x4 pad2;
	
};

struct ShadowPass
{
	matrix_float4x4 ViewProjection;
	matrix_float4x4 pad1;
	matrix_float4x4 pad2;
	matrix_float4x4 pad3;
};

struct MainPass
{
	matrix_float4x4 ViewProjection;
	matrix_float4x4 ViewShadow0Projection;
	vector_float4	LightPosition;
	vector_float4	pad00;
	vector_float4	pad01;
	vector_float4	pad02;
	matrix_float4x4 pad1;
};

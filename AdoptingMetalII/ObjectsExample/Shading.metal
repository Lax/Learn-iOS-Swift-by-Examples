#include <metal_stdlib>
#include "SharedObjectsBridge.h"
using namespace metal;

struct Vertex
{
	packed_float3 position;
	packed_float3 normal;
};

struct PlaneVertex
{
	float4 position;
};

struct Varyings
{
	float4 position [[position]];
	float4 shadow0Position;
};

struct LitVaryings
{
	float4 position [[position]];
	float4 shadow0Position;
	float3 worldSpacePosition;
	float3 worldSpaceNormal;
};


struct PlaneVaryings
{
	float4 position [[position]];
	float4 shadow0Position;
	float4 worldPosition;
};

vertex Varyings vertex_main(device Vertex* verts [[buffer(0)]],
						  constant ObjectData& data [[buffer(1)]],
						  constant MainPass&  frame_constants [[buffer(2)]],
						  uint vid [[vertex_id]])
{
	Varyings out;
	
	float4 worldPosition = data.LocalToWorld * float4(verts[vid].position, 1.0);
	out.position = frame_constants.ViewProjection * worldPosition;
	out.shadow0Position = frame_constants.ViewShadow0Projection * worldPosition;
	
	return out;
}

vertex LitVaryings lit_vertex(device Vertex* verts [[buffer(0)]],
							constant ObjectData& data [[buffer(1)]],
							constant MainPass&  frame_constants [[buffer(2)]],
							uint vid [[vertex_id]])
{
	LitVaryings out;
	
	float4 worldPosition = data.LocalToWorld * float4(verts[vid].position, 1.0);
	
	//We have an orthonormal transform so we can cheat and use the LocalToWorld matrix to transform the normal
	//Manually setting w to 0 effectively makes this just a rotation
	float4 normal = data.LocalToWorld * float4(verts[vid].normal, 0.0);
	
	out.worldSpacePosition = worldPosition.xyz;
	out.position = frame_constants.ViewProjection * worldPosition;
	out.shadow0Position = frame_constants.ViewShadow0Projection * worldPosition;
	out.worldSpaceNormal = normalize(normal.xyz);
	
	return out;
}

fragment float4 unshaded_fragment(Varyings input [[stage_in]],
									  constant ObjectData& data [[buffer(1)]])
{
	return data.color;
}

fragment float4 lit_fragment(LitVaryings input [[stage_in]],
							 constant ObjectData& data [[buffer(1)]],
							 constant MainPass& frame_constants [[buffer(2)]])
{
	float3 L = normalize(frame_constants.LightPosition.xyz);
	float attenuation = clamp(dot(normalize(input.worldSpaceNormal), L), 0.3, 1.0);
	float3 color = data.color.xyz*attenuation;
	return float4(color, 1.0);
}

fragment float4 lit_shadowed_fragment(LitVaryings input [[stage_in]],
							 constant ObjectData& data [[buffer(1)]],
							 constant MainPass& frame_constants [[buffer(2)]],
							  depth2d<float> shadow [[texture(0)]])
{
	constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
	
	float4 shadowSpacePosition = input.shadow0Position;
	
	shadowSpacePosition.xy = shadowSpacePosition.xy * 0.5 + 0.5;
	shadowSpacePosition.y = 1.0 - shadowSpacePosition.y;
	
	float4 shadow_depth = shadow.sample(s, shadowSpacePosition.xy);
	
	float3 L = normalize(frame_constants.LightPosition.xyz);
	float attenuation = clamp(dot(normalize(input.worldSpaceNormal), L), 0.3, 1.0);
	float3 c = data.color.xyz*attenuation;
	
	if(shadow_depth.x <= shadowSpacePosition.z - 0.001)
	{
		c.xyz *= 0.5;
	}
	
	return float4(c, 1.0);
}

fragment float4 unshaded_shadowed_fragment(Varyings input [[stage_in]],
											   constant ObjectData& data [[buffer(1)]],
											   constant MainPass&  frame_constants [[buffer(2)]],
											   depth2d<float> shadow [[texture(0)]])
{
	constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
	
	float4 shadowSpacePosition = input.shadow0Position;
	
	shadowSpacePosition.xy = shadowSpacePosition.xy * 0.5 + 0.5;
	shadowSpacePosition.y = 1.0 - shadowSpacePosition.y;
	
	float4 shadow_depth = shadow.sample(s, shadowSpacePosition.xy);
	
	float4 c = data.color;
	
	if(shadow_depth.x <= shadowSpacePosition.z - 0.001)
	{
		c.xyz *= 0.5;
	}

	return c;
}

vertex PlaneVaryings plane_vertex(device PlaneVertex* verts [[buffer(0)]],
							constant ObjectData& data [[buffer(1)]],
							constant MainPass&  frame_constants [[buffer(2)]],
							uint vid [[vertex_id]])
{
	PlaneVaryings out;
	
	out.worldPosition = data.LocalToWorld * verts[vid].position;
	out.position = frame_constants.ViewProjection * out.worldPosition;
	out.shadow0Position = frame_constants.ViewShadow0Projection * out.worldPosition;
	
	return out;
}

fragment float4 plane_fragment(PlaneVaryings input [[stage_in]],
										   constant ObjectData& data [[buffer(1)]],
										   constant MainPass&  frame_constants [[buffer(2)]],
										   depth2d<float> shadow [[texture(0)]])
{
	constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
	
	float4 shadowSpacePosition = input.shadow0Position;
	
	shadowSpacePosition.xy = shadowSpacePosition.xy * 0.5 + 0.5;
	shadowSpacePosition.y = 1.0 - shadowSpacePosition.y;
	
	float4 shadow_depth = shadow.sample(s, shadowSpacePosition.xy);
	
	/*
		Draw grid lines.
	 
		fract() will give us the fractional part of the world space position.
		Using this directly would give us a very dense grid (the view is over hundreds of units here)
	 
		So we scale the worldspace coordinate to give us a less dense grid.
		We subtract 0.25 to fudge the line a bit and take abs
		This basically approaches the line from both sides

		We scale by fwidth - abs(ddx(value) + ddy(value))
		Stuff that's far away will have rapidly changing worldspace values per pixel and this
		gives us a scale factor to smooth out those areas
	 
		We use smoothstep to define if we are on the gridline or not. This gives us a nice antialiased line. 
		If we are on the line in either dimension one of these will be 0, so we use min() to detect. 
		This effectively creates a mask.
	 
		Then we modulate the color by this mask.
	 */
	float2 coordinate = input.worldPosition.xz;
	float2 grid = abs(fract(coordinate*1.0/50.0)-0.25) / fwidth(coordinate);
	
	grid = smoothstep(0.0, 0.02, grid);
	
	float isLine = min(grid.x, grid.y);
	
	float4 c = data.color*isLine;
	
	if(shadow_depth.x <= shadowSpacePosition.z - 0.001)
	{
		c.xyz *= 0.25;
	}
	
	return c;
}

struct ZPassVaryings
{
	float4 position [[position]];
};

vertex ZPassVaryings zpass_vertex_main(device Vertex* verts [[buffer(0)]],
							constant ObjectData& data [[buffer(1)]],
							constant ShadowPass&  frame_constants [[buffer(2)]],
							uint vid [[vertex_id]])
{
	ZPassVaryings out;
	
	float4 worldPosition = data.LocalToWorld * float4(verts[vid].position, 1.0);
	out.position = frame_constants.ViewProjection * worldPosition;
	
	return out;
}

fragment float4 zpass_fragment()
{
	return float4(1.0);
}

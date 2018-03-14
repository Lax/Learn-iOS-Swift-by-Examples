/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Top level utility functions.
 */


import Foundation
import Metal

class Camera
{
	var m : matrix_float4x4 = matrix_identity_float4x4
	
	var position : vector_float3
	{
		didSet {
			_needsMatrixUpdate = true
		}
	}
	
	
	fileprivate var _needsMatrixUpdate : Bool = true
	fileprivate var _direction : vector_float3
	var direction : vector_float3
	{
		set { _direction = vector_normalize(newValue); _needsMatrixUpdate = true }
		get { return _direction }
	}
	
	fileprivate var _up : vector_float3
	var up : vector_float3
	{
		set { _up = vector_normalize(newValue); _needsMatrixUpdate = true }
		get { return _up }
	}
	
	init()
	{
		position = float3(0.0)
		_direction = float3(0.0)
		_up = float3(0.0)
	}
	
	func GetViewMatrix() -> matrix_float4x4
	{
		if(_needsMatrixUpdate)
		{
			m = matrix_float4x4()
			var right = crossProduct(up, b: direction)
		
			m.columns.0 = float4(right.x, right.y, right.z, 0.0)
			m.columns.1 = float4(up.x, up.y, up.z, 0.0)
			m.columns.2 = float4(direction.x, direction.y, direction.z, 0.0)
			m.columns.3 = float4(position.x, position.y, position.z, 1.0)
			m = matrix_invert(m)
			
			_needsMatrixUpdate = false
		}
		
		return m
	}
};

func getPerpectiveProjectionMatrix(_ FieldOfView : Float, aspectRatio : Float, zFar : Float, zNear : Float) -> matrix_float4x4
{
	var m : matrix_float4x4 = matrix_float4x4()
	
	let f : Float = 1.0 / tan(FieldOfView / 2.0)
	
	m.columns.0.x = f / aspectRatio
	m.columns.1.y = f
	
	m.columns.2.z = zFar / (zFar - zNear)
	m.columns.2.w = 1.0
	
	m.columns.3.z = -(zNear*zFar)/(zFar-zNear)
	
	return m
}

func getLHOrthoMatrix(_ width : Float, height : Float, zFar : Float, zNear : Float) -> matrix_float4x4
{
	var m = matrix_float4x4()
	
	m.columns.0.x = 2.0 / width
	
	m.columns.1.y = 2.0 / height
	
	m.columns.2.z = 1.0 / (zFar-zNear)
	
	m.columns.3.z = -zNear / (zFar-zNear)
	m.columns.3.w = 1.0
	
	return m
}

func createPlane(_ device : MTLDevice) -> (MTLBuffer, Int)
{
	var verts : [CFloat] = [ -1000.5, 0.0,  1000.5, 1.0,
							  1000.5, 0.0,  1000.5, 1.0,
							 -1000.5, 0.0, -1000.5, 1.0,
							  1000.5, 0.0,  1000.5, 1.0,
							  1000.5, 0.0, -1000.5, 1.0,
							 -1000.5, 0.0, -1000.5, 1.0,]
    
    let length = verts.count*MemoryLayout<CFloat>.size
	
    let geoBuffer = device.makeBuffer(length: length, options: MTLResourceOptions.storageModeManaged)

    let geoPtr = geoBuffer.contents().bindMemory(to: CFloat.self, capacity: length)
    
	geoPtr.assign(from: &verts, count: verts.count)
	geoBuffer.didModifyRange(NSMakeRange(0, verts.count*MemoryLayout<Float>.size))
	
	return (geoBuffer, verts.count / 4)
}

func createCube(_ device : MTLDevice) -> (MTLBuffer, MTLBuffer?, Int, Int)
{
	var verts : [CFloat] = [-0.5,  0.5, -0.5, 0.0, 0.0, -1.0,//0
							 0.5,  0.5, -0.5, 0.0, 0.0, -1.0,//1
							 0.5, -0.5, -0.5, 0.0, 0.0, -1.0,//2
							 0.5, -0.5, -0.5, 0.0, 0.0, -1.0,//2
							-0.5, -0.5, -0.5, 0.0, 0.0, -1.0,//3
							-0.5,  0.5, -0.5, 0.0, 0.0, -1.0,//0
		
		0.5,  0.5, -0.5, 1.0,0.0,0.0, //1
		0.5,  0.5,  0.5, 1.0,0.0,0.0, //5
		0.5, -0.5,  0.5, 1.0,0.0,0.0, //6
		0.5, -0.5,  0.5, 1.0,0.0,0.0, //6
		0.5, -0.5, -0.5, 1.0,0.0,0.0, //2
		0.5,  0.5, -0.5, 1.0,0.0,0.0, //1
		
		 0.5,  0.5,  0.5, 0.0,0.0,1.0, //5
		-0.5,  0.5,  0.5, 0.0,0.0,1.0, //4
		-0.5, -0.5,  0.5, 0.0,0.0,1.0, //7
		-0.5, -0.5,  0.5, 0.0,0.0,1.0, //7
		 0.5, -0.5,  0.5, 0.0,0.0,1.0, //6
		 0.5,  0.5,  0.5, 0.0,0.0,1.0, //5
		
		-0.5,  0.5,  0.5, -1.0,0.0,0.0, //4
		-0.5,  0.5, -0.5, -1.0,0.0,0.0, //0
		-0.5, -0.5, -0.5, -1.0,0.0,0.0, //3
		-0.5, -0.5, -0.5, -1.0,0.0,0.0, //3
		-0.5, -0.5,  0.5, -1.0,0.0,0.0, //7
		-0.5,  0.5,  0.5, -1.0,0.0,0.0, //4
		
		-0.5,  0.5,  0.5, 0.0,1.0,0.0,//4
		 0.5,  0.5,  0.5, 0.0,1.0,0.0, //5
		 0.5,  0.5, -0.5, 0.0,1.0,0.0, //1
		 0.5,  0.5, -0.5, 0.0,1.0,0.0, //1
		-0.5,  0.5, -0.5, 0.0,1.0,0.0, //0
		-0.5,  0.5,  0.5, 0.0,1.0,0.0, //4
		
		-0.5, -0.5, -0.5, 0.0,-1.0,0.0, //3
		 0.5, -0.5, -0.5, 0.0,-1.0,0.0, //2
		 0.5, -0.5,  0.5, 0.0,-1.0,0.0, //6
		 0.5, -0.5,  0.5, 0.0,-1.0,0.0, //6
		-0.5, -0.5,  0.5, 0.0,-1.0,0.0, //7
		-0.5, -0.5, -0.5, 0.0,-1.0,0.0, //3
									]
    
    let length = verts.count*MemoryLayout<CFloat>.size
	let geoBuffer = device.makeBuffer(length: length, options: MTLResourceOptions.storageModeManaged)
    
    let geoPtr = geoBuffer.contents().bindMemory(to: CFloat.self, capacity: length)
    
	geoPtr.assign(from: &verts, count: verts.count)
	geoBuffer.didModifyRange(NSMakeRange(0, verts.count*MemoryLayout<Float>.size))
	
	return (geoBuffer, nil, 0, verts.count/6)
}

func getRotationAroundZ(_ radians : Float) -> matrix_float4x4
{
	var m : matrix_float4x4 = matrix_identity_float4x4;
	
	m.columns.0.x = cos(radians);
	m.columns.0.y = sin(radians);
	
	m.columns.1.x = -sin(radians);
	m.columns.1.y = cos(radians);
	
	return m;
}

func getRotationAroundY(_ radians : Float) -> matrix_float4x4
{
	var m : matrix_float4x4 = matrix_identity_float4x4;
	
	m.columns.0.x =  cos(radians);
	m.columns.0.z = -sin(radians);
	
	m.columns.2.x = sin(radians);
	m.columns.2.z = cos(radians);
	
	return m;
}

func getRotationAroundX(_ radians : Float) -> matrix_float4x4
{
	var m : matrix_float4x4 = matrix_identity_float4x4;
	
	m.columns.1.y = cos(radians);
	m.columns.1.z = sin(radians);
	
	m.columns.2.y = -sin(radians);
	m.columns.2.z =  cos(radians);
	
	return m;
}

func getTranslationMatrix(_ translation : vector_float4) -> matrix_float4x4
{
	var m : matrix_float4x4 = matrix_identity_float4x4
	
	m.columns.3 = translation
	
	return m
}

func getScaleMatrix(_ x : Float, y : Float, z : Float) -> matrix_float4x4
{
	var m = matrix_identity_float4x4
	
	m.columns.0.x = x
	m.columns.1.y = y
	m.columns.2.z = z
	
	return m
}

//Returns a value from -max to max
func getRandomValue(_ max : Double) -> Double
{
	let r : Int32 = Int32(Int64(arc4random()) - Int64(RAND_MAX))
	let v = (Double(r) / Double(RAND_MAX)) * max
	
	return v
}

func crossProduct(_ a : vector_float3, b : vector_float3) -> vector_float3
{
	var r : vector_float3 = vector_float3()
	
	r.x = a.y*b.z - a.z*b.y
	r.y = a.z*b.x - a.x*b.z
	r.z = a.x*b.y - a.y*b.x
	
	return r
}

/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main view.
 */


import Cocoa
import Metal
import MetalKit
import Dispatch

import Carbon.HIToolbox.Events

let DEG2RAD = M_PI / 180.0

let SHADOW_DIMENSION = 2048

let MAX_FRAMES_IN_FLIGHT : Int = 3

let SHADOW_PASS_COUNT : Int = 1
let MAIN_PASS_COUNT : Int = 1
let OBJECT_COUNT : Int = 200000

let START_POSITION = float3(0.0, 0.0, -325.0)

let START_CAMERA_VIEW_DIR = float3(0.0, 0.0, 1.0)
let START_CAMERA_UP_DIR = float3(0.0, 1.0, 0.0)

let GROUND_POSITION = float3(0.0, -250.0, 0.0)
let GROUND_COLOR = float4(1.0)

let SHADOWED_DIRECTIONAL_LIGHT_DIRECTION = float3(0.0, -1.0, 0.0)
let SHADOWED_DIRECTIONAL_LIGHT_UP = float3(0.0, 0.0, 1.0)
let SHADOWED_DIRECTIONAL_LIGHT_POSITION = float3(0.0, 225.0, 0.0)

let CONSTANT_BUFFER_SIZE : Int = OBJECT_COUNT * MemoryLayout<ObjectData>.size + SHADOW_PASS_COUNT * MemoryLayout<ShadowPass>.size + MAIN_PASS_COUNT * MemoryLayout<MainPass>.size

class MetalView : MTKView
{
	@IBOutlet weak var lightingLabel : NSTextField?
	@IBOutlet weak var cubeShadowLabel : NSTextField?
	@IBOutlet weak var mtLabel : NSTextField?
	@IBOutlet weak var multithreadUpdateLabel : NSTextField?
	@IBOutlet weak var frameEncodingTimeField : NSTextField?
	@IBOutlet weak var drawCountField : NSTextField?
	
	let mainRPDesc = MTLRenderPassDescriptor()
	
	var shadowRPs : Array<MTLRenderPassDescriptor> = [MTLRenderPassDescriptor]()
	
	var shadowMap : MTLTexture?

	var mainPassDepthTexture : MTLTexture?
	var mainPassFramebuffer : MTLTexture?
	
	var depthTestLess : MTLDepthStencilState?
	var depthTestAlways : MTLDepthStencilState?
	
	// The Metal queue that we will dispatch gpu work to
	var metalQueue : MTLCommandQueue?
	
	var semaphore : DispatchSemaphore
	var dispatchQueue : DispatchQueue
	
	// Contains all our objects and metadata about them
	// We aren't doing any culling so that means we'll be drawing everything every frame
	var renderables : ContiguousArray<RenderableObject> = ContiguousArray<RenderableObject>()
	var groundPlane : StaticRenderableObject?
	
	// Constant buffer ring
	var constantBuffers : Array<MTLBuffer> = [MTLBuffer] ()
	var constantBufferSlot : Int = 0
	var frameCounter : UInt = 1
	
	// View and shadow cameras
	var camera  = Camera()
	var shadowCameras : Array<Camera> = [Camera]()
	
	// Controls
	var moveForward = false
	var moveBackward = false
	var moveLeft = false
	var moveRight = false
	
	var orbit = float2()
	var cameraAngles = float2()
	
	var mouseDown = false
	
	var mouseDownPoint = NSPoint.zero
	
	var drawLighting = true
	var drawShadowsOnCubes = false
	var multithreadedUpdate = false
	var multithreadedRender = false
	var objectsToRender = 10000
	
	// Render modes
	var depthTest = true
	var showDepthAndShadow = false
	
	// Per-pass constant data. View/projection matrices, etc
	var mainPassView = matrix_float4x4()
	var mainPassProjection = matrix_float4x4()
	var mainPassFrameData = MainPass()
	
	var shadowPassData = [ShadowPass]()
	
	// Our pipelines
	var unshadedPipeline: MTLRenderPipelineState?
	var unshadedShadowedPipeline: MTLRenderPipelineState?
	
	var litPipeline: MTLRenderPipelineState?
	var litShadowedPipeline: MTLRenderPipelineState?
	
	var planeRenderPipeline: MTLRenderPipelineState?
	var zpassPipeline: MTLRenderPipelineState?
	
	var quadVisPipeline: MTLRenderPipelineState?
	var depthVisPipeline: MTLRenderPipelineState?
	var texQuadVisPipeline: MTLRenderPipelineState?
	
	// Timing
	var machToMilliseconds: Double = 0.0
	var runningAverageGPU: Double = 0.0
	var runningAverageCPU: Double = 0.0
	
	var gpuTiming = [UInt64]()
	
	required init(coder: NSCoder) {
		semaphore = DispatchSemaphore(value: MAX_FRAMES_IN_FLIGHT)
		dispatchQueue = DispatchQueue(label: "default queue", attributes: [.concurrent])
		
		mainRPDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
		mainRPDesc.colorAttachments[0].loadAction = .clear
		mainRPDesc.colorAttachments[0].storeAction = .store
		
		mainRPDesc.depthAttachment.clearDepth = 1.0
		mainRPDesc.depthAttachment.loadAction = .clear
		mainRPDesc.depthAttachment.storeAction = .dontCare

		mainPassView = matrix_identity_float4x4
		mainPassProjection = matrix_identity_float4x4
		
		mainPassFrameData.ViewProjection = matrix_multiply(mainPassProjection, mainPassView)

		camera.position = START_POSITION
		camera.direction = START_CAMERA_VIEW_DIR
		camera.up = START_CAMERA_UP_DIR
		
		// Set up shadow camera and data
		do
		{
			let c = Camera()
			
			c.direction = SHADOWED_DIRECTIONAL_LIGHT_DIRECTION
			c.up = SHADOWED_DIRECTIONAL_LIGHT_UP
			c.position = SHADOWED_DIRECTIONAL_LIGHT_POSITION
			
			shadowCameras.append(c)
			
			shadowPassData.append(ShadowPass())
		}
		
		var timebase : mach_timebase_info_data_t = mach_timebase_info_data_t()
		mach_timebase_info(&timebase)
		
		machToMilliseconds = Double(timebase.numer) / Double(timebase.denom) * 1e-6
		
		//add 3
		gpuTiming.append(0)
		gpuTiming.append(0)
		gpuTiming.append(0)
		
		super.init(coder: coder)
	}
	
	func createPipelines() {
		let lib = device!.newDefaultLibrary()!
		
		do {
			// Shaders for lighting/shadowing
			let vertexFunction = lib.makeFunction(name: "vertex_main")
			let unshadedFragment = lib.makeFunction(name: "unshaded_fragment")
			let unshadedShadowedFragment = lib.makeFunction(name: "unshaded_shadowed_fragment")
			let planeVertex = lib.makeFunction(name: "plane_vertex")
			let planeFragment = lib.makeFunction(name: "plane_fragment")
			
			let pipeDesc = MTLRenderPipelineDescriptor()
			pipeDesc.vertexFunction = vertexFunction
			pipeDesc.fragmentFunction = unshadedFragment
			pipeDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
			pipeDesc.depthAttachmentPixelFormat = .depth32Float
			
			try unshadedPipeline = device!.makeRenderPipelineState(descriptor: pipeDesc)
			
			pipeDesc.fragmentFunction = unshadedShadowedFragment
			try unshadedShadowedPipeline = device!.makeRenderPipelineState(descriptor: pipeDesc)
			
			let litVertexFunction = lib.makeFunction(name: "lit_vertex")
			let litFragmentFunction = lib.makeFunction(name: "lit_fragment")
			let litShadowedFragment = lib.makeFunction(name: "lit_shadowed_fragment")
			
			// Rendering with simple lighting
			pipeDesc.vertexFunction = litVertexFunction
			pipeDesc.fragmentFunction = litFragmentFunction
			
			try litPipeline = device!.makeRenderPipelineState(descriptor: pipeDesc)
			
			pipeDesc.fragmentFunction = litShadowedFragment
			
			try litShadowedPipeline = device!.makeRenderPipelineState(descriptor: pipeDesc)
			
			// Ground plane
			
			pipeDesc.vertexFunction = planeVertex
			pipeDesc.fragmentFunction = planeFragment
			try planeRenderPipeline = device!.makeRenderPipelineState(descriptor: pipeDesc)
			
			// Shadow pass
			
			let zpassVertex = lib.makeFunction(name: "zpass_vertex_main")
			let zpassFragment = lib.makeFunction(name: "zpass_fragment")
			
			//Z only passes do not need to write color
			pipeDesc.vertexFunction = zpassVertex
			pipeDesc.fragmentFunction = zpassFragment
			pipeDesc.colorAttachments[0].pixelFormat = .invalid
			pipeDesc.colorAttachments[0].writeMask = MTLColorWriteMask()
			
			try zpassPipeline = device!.makeRenderPipelineState(descriptor: pipeDesc)
		}
		catch {
			fatalError("Could not create lighting shaders, failing. \(error)")
		}
		
		do {
			// Visualization shaders
			let vertexFunction = lib.makeFunction(name: "quad_vertex_main")
			let quadVisFragFunction = lib.makeFunction(name: "quad_fragment_main")
			let quadTexVisFunction = lib.makeFunction(name: "textured_quad_fragment")
			let quadDepthVisFunction = lib.makeFunction(name: "visualize_depth_fragment")
			
			let pipeDesc = MTLRenderPipelineDescriptor()
			pipeDesc.vertexFunction = vertexFunction
			pipeDesc.fragmentFunction = quadVisFragFunction
			pipeDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
			
			try quadVisPipeline = device!.makeRenderPipelineState(descriptor: pipeDesc)
			
			pipeDesc.fragmentFunction = quadDepthVisFunction
			try depthVisPipeline = device!.makeRenderPipelineState(descriptor: pipeDesc)
			
			pipeDesc.fragmentFunction = quadTexVisFunction
			try texQuadVisPipeline = device!.makeRenderPipelineState(descriptor: pipeDesc)
		}
		catch {
			Swift.print("Could not compile visualization shaders, failing.")
			exit(1)
		}
	}
	
	override func awakeFromNib() {
        super.awakeFromNib()
        
		drawCountField?.stringValue = "\(objectsToRender) draws"
		if multithreadedUpdate {
			multithreadUpdateLabel?.stringValue = "Multithreaded Update"
		}
		else {
			multithreadUpdateLabel?.stringValue = "Single Threaded Update"
		}
		
		if !multithreadedRender {
			mtLabel?.stringValue = "Single Threaded Encode"
		}
		else {
			mtLabel?.stringValue = "Multithreaded Encode"
		}
		
		let devices = MTLCopyAllDevices()
		for device in devices {
			if !device.isLowPower {
				self.device = device
			}
		}
		
		Swift.print(device!.name!)
		
		//MARK: Set up render targets in MTKView
		
		//this specifies the rendertarget the system will hand back
		colorPixelFormat = MTLPixelFormat.bgra8Unorm
		
		drawableSize.height = frame.height
		drawableSize.width = frame.width
		
		metalQueue = device!.makeCommandQueue()
		
		// MARK: Constant Buffer Creation
		// Create our constant buffers
		// We've chosen 3 for this example; your application may need a different number
		for _ in 1...MAX_FRAMES_IN_FLIGHT {
			let buf : MTLBuffer = device!.makeBuffer(length: CONSTANT_BUFFER_SIZE, options: MTLResourceOptions.storageModeManaged)
			constantBuffers.append(buf)
		}
		
		// MARK: Shadow Texture Creation
		do {
			let texDesc : MTLTextureDescriptor = MTLTextureDescriptor()
			texDesc.pixelFormat = MTLPixelFormat.depth32Float
			texDesc.width = SHADOW_DIMENSION
			texDesc.height = SHADOW_DIMENSION
			texDesc.depth = 1
			texDesc.textureType = MTLTextureType.type2D
			texDesc.usage = [MTLTextureUsage.renderTarget, MTLTextureUsage.shaderRead]
			texDesc.storageMode = .private
			
			shadowMap = device!.makeTexture(descriptor: texDesc)
		}
		
		// MARK: Main framebuffer / depth creation
		do {
			let texDesc = MTLTextureDescriptor()
			texDesc.width =  Int(frame.width)
			texDesc.height =  Int(frame.height)
			texDesc.depth = 1
			texDesc.textureType = MTLTextureType.type2D
			
			texDesc.usage = [MTLTextureUsage.renderTarget, MTLTextureUsage.shaderRead]
			texDesc.storageMode = .private
			texDesc.pixelFormat = .bgra8Unorm
			
			mainPassFramebuffer = device!.makeTexture(descriptor: texDesc)
			
			self.mainRPDesc.colorAttachments[0].texture = mainPassFramebuffer
		}
		
		do {
			let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float,
			                                                       width: Int(frame.width),
			                                                       height: Int(frame.height),
			                                                       mipmapped: false)
			texDesc.usage = [MTLTextureUsage.renderTarget, MTLTextureUsage.shaderRead]
			texDesc.storageMode = .private
			mainPassDepthTexture = device!.makeTexture(descriptor: texDesc)
			
			self.mainRPDesc.depthAttachment.texture = mainPassDepthTexture
		}
		
		do {
			let rp = MTLRenderPassDescriptor()
			rp.depthAttachment.clearDepth = 1.0
			rp.depthAttachment.texture = shadowMap
			rp.depthAttachment.loadAction = .clear
			rp.depthAttachment.storeAction = .store
			shadowRPs.append(rp)
		}
		
		// MARK: Depth State Creation
		
		do {
			let depthStencilDesc = MTLDepthStencilDescriptor()
			depthStencilDesc.isDepthWriteEnabled = true
			depthStencilDesc.depthCompareFunction = MTLCompareFunction.less
			
			depthTestLess = device!.makeDepthStencilState(descriptor: depthStencilDesc)
			
			depthStencilDesc.isDepthWriteEnabled = false
			depthStencilDesc.depthCompareFunction = MTLCompareFunction.always
			depthTestAlways = device!.makeDepthStencilState(descriptor: depthStencilDesc)
		}
		
		// MARK: Shader Creation
		
		createPipelines()
		
		// MARK: Object Creation
		do {
			let (geo, index, indexCount, vertCount) = createCube(device!)
			
			for _ in 0..<OBJECT_COUNT {
				//NOTE returns a value within -value to value
				let p = Float(getRandomValue(500.0))
				let p1 = Float(getRandomValue(100.0))
				let p2 = Float(getRandomValue(500.0))
				
				let cube = RenderableObject(m: geo, idx: index, count: indexCount, tex: nil)
				cube.position = float4(p, p1, p2, 1.0)
				cube.count = vertCount
				
				let r = Float(Float(drand48())) * 2.0
				let r1 = Float(Float(drand48())) * 2.0
				let r2 = Float(Float(drand48())) * 2.0
				
				cube.rotationRate = float3(r, r1, r2)
				
				let scale = Float(drand48()*5.0)
				
				cube.scale = float3(scale)
				
				cube.objectData.color = float4(Float(drand48()),
												 Float(drand48()),
												 Float(drand48()), 1.0)
				renderables.append(cube)
			}
		}
		
		do {
			let (planeGeo, count) = createPlane(device!)
			groundPlane = StaticRenderableObject(m: planeGeo, idx: nil, count: count, tex: nil)
			groundPlane!.position = float4(GROUND_POSITION.x,
			                               GROUND_POSITION.y,
			                               GROUND_POSITION.z,1.0)
			groundPlane!.objectData.color = GROUND_COLOR
			groundPlane!.objectData.LocalToWorld.columns.3 = groundPlane!.position
		}
		
		// Main pass projection matrix
		// Our window cannot change size so we don't ever update this
		mainPassProjection = getPerpectiveProjectionMatrix(Float(60.0*DEG2RAD), aspectRatio: Float(self.frame.width) / Float(self.frame.height), zFar: 2000.0, zNear: 1.0)
	}
	
	// Encodes a single shadow pass
	func encodeShadowPass(_ commandBuffer: MTLCommandBuffer, rp: MTLRenderPassDescriptor, constantBuffer: MTLBuffer, passDataOffset: Int, objectDataOffset: Int) {
		let enc = commandBuffer.makeRenderCommandEncoder(descriptor: rp)
		enc.setDepthStencilState(depthTestLess)
		
		//We're only going to draw back faces into the shadowmap
		enc.setCullMode(MTLCullMode.front)
		
		// setVertexOffset will allow faster updates, but we must bind the Constant buffer once
		enc.setVertexBuffer(constantBuffer, offset: 0, at: 1)
		// Bind the ShadowPass data once for all objects to see
		enc.setVertexBuffer(constantBuffer, offset: passDataOffset, at: 2)
		
		// We have one pipeline for all our objects, so only bind it once
		enc.setRenderPipelineState(zpassPipeline!)
		enc.setVertexBuffer(renderables[0].mesh, offset: 0, at: 0)
		
		var offset = objectDataOffset
		for index in 0..<objectsToRender {
			renderables[index].DrawZPass(enc, offset: offset)
			offset += MemoryLayout<ObjectData>.size
		}
		
		enc.endEncoding()
		
		commandBuffer.commit()
	}
	
	// A tiny bit more complex than DrawShadowPass
	// We must pick the current drawable from MTKView as well as calling present before
	// Committing our command buffer
	// We'll also add a completion handler to signal the semaphore
	
	func encodeMainPass(_ enc: MTLRenderCommandEncoder, constantBuffer: MTLBuffer, passDataOffset: Int, objectDataOffset: Int) {
		// Similar to the shadow passes, we must bind the constant buffer once before we call setVertexBytes
		enc.setVertexBuffer(constantBuffer, offset: 0, at: 1)
		enc.setFragmentBuffer(constantBuffer, offset: 0, at: 1)
        
		// Now bind the MainPass constants once
		enc.setVertexBuffer(constantBuffer, offset: passDataOffset, at: 2)
		enc.setFragmentBuffer(constantBuffer, offset: passDataOffset, at: 2)
		
		enc.setFragmentTexture(shadowMap, at: 0)
		
		var offset = objectDataOffset
		if drawShadowsOnCubes {
			if drawLighting {
				enc.setRenderPipelineState(litShadowedPipeline!)
			}
			else {
				enc.setRenderPipelineState(unshadedShadowedPipeline!)
			}
		}
		else {
			if drawLighting {
				enc.setRenderPipelineState(litPipeline!)
			}
			else {
				enc.setRenderPipelineState(unshadedPipeline!)
			}
		}
        
		enc.setVertexBuffer(renderables[0].mesh!, offset: 0, at: 0)
		for index in 0..<objectsToRender {
			renderables[index].Draw(enc, offset: offset)
			offset += MemoryLayout<ObjectData>.size
		}
		
		enc.setRenderPipelineState(planeRenderPipeline!)
		enc.setVertexBuffer(groundPlane!.mesh, offset: 0, at: 0)
		groundPlane!.Draw(enc, offset: offset)
	}
	
	func drawMainPass(_ mainCommandBuffer: MTLCommandBuffer, constantBuffer: MTLBuffer, mainPassOffset: Int, objectDataOffset: Int) {
		let currentFrame = frameCounter
		
		if showDepthAndShadow {
			mainRPDesc.depthAttachment.storeAction = .store
		}
		else {
			mainRPDesc.depthAttachment.storeAction = .dontCare
		}
		
		let enc : MTLRenderCommandEncoder = mainCommandBuffer.makeRenderCommandEncoder(descriptor: mainRPDesc)
		enc.setCullMode(MTLCullMode.back)
		
		if depthTest {
			enc.setDepthStencilState(depthTestLess)
		}
		
		encodeMainPass(enc, constantBuffer: constantBuffer, passDataOffset : mainPassOffset, objectDataOffset: objectDataOffset)
		
		enc.endEncoding()
		
		let currentDrawable = self.currentDrawable!
		let rpDesc = currentRenderPassDescriptor!
		
		// Draws the Scene, Depth and Shadow map to the screen
		if showDepthAndShadow {
			let visEnc = mainCommandBuffer.makeRenderCommandEncoder(descriptor: rpDesc)
			
			var viewport = MTLViewport(originX: 0.0, originY: 0.0,
			                           width: Double(frame.width)*0.5,
			                           height: Double(frame.height)*0.5,
			                           znear: 0.0, zfar: 1.0)
			
			visEnc.setViewport(viewport)
			
			visEnc.setRenderPipelineState(texQuadVisPipeline!)
			visEnc.setFragmentTexture(mainPassFramebuffer, at: 0)
			
			visEnc.drawPrimitives(type: MTLPrimitiveType.triangleStrip, vertexStart: 0, vertexCount: 4)
			
			viewport = MTLViewport(originX: Double(frame.width)*0.5, originY: 0.0,
			                       width: Double(frame.width)*0.5,
			                       height: Double(frame.height)*0.5,
			                       znear: 0.0, zfar: 1.0)
			
			visEnc.setViewport(viewport)
			
			visEnc.setRenderPipelineState(self.depthVisPipeline!)
			visEnc.setFragmentTexture(self.mainPassDepthTexture, at: 0)
			
			visEnc.drawPrimitives(type: MTLPrimitiveType.triangleStrip, vertexStart: 0, vertexCount: 4)
			
			// Shadow
			viewport = MTLViewport(originX: 0.0,
			                       originY: Double(frame.height)*0.5,
			                       width: Double(frame.width)*0.5,
			                       height: Double(frame.height)*0.5,
			                       znear: 0.0, zfar: 1.0)
			
			visEnc.setViewport(viewport)
			
			visEnc.setFragmentTexture(shadowMap, at: 0)
			visEnc.drawPrimitives(type: MTLPrimitiveType.triangleStrip, vertexStart: 0, vertexCount: 4)
			
			visEnc.endEncoding()
		}
		else {
			// Draws the main pass
			let finalEnc = mainCommandBuffer.makeRenderCommandEncoder(descriptor: rpDesc)
			
			finalEnc.setRenderPipelineState(texQuadVisPipeline!)
			finalEnc.setFragmentTexture(mainPassFramebuffer, at: 0)
			
			finalEnc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
			
			finalEnc.endEncoding()
		}
		
		mainCommandBuffer.present(currentDrawable)
		
		mainCommandBuffer.addScheduledHandler { scheduledCommandBuffer in
			self.gpuTiming[Int(currentFrame % 3)] = mach_absolute_time()
		}
		
		mainCommandBuffer.addCompletedHandler { completedCommandBuffer in
			
			let end = mach_absolute_time()
			self.gpuTiming[Int(currentFrame % 3)] = end - self.gpuTiming[Int(currentFrame % 3)]
			
			let seconds = self.machToMilliseconds * Double(self.gpuTiming[Int(currentFrame % 3)])
			
			self.runningAverageGPU = (self.runningAverageGPU * Double(currentFrame-1) + seconds) / Double(currentFrame)
			
			self.semaphore.signal()
		}
		
		mainCommandBuffer.commit()
	}
	
	override func draw(_ dirtyRect: NSRect) {
		// Synchronize frame rendering
		_ = semaphore.wait(timeout: DispatchTime.distantFuture)
		
		let currentFrame = frameCounter
		let currentConstantBuffer = constantBufferSlot
		
		// Update view matrix here
		if moveForward {
			camera.position.z += 1.0
		}
		else if moveBackward {
			camera.position.z -= 1.0
		}
		
		if mouseDown {
			cameraAngles.x += 0.005 * orbit.y
			cameraAngles.y += 0.005 * orbit.x
		}
		
		// Prepare Shadow Pass data
		// The shadow is cast by a directional light - an infinite distance away
		// This is a good fit for an orthographic projection
		// IMPORTANT NOTE:
		// The projection is hardcoded right now since our objects do not move.
		// What this SHOULD do is determine the bounds of all the objects that will be drawn into the shadowmap
		// and generate the smallest frustum possible

		do {
			// Figure out far plane distance at least
			let zFar = distance(GROUND_POSITION,SHADOWED_DIRECTIONAL_LIGHT_POSITION)
			
			shadowPassData[0].ViewProjection = getLHOrthoMatrix(1100, height: 1100, zFar: zFar, zNear: 25)
			shadowPassData[0].ViewProjection = matrix_multiply(shadowPassData[0].ViewProjection, shadowCameras[0].GetViewMatrix())
		}
		
		do {
			//NOTE: We're doing an orbit so we've usurped the normal camera class here
			mainPassView = matrix_multiply(getRotationAroundY(cameraAngles.y), getRotationAroundX(cameraAngles.x))
			mainPassView = matrix_multiply(camera.GetViewMatrix(), mainPassView)
			mainPassFrameData.ViewProjection = matrix_multiply(mainPassProjection, mainPassView)
			mainPassFrameData.ViewShadow0Projection = shadowPassData[0].ViewProjection
			mainPassFrameData.LightPosition = float4(SHADOWED_DIRECTIONAL_LIGHT_POSITION.x,
													SHADOWED_DIRECTIONAL_LIGHT_POSITION.y,
													SHADOWED_DIRECTIONAL_LIGHT_POSITION.z, 1.0)
		}
		
        // Select which constant buffer to use
        let constantBufferForFrame = constantBuffers[currentConstantBuffer]
        
        // Calculate the offsets into the constant buffer for the shadow pass data, main pass data, and object data
        let shadowOffset = 0
        let mainPassOffset = MemoryLayout<ShadowPass>.stride + shadowOffset
        let objectDataOffset = MemoryLayout<MainPass>.stride + mainPassOffset
        
        // Write the shadow pass data into the constants buffer
        constantBufferForFrame.contents().storeBytes(of: shadowPassData[0], toByteOffset: shadowOffset, as: ShadowPass.self)
        
        // Write the main pass data into the constants buffer
        constantBufferForFrame.contents().storeBytes(of: mainPassFrameData, toByteOffset: mainPassOffset, as: MainPass.self)
        
        // Create a mutable pointer to the beginning of the object data so we can step through it and set the data of each object individually
        var ptr = constantBufferForFrame.contents().advanced(by: objectDataOffset).bindMemory(to: ObjectData.self, capacity: objectsToRender)
        
        // Update position of all the objects
        if multithreadedUpdate {
            DispatchQueue.concurrentPerform(iterations: objectsToRender) { i in
                let thisPtr = ptr.advanced(by: i)
                _ = self.renderables[i].UpdateData(thisPtr, deltaTime: 1.0/60.0)
            }
        }
        else {
            for index in 0..<objectsToRender {
                ptr = renderables[index].UpdateData(ptr, deltaTime: 1.0/60.0)
            }
        }
        
        // Advance the object data pointer once more so we can write the data for the ground plane object
        ptr = ptr.advanced(by: objectsToRender)
        
        _ = groundPlane!.UpdateData(ptr, deltaTime: 1.0/60.0)
        
        // Mark constant buffer as modified (objectsToRender+1 because of the ground plane)
        constantBufferForFrame.didModifyRange(NSMakeRange(0, mainPassOffset+(MemoryLayout<ObjectData>.stride*(objectsToRender+1))))
		
		// Create command buffers for the entire scene rendering
		let shadowCommandBuffer : MTLCommandBuffer = metalQueue!.makeCommandBufferWithUnretainedReferences()
		let mainCommandBuffer : MTLCommandBuffer = metalQueue!.makeCommandBufferWithUnretainedReferences()
		
		// Enforce the ordering:
		// Shadows must be completed before the main rendering pass
		shadowCommandBuffer.enqueue()
		mainCommandBuffer.enqueue()
		
		// Time the encoding, not the data update
		let start = mach_absolute_time()
		
		let dispatchGroup = DispatchGroup()

		// Generate the command buffer for Shadowmap
		if multithreadedRender {
			dispatchGroup.enter()
			dispatchQueue.async {
				self.encodeShadowPass(shadowCommandBuffer, rp: self.shadowRPs[0], constantBuffer: constantBufferForFrame, passDataOffset: shadowOffset, objectDataOffset: objectDataOffset)
				dispatchGroup.leave()
			}
		}
		else {
			encodeShadowPass(shadowCommandBuffer, rp: self.shadowRPs[0], constantBuffer: constantBufferForFrame, passDataOffset: shadowOffset, objectDataOffset: objectDataOffset)
		}
		
		//MARK: Dispatch Main Render Pass
		if multithreadedRender {
			dispatchGroup.enter()
			dispatchQueue.async {
				self.drawMainPass(mainCommandBuffer, constantBuffer: constantBufferForFrame, mainPassOffset: mainPassOffset, objectDataOffset: objectDataOffset)
				dispatchGroup.leave()
			}
		}
		else {
			drawMainPass(mainCommandBuffer, constantBuffer: constantBufferForFrame, mainPassOffset: mainPassOffset, objectDataOffset: objectDataOffset)
		}

		if multithreadedRender {
			// At this point we have created and committed all our command buffers
			// Ordering was enforced by enqueue so there is no need to do anything extra
			
			// We rejoin here to ensure we aren't stomping any of our data.
			// We are also using unretained command buffers so this ensure no weirdness there.
			// You could certainly design this to just run through and let the semaphore handle throttling
			_ = dispatchGroup.wait(timeout: DispatchTime.distantFuture)
		}
		
		let end = mach_absolute_time()
		
		let delta = end - start
		
		let mseconds = machToMilliseconds*Double(delta)
		
		self.runningAverageCPU = (runningAverageCPU * Double(currentFrame-1) + mseconds) / Double(currentFrame)
		
		if frameCounter % 60 == 0 {
			frameEncodingTimeField?.stringValue = String.localizedStringWithFormat("%.3f ms", mseconds)
		}
		
		// Increment our constant buffer counter
		// This will wrap and the semaphore will make sure we aren't using a buffer that's already in flight
		constantBufferSlot = (constantBufferSlot + 1) % MAX_FRAMES_IN_FLIGHT
		frameCounter = frameCounter+1
	}
	
	func resetCamera() {
		camera.position = START_POSITION
		cameraAngles = float2(0.0, 0.0)
	}
	
	override var acceptsFirstResponder: Bool { return true }
	
	override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
		
		switch Int(event.keyCode)
		{
            case kVK_ANSI_W:
                moveForward = true
            
            case kVK_ANSI_A:
                moveLeft = true
            
            case kVK_ANSI_S:
                moveBackward = true
            
            case kVK_ANSI_D:
                moveRight = true
            
            case kVK_ANSI_3:
                drawLighting = !drawLighting
                if drawLighting {
                    lightingLabel?.stringValue = "Lambert Lighting"
                }
                else {
                    lightingLabel?.stringValue = "No Lighting"
                }
            
            case kVK_ANSI_4:
                drawShadowsOnCubes = !drawShadowsOnCubes
                if !drawShadowsOnCubes {
                    cubeShadowLabel?.stringValue = "Unshadowed Cubes"
                }
                else {
                    cubeShadowLabel?.stringValue = "Shadowed Cubes"
                }
            
            case kVK_ANSI_5:
                multithreadedUpdate = !multithreadedUpdate
            
            case kVK_ANSI_6:
                multithreadedRender = !multithreadedRender
                if !multithreadedRender {
                    mtLabel?.stringValue = "Single Threaded Encode"
                }
                else {
                    mtLabel?.stringValue = "Multithreaded Encode"
                }
            
            case kVK_ANSI_7:
                objectsToRender = max(objectsToRender/2, 10)
                drawCountField?.stringValue = "\(objectsToRender) draws"
            
            case kVK_ANSI_8:
                objectsToRender = min(objectsToRender*2,OBJECT_COUNT)
                drawCountField?.stringValue = "\(objectsToRender) draws"
            
            case kVK_ANSI_9:
                showDepthAndShadow = !showDepthAndShadow
                if showDepthAndShadow {
                    drawCountField?.isHidden = true
                    frameEncodingTimeField?.isHidden = true
                    mtLabel?.isHidden = true
                    multithreadUpdateLabel?.isHidden = true
                    cubeShadowLabel?.isHidden = true
                    lightingLabel?.isHidden = true
                }
                else {
                    drawCountField?.isHidden = false
                    frameEncodingTimeField?.isHidden = false
                    mtLabel?.isHidden = false
                    multithreadUpdateLabel?.isHidden = false
                    cubeShadowLabel?.isHidden = false
                    lightingLabel?.isHidden = false
                }
            
            default:
                break
		}
	}
	
	override func keyUp(with event: NSEvent) {
		switch Int(event.keyCode)
		{
            case kVK_ANSI_W:
                moveForward = false
            
            case kVK_ANSI_A:
                moveLeft = false
            
            case kVK_ANSI_S:
                moveBackward = false
            
            case kVK_ANSI_D:
                moveRight = false
            
            case kVK_Delete:
                resetCamera()
            
            default:
                break
		}
	}
	
	override func mouseDown(with event: NSEvent) {
		mouseDownPoint = event.locationInWindow
		mouseDown = true
	}
	
	override func mouseUp(with event: NSEvent) {
		mouseDown = false
	}
	
	override func mouseDragged(with event: NSEvent) {
        guard mouseDown else { return }

        let thePoint = event.locationInWindow
			
        orbit.x = Float(thePoint.x - mouseDownPoint.x)
        orbit.y = Float(thePoint.y - mouseDownPoint.y)
        
        mouseDownPoint = thePoint
	}
}

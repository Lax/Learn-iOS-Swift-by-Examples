/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 APLDiagonalWipeRenderer subclass of APLMetalRenderer, renders the given source buffers to perform a diagonal wipe over
  the time range of the transition.
 */

import Foundation
import CoreVideo
import MetalKit

/*
 RenderPixelBuffers is used to maintain a reference to the pixel buffer until the Metal rendering
 is complete. This is because when CVMetalTextureCacheCreateTextureFromImage is used to create a
 Metal texture (CVMetalTexture) from the IOSurface that backs the CVPixelBuffer, the
 CVMetalTextureCacheCreateTextureFromImage doesn't increment the use count of the IOSurface; only
 the CVPixelBuffer, and the CVMTLTexture own this IOSurface. Therefore we must maintain a reference
 to the pixel buffer until the Metal rendering is done.
 */
class RenderPixelBuffers {
    var foregroundTexture: CVPixelBuffer?
    var backgroundTexture: CVPixelBuffer?
    var destinationTexture: CVPixelBuffer?

    init(_ foregroundTexture: CVPixelBuffer, backgroundTexture: CVPixelBuffer, destinationTexture: CVPixelBuffer) {
        self.foregroundTexture = foregroundTexture
        self.backgroundTexture = backgroundTexture
        self.destinationTexture = destinationTexture
    }
}

class APLDiagonalWipeRenderer: APLMetalRenderer {

    /// Defines an x,y coordinate. Used in vertex coordinate calculations when performing the diagonal wipe.
    fileprivate struct Point {
        public var xCoord: Float
        public var yCoord: Float

        public init(xCoord: Float, yCoord: Float) {
            self.xCoord = xCoord
            self.yCoord = yCoord
        }
    }

    /// ID used to identify the foreground track during compositing.
    fileprivate let foregroundTrackID = 0
    /// ID used to identify the background track during compositing.
    fileprivate let backgroundTrackID = 1

    /// The endpoints of a line which partitions the frame on screen into two parts.
    fileprivate var diagonalEnd1: Point = Point(xCoord: 0, yCoord: 0)
    fileprivate var diagonalEnd2: Point = Point(xCoord: 0, yCoord: 0)

    /// A MTLRenderPipelineState object that contains compiled rendering state, including vertex and fragment shaders.
    fileprivate var renderPipelineState: MTLRenderPipelineState?

    /// MTLBuffer object used to maintain color data.
    fileprivate var colorBuffer: MTLBuffer?

    /// The colors for each vertex coordinate.
    fileprivate let colorArray: [Float] = [
        1, 0, 0, 1,
        0, 1, 0, 1,
        0, 0, 1, 1,
        1, 0, 0, 1,
        0, 0, 1, 1,
        1, 0, 1, 1
    ]

    /// The pixel buffers that contain references to the uncompressed movie frames.
    fileprivate var pixelBuffers: RenderPixelBuffers?

    override init?() {

        super.init()

        // The default library contains all of the shader functions that were compiled into our app bundle.
        guard let library = device.newDefaultLibrary() else { return nil }

        // Retrieve the functions that will comprise our pipeline.

        // Load the vertex program into the library.
        guard let vertexFunc = library.makeFunction(name: "vertexShader_DiagonalWipe") else { return nil }

        // Load the fragment program into the library.
        guard let fragmentFunc = library.makeFunction(name: "texturedQuadFragmentShader") else { return nil }

        // Compile the functions and other state into a pipeline object.
        do {
            let renderPipelineStateObj =
                try self.buildRenderPipelineState(vertexFunc, fragmentFunction: fragmentFunc)
            renderPipelineState = renderPipelineStateObj
        } catch {
            print("Unable to compile render pipeline state due to error:\(error)")
            return nil
        }

        colorBuffer =
            device.makeBuffer(bytes: colorArray,
                              length: colorArray.count * MemoryLayout.size(ofValue: colorArray[0]),
                              options: .storageModeShared)
    }

    func convertTo4dHomogeneousCoords(_ inCoords: [Float]) -> [Float] {

        var homogeneousCoords: [Float] = []

        for i in stride(from: 0, to: inCoords.count, by: 2) {
            homogeneousCoords += [inCoords[i], inCoords[i + 1]] // Copy in x, y coordinate.
            homogeneousCoords += [0, 1] // Add z, w coordinate.
        }

        return homogeneousCoords
    }

    func quadVertexCoordinates(_ vertexCoordinates: inout [Float], trackID: Int, tween: Float) {
        /*
         diagonalEnd1 and diagonalEnd2 represent the endpoints of a line which partitions the frame on screen into
         the two parts.

         ------------------------
         |			 			|
         |			  			X diagonalEnd2
         |						|
         |						|
         ------------X-----------
         diagonalEnd1

         The below conditionals, use the tween factor as a measure to determine the size of the foreground and
         background quads.

         */

        // The expectation here is that in half the timeRange of the transition we reach the diagonal of the frame.
        if tween <= 0.5 {
            diagonalEnd2.xCoord = 1.0
            diagonalEnd1.yCoord = -1.0
            diagonalEnd1.xCoord = 1.0 - tween * 4
            diagonalEnd2.yCoord = -1.0 + tween * 4

            vertexCoordinates[6] = diagonalEnd2.xCoord
            vertexCoordinates[7] = diagonalEnd2.yCoord
            vertexCoordinates[8] = diagonalEnd1.xCoord
            vertexCoordinates[9] = diagonalEnd1.yCoord

        } else if tween > 0.5 && tween < 1.0 {
            if trackID == foregroundTrackID {
                diagonalEnd1.xCoord = -1.0
                diagonalEnd2.yCoord = 1.0
                diagonalEnd2.xCoord = 1.0 - (tween - 0.5) * 4
                diagonalEnd1.yCoord = -1.0 + (tween - 0.5) * 4

                vertexCoordinates[2] = diagonalEnd2.xCoord
                vertexCoordinates[3] = diagonalEnd2.yCoord
                vertexCoordinates[4] = diagonalEnd1.xCoord
                vertexCoordinates[5] = diagonalEnd1.yCoord
                vertexCoordinates[6] = diagonalEnd1.xCoord
                vertexCoordinates[7] = diagonalEnd1.yCoord
                vertexCoordinates[8] = diagonalEnd1.xCoord
                vertexCoordinates[9] = diagonalEnd1.yCoord
            } else if trackID == backgroundTrackID {
                vertexCoordinates[4] = 1.0
                vertexCoordinates[5] = 1.0
                vertexCoordinates[6] = -1.0
                vertexCoordinates[7] = -1.0
            }
        } else if tween >= 1.0 {
            diagonalEnd1 = Point(xCoord: 1.0, yCoord: -1.0)
            diagonalEnd2 = Point(xCoord: 1.0, yCoord: -1.0)
        }
    }

    func setupRenderPassDescriptor(_ texture: MTLTexture) -> MTLRenderPassDescriptor {

        /*
         MTLRenderPassDescriptor contains attachments that are the rendering destination for pixels
         generated by a rendering pass.
         */
        let renderPassDescriptor = MTLRenderPassDescriptor()

        // Set color to use when the color attachment is cleared.
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        // Associate the texture object with the attachment.
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        return renderPassDescriptor
    }

    func buildRenderPipelineState(_ vertexFunction: MTLFunction, fragmentFunction: MTLFunction)
        throws -> MTLRenderPipelineState {

        // A MTLRenderPipelineDescriptor object that describes the attributes of the render pipeline state.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()

        // A string to help identify this object.
        pipelineDescriptor.label = "Render Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        // Pixel format of the color attachments texture: BGRA.
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    func renderTexture(_ renderEncoder: MTLRenderCommandEncoder, texture: MTLTexture, vertexBuffer: MTLBuffer, textureBuffer: MTLBuffer, pipelineState: MTLRenderPipelineState) {

        // Set the current render pipeline state object.
        renderEncoder.setRenderPipelineState(pipelineState)

        // Specify vertex, color and texture buffers for the vertex shader function.
        renderEncoder.setVertexBuffer(vertexBuffer, offset:0, at:0)
        renderEncoder.setVertexBuffer(colorBuffer, offset:0, at:1)
        renderEncoder.setVertexBuffer(textureBuffer, offset: 0, at: 2)

        // Set a texture for the fragment shader function.
        renderEncoder.setFragmentTexture(texture, at:0)

        // Tell the render context we want to draw our primitives (triangle strip).
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 5, instanceCount: 1)
    }

    override func renderPixelBuffer(_ destinationPixelBuffer: CVPixelBuffer,
                                    usingForegroundSourceBuffer foregroundPixelBuffer: CVPixelBuffer,
                                    andBackgroundSourceBuffer backgroundPixelBuffer: CVPixelBuffer,
                                    forTweenFactor tween: Float) {

        // Create an MTLTexture from the CVPixelBuffer.
        guard let foregroundTexture = buildTextureForPixelBuffer(foregroundPixelBuffer) else { return }
        guard let backgroundTexture = buildTextureForPixelBuffer(backgroundPixelBuffer) else { return }
        guard let destinationTexture = buildTextureForPixelBuffer(destinationPixelBuffer) else { return }

        /*
         We must maintain a reference to the pixel buffer until the Metal rendering is complete. This is because the
         'buildTextureForPixelBuffer' function above uses CVMetalTextureCacheCreateTextureFromImage to create a
         Metal texture (CVMetalTexture) from the IOSurface that backs the CVPixelBuffer, but
         CVMetalTextureCacheCreateTextureFromImage doesn't increment the use count of the IOSurface; only the
         CVPixelBuffer, and the CVMTLTexture own this IOSurface. Therefore we must maintain a reference to either
         the pixel buffer or Metal texture until the Metal rendering is done. The MTLCommandBuffer completion
         handler below is then used to release these references.
        */
        pixelBuffers = RenderPixelBuffers(foregroundPixelBuffer,
                                          backgroundTexture: backgroundPixelBuffer,
                                          destinationTexture: destinationPixelBuffer)

        // Create a new command buffer for each renderpass to the current drawable.
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer.label = "MyCommand"

        /*
         Obtain a drawable texture for this render pass and set up the renderpass descriptor for the command
         encoder to render into.
         */
        let renderPassDescriptor = setupRenderPassDescriptor(destinationTexture)

        // Create a render command encoder so we can render into something.
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.label = "MyRenderEncoder"

        var quadVertexData1: [Float] = [
            -1.0, 1.0,
            1.0, 1.0,
            -1.0, -1.0,
            1.0, -1.0,
            1.0, -1.0
        ]

        // Compute the vertex data for the foreground frame at this instructionLerp.
        quadVertexCoordinates(&quadVertexData1, trackID:foregroundTrackID, tween:tween)

        var homogeneousCoords = convertTo4dHomogeneousCoords(quadVertexData1)
        let quadvertexBuffer =
            device.makeBuffer(bytes: homogeneousCoords,
                              length: homogeneousCoords.count * MemoryLayout.size(ofValue: homogeneousCoords[0]),
                              options: .storageModeShared)

        // Texture data varies from 0 -> 1, whereas vertex data varies from -1 -> 1.
        var quadTextureData1: [Float] = [
            0.5 + quadVertexData1[0]/2, 0.5 + quadVertexData1[1]/2,
            0.5 + quadVertexData1[2]/2, 0.5 + quadVertexData1[3]/2,
            0.5 + quadVertexData1[4]/2, 0.5 + quadVertexData1[5]/2,
            0.5 + quadVertexData1[6]/2, 0.5 + quadVertexData1[7]/2,
            0.5 + quadVertexData1[8]/2, 0.5 + quadVertexData1[9]/2
        ]

        let quadtextureBuffer =
            device.makeBuffer(bytes: quadTextureData1,
                              length: quadTextureData1.count * MemoryLayout.size(ofValue: quadTextureData1[0]),
                              options: .storageModeShared)

        guard let renderPipelineState = renderPipelineState else { return }
        // Render Foreground texture.
        renderTexture(renderEncoder, texture: foregroundTexture, vertexBuffer: quadvertexBuffer,
                      textureBuffer:  quadtextureBuffer,
                      pipelineState: renderPipelineState)

        var quadVertexData2: [Float] = [
            diagonalEnd2.xCoord, diagonalEnd2.yCoord,
            diagonalEnd1.xCoord, diagonalEnd1.yCoord,
            1.0, -1.0,
            1.0, -1.0,
            1.0, -1.0
        ]

        // Compute the vertex data for the background frame at this instructionLerp.
        quadVertexCoordinates(&quadVertexData2, trackID: backgroundTrackID, tween:tween)

        homogeneousCoords = convertTo4dHomogeneousCoords(quadVertexData2)
        let quadvertexBuffer2 =
            device.makeBuffer(bytes: homogeneousCoords,
                              length: homogeneousCoords.count * MemoryLayout.size(ofValue: homogeneousCoords[0]),
                              options: .storageModeShared)

        var quadTextureData2: [Float] = [
            0.5 + quadVertexData2[0]/2, 0.5 + quadVertexData2[1]/2,
            0.5 + quadVertexData2[2]/2, 0.5 + quadVertexData2[3]/2,
            0.5 + quadVertexData2[4]/2, 0.5 + quadVertexData2[5]/2,
            0.5 + quadVertexData2[6]/2, 0.5 + quadVertexData2[7]/2,
            0.5 + quadVertexData2[8]/2, 0.5 + quadVertexData2[9]/2
        ]

        let quadtextureBuffer2 =
            device.makeBuffer(bytes: quadTextureData2,
                              length: quadTextureData2.count * MemoryLayout.size(ofValue: quadTextureData2[0]),
                              options: .storageModeShared)

        // Render Background texture.
        renderTexture(renderEncoder, texture: backgroundTexture, vertexBuffer: quadvertexBuffer2,
                      textureBuffer: quadtextureBuffer2,
                      pipelineState: renderPipelineState)

        // We're done encoding commands.
        renderEncoder.endEncoding()

        // Use the command buffer completion block to release the reference to the pixel buffers.
        commandBuffer.addCompletedHandler({ _ in
            self.pixelBuffers = nil // Release the reference to the pixel buffers.
        })
        // Finalize rendering here & push the command buffer to the GPU.
        commandBuffer.commit()
    }

}

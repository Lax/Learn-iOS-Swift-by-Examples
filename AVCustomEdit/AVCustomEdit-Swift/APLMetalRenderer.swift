/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal base class renderer sets up Metal for rendering, it also loads, compiles and links the vertex and fragment shaders.
 */

import Foundation
import CoreGraphics
import CoreVideo
import MetalKit

class APLMetalRenderer: AnyObject {

    /// A `MTLDevice` object instance representing a GPU that can execute commands.
    let device: MTLDevice

    /// A `MTLCommandQueue` object used to queue the command buffers for the Metal device to execute.
    let commandQueue: MTLCommandQueue

    /// `CVMetalTextureCache` object used for rendering of textures associated with video frames.
    var textureCache: CVMetalTextureCache?

    init?() {
        
        // Ask for the default Metal device; this represents our GPU.
        guard let defaultMetalDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device.")
            return nil
        }
        device = defaultMetalDevice

        // Create the command queue to submit work to the GPU.
        commandQueue = device.makeCommandQueue()

        // Create a new texture cache to use to create textures from the pixel buffers for the movie frames.
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache) == kCVReturnSuccess
            else { return nil }
    }

    func buildTextureForPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> MTLTexture? {

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)

        guard let metalTextureCache = textureCache else { return nil }

        var texture: CVMetalTexture?
        /*
         CVMetalTextureCacheCreateTextureFromImage is used to create a Metal texture (CVMetalTexture) from a
         CVPixelBuffer (or more precisely, a texture from the IOSurface that backs a CVPixelBuffer).

         Note: Calling CVMetalTextureCacheCreateTextureFromImage does not increment the use count of the
         IOSurface; only the CVPixelBuffer, and the CVMTLTexture own this IOSurface. At least one of the two
         must be retained until Metal rendering is done. The MTLCommandBuffer completion handler is good for
         this purpose.
        */
        let status =
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, metalTextureCache, pixelBuffer, nil,
                                                      MTLPixelFormat.bgra8Unorm, width, height, 0, &texture)
        if status == kCVReturnSuccess {
            guard let textureFromImage = texture else { return nil }

            guard let metalTexture = CVMetalTextureGetTexture(textureFromImage) else { return nil }

            return metalTexture
        } else { return nil }
    }

    func renderPixelBuffer(_ destinationPixelBuffer: CVPixelBuffer,
                           usingForegroundSourceBuffer foregroundPixelBuffer: CVPixelBuffer,
                           andBackgroundSourceBuffer backgroundPixelBuffer: CVPixelBuffer,
                           forTweenFactor tween: Float) {
        // Subclasses must implement this function.
    }
}

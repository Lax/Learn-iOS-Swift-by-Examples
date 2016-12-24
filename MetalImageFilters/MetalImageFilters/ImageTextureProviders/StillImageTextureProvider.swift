/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Still Image Texture Provider for MetalImageFilters.
                Uses the MetalKit texture loader to load an still image into a Metal texture.
 */

import MetalKit

/// Uses the MetalKit texture loader to load a still image into a Metal texture.
class StillImageTextureProvider: NSObject {
    /// The source texture for image filter operations.
    var texture: MTLTexture?

    /// Returns an initialized StillImageTextureProvider object with a source texture, or nil in case of failure.
    required init?(device: MTLDevice, imageName: String) {
        super.init()
        
        let loader = MTKTextureLoader(device: device)
        let image = UIImage(named: imageName)?.cgImage
        // The still image is loaded directly into GPU-accessible memory that is only ever read from.
        let options = [
            MTKTextureLoaderOptionTextureStorageMode:   MTLStorageMode.private.rawValue,
            MTKTextureLoaderOptionTextureUsage:         MTLTextureUsage.shaderRead.rawValue,
            MTKTextureLoaderOptionSRGB:                 0
        ]
        do {
            let fileTexture = try loader.newTexture(with: image!, options: options as [String : NSObject]?)
            texture = fileTexture
        } catch let error as NSError {
            print("Error loading still image texture: \(error)")
            return nil
        }
    }
}

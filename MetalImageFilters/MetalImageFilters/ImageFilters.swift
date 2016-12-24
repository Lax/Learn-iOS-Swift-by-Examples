/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Image Filters for MetalImageFilters.
                Each image filter is represented as a class that conforms to the CommandBufferEncodable protocol.
                The protocol ensures that each image filter is initialized with a Metal device and obtains the necessary Metal objects to encode its MetalPerformanceShaders operations.
                The image filters can be single-pass or multi-pass operations on Metal buffers and/or textures.
                The initial source texture is always the original input image read from a file or video.
                The final destination texture is always the filtered output image written to the MTKView's drawable.
 */

import UIKit
import MetalPerformanceShaders
import MetalKit

// MARK: Image Filters
/** Blits the source texture into the destination texture.
    No image filter is applied.
 */
class PassThrough: CommandBufferEncodable {
    required init(device: MTLDevice) {
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        /* destinationTexture is a 'let' constant and thus,the operation "destinationTexture = sourceTexture" is not allowed.
           Instead, a blit operation is performed to copy the contents from sourceTexture to destinationTexture.
         */
        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        blitCommandEncoder.copy(from: sourceTexture,
                                sourceSlice: 0,
                                sourceLevel: 0,
                                sourceOrigin: MTLOriginMake(0, 0, 0),
                                sourceSize: MTLSizeMake(sourceTexture.width, sourceTexture.height, 1),
                                to: destinationTexture,
                                destinationSlice: 0,
                                destinationLevel: 0,
                                destinationOrigin: MTLOriginMake(0, 0, 0))
        blitCommandEncoder.endEncoding()
    }
}

/** Applies a Gaussian blur with a sigma value of 0.5.
    This is a pre-packaged convolution filter.
 */
class GaussianBlur: CommandBufferEncodable {
    let gaussian: MPSImageGaussianBlur
    
    required init(device: MTLDevice) {
        gaussian = MPSImageGaussianBlur(device: device,
                                        sigma: 5.0)
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        gaussian.encode(commandBuffer: commandBuffer,
                        sourceTexture: sourceTexture,
                        destinationTexture: destinationTexture)
    }
}

/** Applies a median filter with a diameter value of 5.
    This is a pre-packaged nonlinear filter.
 */
class Median: CommandBufferEncodable {
    let median: MPSImageMedian
    
    required init(device: MTLDevice) {
        median = MPSImageMedian(device: device,
                                kernelDiameter: 5)
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        median.encode(commandBuffer: commandBuffer,
                      sourceTexture: sourceTexture,
                      destinationTexture: destinationTexture)
    }
}

/** Applies a Laplacian filter with a clamped edge mode.
    This is a pre-packaged convolution filter.
 */
class Laplacian: CommandBufferEncodable {
    let laplacian: MPSImageLaplacian
    
    required init(device: MTLDevice) {
        laplacian = MPSImageLaplacian(device: device)
        laplacian.edgeMode = .clamp
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        laplacian.encode(commandBuffer: commandBuffer,
                         sourceTexture: sourceTexture,
                         destinationTexture: destinationTexture)
    }
}

/** Applies a Sobel filter with a clamped edge mode.
    This is a pre-packaged convolution filter.
 */
class Sobel: CommandBufferEncodable {
    let sobel: MPSImageSobel
    
    required init(device: MTLDevice) {
        sobel = MPSImageSobel(device: device)
        sobel.edgeMode = .clamp
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        sobel.encode(commandBuffer: commandBuffer,
                     sourceTexture: sourceTexture,
                     destinationTexture: destinationTexture)
    }
}

/** Applies a binary filter with a threshold value of 0.5 (minimum value = 0.0; maximum value = 1.0).
    This is a pre-packaged nonlinear filter.
 */
class ThresholdBinary: CommandBufferEncodable {
    let threshold: MPSImageThresholdBinary
    
    required init(device: MTLDevice) {
        threshold = MPSImageThresholdBinary(device: device,
                                            thresholdValue: 0.5,
                                            maximumValue: 1.0,
                                            linearGrayColorTransform: nil)
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        threshold.encode(commandBuffer: commandBuffer,
                         sourceTexture: sourceTexture,
                         destinationTexture: destinationTexture)
    }
}

/** Applies an emboss filter with a clamped edge mode.
    This is a custom convolution filter.
 */
class ConvolutionEmboss: CommandBufferEncodable {
    let convolution: MPSImageConvolution
    
    // These kernel weights create a carving effect that makes the image appear to have physical depth.
    let weights: [Float] = [
        -2,  0,  0,
         0,  1,  0,
         0,  0,  2
    ]
    
    required init(device: MTLDevice) {
        convolution = MPSImageConvolution(device: device,
                                          kernelWidth: 3,
                                          kernelHeight: 3,
                                          weights: weights)
        convolution.edgeMode = .clamp
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        convolution.encode(commandBuffer: commandBuffer,
                           sourceTexture: sourceTexture,
                           destinationTexture: destinationTexture)
    }
}

/** Applies a sharpen filter with a clamped edge mode.
    This is a custom convolution filter.
 */
class ConvolutionSharpen: CommandBufferEncodable {
    let convolution: MPSImageConvolution
    
    // These kernel weights accentuate image details and reduce blur.
    let weights: [Float] = [
        -0.5, -1.0, -0.5,
        -1.0,  7.0, -1.0,
        -0.5, -1.0, -0.5
    ]
    
    required init(device: MTLDevice) {
        convolution = MPSImageConvolution(device: device,
                                          kernelWidth: 3,
                                          kernelHeight: 3,
                                          weights: weights)
        convolution.edgeMode = .clamp
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        convolution.encode(commandBuffer: commandBuffer,
                           sourceTexture: sourceTexture,
                           destinationTexture: destinationTexture)
    }
}

/** Applies a dilation filter with a circular shaped kernel.
    This is a pre-packaged morphology filter.
 */
class DilateBokeh: CommandBufferEncodable {
    let device: MTLDevice
    let bokehRadius = 7
    
    /* A dilation filter requires an array of values known as the "strucuring element" or "probe", which defines which surrounding pixels to sample and their weight.
       This code constructs a 2D probe which is twice the size of the bokeh radius in width and height.
       Elements within the radius are set to 0 and elements outside of the radius are set to 1, which creates a circle filled with zeros.
       The resulting filter gives an effect similar to a photographic "bokeh" effect, where out-of-focus bright areas dilate to circles.
     */
    lazy var dilate: MPSImageDilate = {
        var probe = [Float]()
        let size = self.bokehRadius * 2 + 1
        let mid = Float(size) / 2
        
        for i in 0 ..< size
        {
            for j in 0 ..< size
            {
                let x = abs(Float(i) - mid)
                let y = abs(Float(j) - mid)
                let element: Float = hypot(x, y) < Float(self.bokehRadius) ? 0.0 : 1.0
                probe.append(element)
            }
        }
        
        let dilate = MPSImageDilate(
            device: self.device,
            kernelWidth: size,
            kernelHeight: size,
            values: probe)
        
        return dilate
    }()
    
    required init(device: MTLDevice) {
        self.device = device
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        dilate.encode(commandBuffer: commandBuffer,
                      sourceTexture: sourceTexture,
                      destinationTexture: destinationTexture)
    }
}

/** Applies a dilation followed by an erosion.
    This is a custom filter composed of two morphology filters.
 */
class MorphologyClosing: CommandBufferEncodable {
    // The MPSImageAreaMax and MPSImageAreaMin filters are specialized versions of the MPSImageDilate and MPSImageErode filters, with rectangular kernels.
    let max: MPSImageAreaMax
    let min: MPSImageAreaMin
    
    required init(device: MTLDevice) {
        max = MPSImageAreaMax(device: device,
                              kernelWidth: 9,
                              kernelHeight: 9)
        
        min = MPSImageAreaMin(device: device,
                              kernelWidth: 9,
                              kernelHeight: 9)
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        /* The MorphologyClosing filter is a two-pass operation.
           The intermediate texture acts as the output for the first pass and the input for the second pass, therefore its usage is both write and read.
           Its contents are only accessed by the GPU and therefore its storage mode is private.
         */

        let intermediateTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat,
                                                                                     width: sourceTexture.width,
                                                                                     height: sourceTexture.height,
                                                                                     mipmapped: false)
        intermediateTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        intermediateTextureDescriptor.storageMode = .private
        let intermediateTexture = commandBuffer.device.makeTexture(descriptor: intermediateTextureDescriptor)

        // Applies the dilation to the source texture and outputs the intermediate results to the intermediate texture.
        max.encode(commandBuffer: commandBuffer,
                   sourceTexture: sourceTexture,
                   destinationTexture: intermediateTexture)
        
        // Applies the erosion to the intermediate texture and outputs the final results to the destination texture.
        min.encode(commandBuffer: commandBuffer,
                   sourceTexture: intermediateTexture,
                   destinationTexture: destinationTexture)
    }
}

/** Equalizes the histogram of an image.
    This is a custom filter composed of two histogram filters.
 */
class HistogramEqualization: CommandBufferEncodable {
    /* Histogram equalization flattens an images histogram and stretches it to fill the entire tonal range.
       This technique is useful for revealing detail in images with close contrast values.
     */
    let device: MTLDevice
    let calculation: MPSImageHistogram
    let equalization: MPSImageHistogramEqualization
    
    // Information to compute the histogram for the channels of an image.
    var histogramInfo = MPSImageHistogramInfo(
        numberOfHistogramEntries: 256,
        histogramForAlpha: false,
        minPixelValue: vector_float4(0,0,0,0),
        maxPixelValue: vector_float4(1,1,1,1))
    
    required init(device: MTLDevice) {
        self.device = device
        
        /* Performing histogram equalization requires two filters:
           - An MPSImageHistogram filter which calculates the image's current histogram 
           - An MPSImageHistogramEqualization filter which calculates and applies the equalization.
         */
        calculation = MPSImageHistogram(device: device,
                                        histogramInfo: &histogramInfo)
        
        equalization = MPSImageHistogramEqualization(device: device,
                                                     histogramInfo: &histogramInfo)
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        /* The length of the histogram buffer is calculated as follows:
         Number of Histogram Entries * Size of 32-bit unsigned integer * Number of Image Channels
         However, it is recommended that you use the histogramSize(forSourceFormat:) method to calculate the buffer length.
         The buffer storage mode is private because its contents are only written by the GPU and never accessed by the CPU.
         */
        let bufferLength = calculation.histogramSize(forSourceFormat: sourceTexture.pixelFormat)
        let histogramInfoBuffer = device.makeBuffer(length: bufferLength, options: [.storageModePrivate])
        print("Equalization Buffer Length: \(bufferLength)")
        
        // Performing equalization with MPS is a three stage operation:

        // 1: The image's histogram is calculated and passed to an MPSImageHistogramInfo object.
        calculation.encode(to: commandBuffer,
                           sourceTexture: sourceTexture,
                           histogram: histogramInfoBuffer,
                           histogramOffset: 0)
        
        // 2: The equalization filter's encodeTransform method creates an image transform which is used to equalize the distribution of the histogram of the source image.
        equalization.encodeTransform(to: commandBuffer,
                                     sourceTexture: sourceTexture,
                                     histogram: histogramInfoBuffer,
                                     histogramOffset: 0)
        
        // 3: The equalization filter's encode method applies the equalization transform to the source texture and and writes the output to the destination texture.
        equalization.encode(commandBuffer: commandBuffer,
                            sourceTexture: sourceTexture,
                            destinationTexture: destinationTexture)
    }
}

/** Matches the histogram of an image to another.
    This is a custom filter composed of two histogram filters.
 */
class HistogramSpecification: CommandBufferEncodable  {
    /* Histogram specification takes the histogram of one image and applies it to another.
       This technique is useful for color matching two images prior to compositing them together.
     */
    let device: MTLDevice
    let calculation: MPSImageHistogram
    let specification: MPSImageHistogramSpecification
    
    // Information to compute the histogram for the channels of an image.
    var histogramInfo = MPSImageHistogramInfo(
        numberOfHistogramEntries: 256,
        histogramForAlpha: false,
        minPixelValue: vector_float4(0,0,0,0),
        maxPixelValue: vector_float4(1,1,1,1))
    
    // The texture which will supply the source histogram for the specification operation.
    lazy var imageTexture: MTLTexture = {
        let image = UIImage(named: "final2.jpg")?.cgImage
        let textureLoader = MTKTextureLoader(device: self.device)
        // The still image is loaded directly into GPU-accessible memory that is only ever read from.
        let options = [
            MTKTextureLoaderOptionTextureStorageMode:   MTLStorageMode.private.rawValue,
            MTKTextureLoaderOptionTextureUsage:         MTLTextureUsage.shaderRead.rawValue,
            MTKTextureLoaderOptionSRGB:                 0
        ]
        return try! textureLoader.newTexture(with: image!, options: options as [String : NSObject]?)
    }()
    
    required init(device: MTLDevice) {
        self.device = device
        
        /* Performing histogram specification requires two filters:
           - An MPSImageHistogram filter which calculates the source and destination images' current histograms.
           - An MPSImageHistogramSpecification filter which calculates and applies the specification.
         */
        calculation = MPSImageHistogram(device: device,
                                        histogramInfo: &histogramInfo)

        specification = MPSImageHistogramSpecification(device: device,
                                                       histogramInfo: &histogramInfo)
    }
    
    func encode(to commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        /* The length of the histogram buffer is calculated as follows:
         Number of Histogram Entries * Size of 32-bit unsigned integer * Number of Image Channels
         However, it is recommended that you use the histogramSize(forSourceFormat:) method to calculate the buffer length.
         The buffer storage mode is private because its contents are only written by the GPU and never accessed by the CPU.
         */
        let bufferLength = calculation.histogramSize(forSourceFormat: sourceTexture.pixelFormat)
        let sourceHistogramInfoBuffer = device.makeBuffer(length: bufferLength, options: [.storageModePrivate])
        let desiredHistogramInfoBuffer = device.makeBuffer(length: bufferLength, options: [.storageModePrivate])
        print("Specification Buffer Length: \(bufferLength)")
        
        // Performing equalization with MPS is a four stage operation:
        
        // 1: The histogram of the image to transform is calculated and passed to an MPSImageHistogramInfo object.
        calculation.encode(to: commandBuffer,
                           sourceTexture: sourceTexture,
                           histogram: sourceHistogramInfoBuffer,
                           histogramOffset: 0)
        
        // 2: The histogram of the image to specify from is calculated and passed to an MPSImageHistogramInfo object.
        calculation.encode(to: commandBuffer,
                           sourceTexture: imageTexture,
                           histogram: desiredHistogramInfoBuffer,
                           histogramOffset: 0)
  
        // 3: The specification filter's encodeTransform method creates an image transform which is used to specify the histogram.
        specification.encodeTransform(to: commandBuffer,
                                      sourceTexture: sourceTexture,
                                      sourceHistogram: sourceHistogramInfoBuffer,
                                      sourceHistogramOffset: 0,
                                      desiredHistogram: desiredHistogramInfoBuffer,
                                      desiredHistogramOffset: 0)
        
        // 4: The specification filter's encode method applies the specification transform to the source texture and and writes it to the destination texture
        specification.encode(commandBuffer: commandBuffer,
                             sourceTexture: sourceTexture,
                             destinationTexture: destinationTexture)
    }
}

// MARK: CommandBufferEncodable Protocol
/** A protocol which ensures that each image filter is initialized with a Metal device and can encode its operations with the necessary Metal objects.
 */
protocol CommandBufferEncodable {
    init(device: MTLDevice)
    
    func encode(to commandBuffer: MTLCommandBuffer,
                sourceTexture: MTLTexture,
                destinationTexture: MTLTexture)
}

// MARK: SupportedImageFilter Enum
enum SupportedImageFilter: String {
    case PassThrough
    case GaussianBlur
    case Median
    case Laplacian
    case Sobel
    case ThresholdBinary
    case ConvolutionEmboss
    case ConvolutionSharpen
    case DilateBokeh
    case MorphologyClosing
    case HistogramEqualization
    case HistogramSpecification
    
    static var supportedImageFilterNames: [String] {
        let imageFilters: [SupportedImageFilter] = [
            .PassThrough,
            .GaussianBlur,
            .Median,
            .Laplacian,
            .Sobel,
            .ThresholdBinary,
            .ConvolutionEmboss,
            .ConvolutionSharpen,
            .DilateBokeh,
            .MorphologyClosing,
            .HistogramEqualization,
            .HistogramSpecification
        ]
        return imageFilters.map{$0.rawValue}
    }
    
    static func imageFilterOfIndex(_ index: Int) -> SupportedImageFilter? {
        return imageFilterOfName(supportedImageFilterNames[index])
    }
    
    static func imageFilterOfName(_ name: String?) -> SupportedImageFilter? {
        return SupportedImageFilter(rawValue: name ?? "")
    }
}

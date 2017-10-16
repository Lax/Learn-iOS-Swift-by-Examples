/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Filter renderer protocol.
*/

import CoreMedia

protocol FilterRenderer: class {

	var description: String { get }

	var isPrepared: Bool { get }

	// Prepare resources.
	// The outputRetainedBufferCountHint tells out of place renderers how many of
	// their output buffers will be held onto by the downstream pipeline at one time.
	// This can be used by the renderer to size and preallocate their pools.
	func prepare(with inputFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int)

	// Release resources.
	func reset()

	// The format description of the output pixel buffers.
	var outputFormatDescription: CMFormatDescription? { get }

	// The format description of the input pixel buffers.
	var inputFormatDescription: CMFormatDescription? { get }

	// Render pixel buffer.
	func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer?
}

func allocateOutputBufferPool(with inputFormatDescription: CMFormatDescription,
                              outputRetainedBufferCountHint: Int) ->(
	outputBufferPool: CVPixelBufferPool?,
	outputColorSpace: CGColorSpace?,
	outputFormatDescription: CMFormatDescription?) {

	let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
	if inputMediaSubType != kCVPixelFormatType_32BGRA {
		assertionFailure("Invalid input pixel buffer type \(inputMediaSubType)")
		return (nil, nil, nil)
	}

	let inputDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
	var pixelBufferAttributes: [String: Any] = [
		kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
		kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
		kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
		kCVPixelBufferIOSurfacePropertiesKey as String: [:]
	]

	// Get pixel buffer attributes and color space from the input format description
	var cgColorSpace = CGColorSpaceCreateDeviceRGB()
	if let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(inputFormatDescription) as Dictionary? {
		let colorPrimaries = inputFormatDescriptionExtension[kCVImageBufferColorPrimariesKey]

		if let colorPrimaries = colorPrimaries {
			var colorSpaceProperties: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: colorPrimaries]

			if let yCbCrMatrix = inputFormatDescriptionExtension[kCVImageBufferYCbCrMatrixKey] {
				colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = yCbCrMatrix
			}

			if let transferFunction = inputFormatDescriptionExtension[kCVImageBufferTransferFunctionKey] {
				colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = transferFunction
			}

			pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties
		}

		if let cvColorspace = inputFormatDescriptionExtension[kCVImageBufferCGColorSpaceKey] {
			cgColorSpace = cvColorspace as! CGColorSpace
		} else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
			cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
		}
	}

	// Create a pixel buffer pool with the same pixel attributes as the input format description
	let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
	var cvPixelBufferPool: CVPixelBufferPool?
	CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, pixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)
	guard let pixelBufferPool = cvPixelBufferPool else {
		assertionFailure("Allocation failure: Could not allocate pixel buffer pool")
		return (nil, nil, nil)
	}

	preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)

	// Get output format description
	var pixelBuffer: CVPixelBuffer?
	var outputFormatDescription: CMFormatDescription?
	let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint] as NSDictionary
	CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pixelBufferPool, auxAttributes, &pixelBuffer)
	if let pixelBuffer = pixelBuffer {
		CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &outputFormatDescription)
	}
	pixelBuffer = nil

	return (pixelBufferPool, cgColorSpace, outputFormatDescription)
}

private func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
	var pixelBuffers = [CVPixelBuffer]()
	var error: CVReturn = kCVReturnSuccess
	let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
	var pixelBuffer: CVPixelBuffer?
	while error == kCVReturnSuccess {
		error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
		if let pixelBuffer = pixelBuffer {
			pixelBuffers.append(pixelBuffer)
		}
		pixelBuffer = nil
	}
	pixelBuffers.removeAll()
}

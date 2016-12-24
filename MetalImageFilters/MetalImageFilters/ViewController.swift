/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View Controller for MetalImageFilters.
                The filtered images are displayed within a MetalKit view.
                The view's UI controls are gesture-driven as follows:
                - Swipe left or right to change the current filter.
                - Swipe down to display the video image.
                - Swipe up to display the still image.
                The MetalKit view's draw loop is called manually whenever:
                - The still image is swapped into the view (draws once).
                - A new video frame is provided (draws at 30 FPS).
 */

import UIKit
import MetalPerformanceShaders
import MetalKit

class ViewController: UIViewController {
    // MARK: IB Outlets
    @IBOutlet weak var mtkView: MTKView!
    @IBOutlet weak var filterLabel: UILabel!
    
    // MARK: Metal Properties
    let device = MTLCreateSystemDefaultDevice()!
    var commandQueue: MTLCommandQueue!
    var sourceTexture: MTLTexture?
    
    // MARK: Image Texture Providers
    lazy var stillImageTextureProvider: StillImageTextureProvider? = {
        /* The image file is fixed at a 960x540 pixel resolution that matches the MTKView pixel resolution.
           This ensures screen size compatibility with all target iOS devices, without having to downsample or transform the image file.
         */
        let provider = StillImageTextureProvider(device: self.device, imageName: "final0.jpg")
        return provider
    }()
    
    lazy var videoImageTextureProvider: VideoImageTextureProvider? = {
        let provider = VideoImageTextureProvider(device: self.device, delegate: self)
        return provider
    }()
    
    // MARK: Image Filters
    // Lazily initialized variables for each of the supported filters
    lazy var passThrough: PassThrough = {
        return PassThrough(device: self.device)
    }()
    
    lazy var gaussianBlur: GaussianBlur = {
        return GaussianBlur(device: self.device)
    }()
    
    lazy var median: Median = {
        return Median(device: self.device)
    }()
    
    lazy var laplacian: Laplacian = {
        return Laplacian(device: self.device)
    }()
    
    lazy var sobel: Sobel = {
        return Sobel(device: self.device)
    }()
    
    lazy var thresholdBinary: ThresholdBinary = {
        return ThresholdBinary(device: self.device)
    }()
    
    lazy var convolutionEmboss: ConvolutionEmboss = {
        return ConvolutionEmboss(device: self.device)
    }()
    
    lazy var convolutionSharpen: ConvolutionSharpen = {
        return ConvolutionSharpen(device: self.device)
    }()
    
    lazy var dilateBokeh: DilateBokeh = {
        return DilateBokeh(device: self.device)
    }()
    
    lazy var morphologyClosing: MorphologyClosing = {
        return MorphologyClosing(device: self.device)
    }()
    
    lazy var histogramEqualization: HistogramEqualization = {
        return HistogramEqualization(device: self.device)
    }()
    
    lazy var histogramSpecification: HistogramSpecification = {
        return HistogramSpecification(device: self.device)
    }()
    
    // MARK: Selection properties
    /// This property cycles through the supported image filters and updates the UI accordingly.
    var imageFilterIndex = 0 {
        didSet {
            if imageFilterIndex < 0 {
                imageFilterIndex = SupportedImageFilter.supportedImageFilterNames.count - 1
            }
            else {
                imageFilterIndex = imageFilterIndex % SupportedImageFilter.supportedImageFilterNames.count
            }
            filterLabel.text = (SupportedImageFilter.imageFilterOfIndex(imageFilterIndex)?.rawValue)! + " Filter"
        }
    }
    
    /** This property toggles between the video and still image.
        When the video is running, the delegate method calls the MTKView's draw() method.
        When the video is not running, the else clause calls the MTKView's draw() method.
     */
    var videoIsRunning = false {
        didSet {
            if videoIsRunning == true {
                videoImageTextureProvider?.startRunning()
            }
            else {
                videoImageTextureProvider?.stopRunning()
                sourceTexture = stillImageTextureProvider?.texture
                mtkView.draw()
            }
        }
    }
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageFilterIndex = 0
        setupMetal()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /** The content is rendered *after* the view has appeared.
            This allows the MTKView to set up properly and get the current drawable.
            The MTKView's draw() method is called once after the still image has been loaded.
         */
        sourceTexture = stillImageTextureProvider?.texture
        mtkView.draw()
    }

    // MARK: Metal Setup
    private func setupMetal() {
        commandQueue = device.makeCommandQueue()
        
        /** MetalPerformanceShaders is a compute-based framework.
            This means that the drawable's texture is *written* to, not *rendered* to.
            The destination texture for all image filter operations is not a traditional framebuffer.
         */
        mtkView.framebufferOnly = false
        
        /** This sample manages the MTKView's draw loop manually (i.e. the draw() method is called explicitly).
            For the still image, the content only needs to be filtered once.
            For the video image, the content only needs to be filtered whenever the camera provides a new video frame.
         */
        mtkView.isPaused = true
        
        mtkView.delegate = self
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
    }
    
    // MARK: IB Actions
    @IBAction func didSwipeLeft(sender: UISwipeGestureRecognizer) {
        imageFilterIndex += 1
        if(!videoIsRunning) {
            mtkView.draw()
        }
    }
    
    @IBAction func didSwipeRight(sender: UISwipeGestureRecognizer) {
        imageFilterIndex -= 1
        if(!videoIsRunning) {
            mtkView.draw()
        }
    }
       
    @IBAction func didSwipeUpOrDown(sender: UISwipeGestureRecognizer) {
        videoIsRunning = !videoIsRunning
    }
}

// MARK: MTKViewDelegate
extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        // Use a guard to ensure the method has a valid current drawable, a source texture, and an image filter.
        guard
            let currentDrawable = mtkView.currentDrawable,
            let sourceTexture = sourceTexture,
            let supportedImageFilter = SupportedImageFilter.imageFilterOfIndex(imageFilterIndex) else {
                return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer();
        
        let imageFilter: CommandBufferEncodable
        switch supportedImageFilter {
        case .PassThrough:              imageFilter = passThrough
        case .GaussianBlur:             imageFilter = gaussianBlur
        case .Median:                   imageFilter = median
        case .Laplacian:                imageFilter = laplacian
        case .Sobel:                    imageFilter = sobel
        case .ThresholdBinary:          imageFilter = thresholdBinary
        case .ConvolutionEmboss:        imageFilter = convolutionEmboss
        case .ConvolutionSharpen:       imageFilter = convolutionSharpen
        case .DilateBokeh:              imageFilter = dilateBokeh
        case .MorphologyClosing:        imageFilter = morphologyClosing
        case .HistogramEqualization:    imageFilter = histogramEqualization
        case .HistogramSpecification:   imageFilter = histogramSpecification
        }

        /** Obtain the current drawable.
            The final destination texture is always the filtered output image written to the MTKView's drawable.
         */
        let destinationTexture = currentDrawable.texture
        
        // Encode the image filter operation.
        imageFilter.encode(to: commandBuffer,
                           sourceTexture: sourceTexture,
                           destinationTexture: destinationTexture)
        
        // Schedule a presentation.
        commandBuffer.present(currentDrawable)
        
        // Commit the command buffer to the GPU.
        commandBuffer.commit()
    }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: VideoImageTextureProviderDelegate
{
    func videoImageTextureProvider(_: VideoImageTextureProvider, didProvideTexture texture: MTLTexture) {
        // Replace the source tetxure and call the MTKView's draw() method whenever the camera provides a new video frame.
        sourceTexture = texture
        mtkView.draw()
    }
}

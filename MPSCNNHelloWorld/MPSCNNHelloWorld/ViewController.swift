/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View Controller for Metal Performance Shaders Sample Code.
*/

import UIKit
import MetalPerformanceShaders

class ViewController: UIViewController{

    // some properties used to control the app and store appropriate values
    // we will start with the simple 1 layer
    var deep = false
    var commandQueue: MTLCommandQueue!
    var device: MTLDevice!
    
    // Networks we have
    var neuralNetwork: MNIST_Full_LayerNN? = nil
    var neuralNetworkDeep: MNIST_Deep_ConvNN? = nil
    var runningNet: MNIST_Full_LayerNN? = nil
    
    // loading MNIST Test Set here
    let MNISTdata = GetMNISTData()
    
    // MNIST dataset image parameters
    let mnistInputWidth  = 28
    let mnistInputHeight = 28
    let mnistInputNumPixels = 784
    
    // Outlets to labels and view
    @IBOutlet weak var digitView: DrawView!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load default device.
        device = MTLCreateSystemDefaultDevice()
        
        // Make sure the current device supports MetalPerformanceShaders.
        guard MPSSupportsMTLDevice(device) else {
            print("Metal Performance Shaders not Supported on current Device")
            return
        }
        
        // Create new command queue.
        commandQueue = device!.makeCommandQueue()
        
        // initialize the networks we shall use to detect digits
        neuralNetwork = MNIST_Full_LayerNN(withCommandQueue: commandQueue)
        neuralNetworkDeep  = MNIST_Deep_ConvNN(withCommandQueue: commandQueue)
        runningNet = neuralNetwork
    }
    
    @IBAction func tappedDeepButton(_ sender: UIButton) {
        // switch network to be used between the deep and the single layered
        if deep {
            sender.setTitle("Use Deep Net", for: UIControlState.normal)
            runningNet = neuralNetwork
        }
        else{
            sender.setTitle("Use Single Layer", for: UIControlState.normal)
            runningNet = neuralNetworkDeep
        }
        
        deep = !deep
    }
    
    @IBAction func tappedClear(_ sender: UIButton) {
        // clear the digitview
        digitView.lines = []
        digitView.setNeedsDisplay()
        predictionLabel.isHidden = true
        
    }

    @IBAction func tappedTestSet(_ sender: UIButton) {
        // placeholder to count number of correct detections on the test set
        var correctDetections = Int32(0)
        let total = Float(10000)
        accuracyLabel.isHidden = false
        __atomic_reset()
        
        // validate NeuralNetwork was initialized properly
        assert(runningNet != nil)
        
        for i in 0..<Int(total){
            inference(imageNum: i, correctLabel: UInt(MNISTdata.labels[i]))
            if i % 100 == 0 {
                accuracyLabel.text = "\(i/100)% Done"
                // this command helps update the UI in the loop regularly
                RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantPast)
            }
        }
        // display accuracy of the network on the MNIST test set
        correctDetections = __get_atomic_count()
        
        accuracyLabel.isHidden = false
        accuracyLabel.text = "Accuracy = \(Float(correctDetections * 100)/total)%"
    }
    
    @IBAction func tappedDetectDigit(_ sender: UIButton) {
        // get the digitView context so we can get the pixel values from it to intput to network
        let context = digitView.getViewContext()
        
        // validate NeuralNetwork was initialized properly
        assert(runningNet != nil)
        
        // putting input into MTLTexture in the MPSImage
        runningNet?.srcImage.texture.replace(region: MTLRegion( origin: MTLOrigin(x: 0, y: 0, z: 0),
                                                        size: MTLSize(width: mnistInputWidth, height: mnistInputHeight, depth: 1)),
                                                        mipmapLevel: 0,
                                                        slice: 0,
                                                        withBytes: context!.data!,
                                                        bytesPerRow: mnistInputWidth,
                                                        bytesPerImage: 0)
        // run the network forward pass
        let label = (runningNet?.forward())!
        
        // show the prediction
        predictionLabel.text = "\(label)"
        predictionLabel.isHidden = false
    }

    
    /**
        This function runs the inference network on the test set
     
        - Parameters:
            - imageNum: If the test set is being used we will get a value between 0 and 9999 for which of the 10,000 images is being evaluated
            - correctLabel: The correct label for the inputImage while testing
     
        - Returns:
            Void
     */
    func inference(imageNum: Int, correctLabel: UInt){
        // get the correct image pixels from the test set
        var mnist_input_image = [UInt8]()
        mnist_input_image += MNISTdata.images[(imageNum*mnistInputNumPixels)..<((imageNum+1)*mnistInputNumPixels)]
        
        // create a source image for the network to forward
        let inputImage = MPSImage(device: device, imageDescriptor: (runningNet?.sid)!)
        
        // put image in source texture (input layer)
        inputImage.texture.replace(region: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                                             size: MTLSize(width: mnistInputWidth, height: mnistInputHeight, depth: 1)),
                                             mipmapLevel: 0,
                                             slice: 0,
                                             withBytes: mnist_input_image,
                                             bytesPerRow: mnistInputWidth,
                                             bytesPerImage: 0)
        
        // run the network forward pass
        _ = runningNet!.forward(inputImage: inputImage, imageNum : imageNum, correctLabel: correctLabel)
        
    }
    
}



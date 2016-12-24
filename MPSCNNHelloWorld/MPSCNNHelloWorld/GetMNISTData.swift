/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    GetMNISTData is used to import the test set from the MNIST dataset
*/

import Foundation

class GetMNISTData {
    
    var labels = [UInt8]()
    var images = [UInt8]()
    
    var hdrW, hdrB: UnsafeMutableRawPointer?
    var fd_b, fd_w: CInt
    var sizeBias, sizeWeights: Int
    
    
    init() {
        // get the url to this layer's weights and bias
        let wtPath = Bundle.main.path(forResource: "t10k-images-idx3-ubyte", ofType: "data")
        let bsPath = Bundle.main.path(forResource: "t10k-labels-idx1-ubyte", ofType: "data")
        
        // find and open file
        let URLL = Bundle.main.url(forResource: "t10k-labels-idx1-ubyte", withExtension: "data")
        let dataL = NSData(contentsOf: URLL!)
        
        let URLI = Bundle.main.url(forResource: "t10k-images-idx3-ubyte", withExtension: "data")
        let dataI = NSData(contentsOf: URLI!)
        
        // calculate the size of weights and bias required to be memory mapped into memory
        sizeBias = dataL!.length
        sizeWeights = dataI!.length
        
        // open file descriptors in read-only mode to parameter files
        fd_w = open(wtPath!, O_RDONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)
        fd_b = open(bsPath!, O_RDONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)
        
        assert(fd_w != -1, "Error: failed to open output file at \""+wtPath!+"\"  errno = \(errno)\n")
        assert(fd_b != -1, "Error: failed to open output file at \""+bsPath!+"\"  errno = \(errno)\n")
        
        
        // memory map the parameters
        hdrW = mmap(nil, Int(sizeWeights), PROT_READ, MAP_FILE | MAP_SHARED, fd_w, 0);
        hdrB = mmap(nil, Int(sizeBias), PROT_READ, MAP_FILE | MAP_SHARED, fd_b, 0);
        
        let i = UnsafePointer(hdrW!.bindMemory(to: UInt8.self, capacity: Int(sizeWeights)))
        let l = UnsafePointer(hdrB!.bindMemory(to: UInt8.self, capacity: Int(sizeBias)))

        assert(i != UnsafePointer<UInt8>(bitPattern: -1), "mmap failed with errno = \(errno)")
        assert(l != UnsafePointer<UInt8>(bitPattern: -1), "mmap failed with errno = \(errno)")
        
        
        // remove first 16 bytes that contain info data from array
        images = Array(UnsafeBufferPointer(start: (i + 16), count: sizeWeights - 16))
        
        // remove first 8 bytes that contain file data from our labels array
        labels = Array(UnsafeBufferPointer(start: (l + 8), count: sizeBias - 8))
    }
    
    deinit{
        // unmap files at initialization of MPSCNNFullyConnected, the weights are copied and packed internally we no longer require these
        assert(munmap(hdrW, Int(sizeWeights)) == 0, "munmap failed with errno = \(errno)")
        assert(munmap(hdrB, Int(sizeBias))    == 0, "munmap failed with errno = \(errno)")
        
        // close file descriptors
        close(fd_w)
        close(fd_b)
    }
    
}

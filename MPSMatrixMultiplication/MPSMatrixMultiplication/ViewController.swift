/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Sample code demonstrating matrix multiplication using the Metal Performance Shaders Framework.
 */

import UIKit
import MetalPerformanceShaders

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         Matrix multiplication parameters.  This code performs the operation:
         
         C = A * B
         
         Where C is M x N, A is M x K, and B is K x N.  M = N = K = 1024.
         
         MPSMatrixMultiplication kernels are initialized with parameters for a
         generalized matrix multiplication in the same sense as the C BLAS
         level 3 *gemm routines.
         
         This operation uses alpha = 1.0 and beta = 0.0.  No matrices are
         transposed.
         
         MPSMatrix objects use row-major ordering.
         */
        let M = 1024
        let N = 1024
        let K = 1024
        let alpha = 1.0
        let beta  = 0.0
        
        // Use the default system device and an associated command queue.
        let device = MTLCreateSystemDefaultDevice()!
        let commandQueue = device.makeCommandQueue()
        
        /* 
         A MPSMatrixDescriptor object will be used to specify the matrix
         properties to the MPSMatrix initialization routines.
         */
        var matrixDescriptor: MPSMatrixDescriptor
        
        /*
         All data is referenced by MTLBuffer objects.  There are three MTLBuffer
         objects, two for the input arrays and one for the output array.
         */
        
        /*
         Each MTLBuffer object requires only enough storage to hold its data.
         In order to achieve best performance more space may be required.  This
         amount of space, in bytes, may be determined by calling the
         MPSMatrixDescriptor method rowBytes(fromColumns:dataType:).
         */
        
        // Each row of A has K values.
        let ARowBytes = MPSMatrixDescriptor.rowBytes(fromColumns: K, dataType: MPSDataType.float32)
        
        // Each row of B has N values.
        let BRowBytes = MPSMatrixDescriptor.rowBytes(fromColumns: N, dataType: MPSDataType.float32)
        
        // Each row of C has N values.
        let CRowBytes = MPSMatrixDescriptor.rowBytes(fromColumns:N, dataType: MPSDataType.float32)
        
        // Create the buffers with the recommended sizes.
        let ABuffer = device.makeBuffer(length: M * ARowBytes)
        let BBuffer = device.makeBuffer(length: K * BRowBytes)
        let CBuffer = device.makeBuffer(length: M * CRowBytes)
        
        /*
         All buffers are encapsulated in MPSMatrix objects.  Each MPSMatrix
         object is created with its associated buffer and an MPSMatrixDescriptor
         object which specifies dimension and type information for the matrix.
         */
        
        // The 'A' matrix.
        matrixDescriptor = MPSMatrixDescriptor(dimensions: M,
                                               columns: K,
                                               rowBytes: ARowBytes,
                                               dataType: MPSDataType.float32)
        let A = MPSMatrix(buffer: ABuffer, descriptor: matrixDescriptor)
        
        // The 'B' matrix.
        matrixDescriptor.rows = K
        matrixDescriptor.columns = N
        matrixDescriptor.rowBytes = BRowBytes
        let B = MPSMatrix(buffer: BBuffer, descriptor: matrixDescriptor)
        
        // The 'C' matrix.
        matrixDescriptor.rows = M
        matrixDescriptor.rowBytes = CRowBytes
        let C = MPSMatrix(buffer: CBuffer, descriptor: matrixDescriptor)
        
        /*
         Create a kernel to perform generalized matrix multiplication on the
         system device using the desired parameters.
         */
        let sgemmKernel = MPSMatrixMultiplication(device: device,
                                                  transposeLeft: false,
                                                  transposeRight: false,
                                                  resultRows: M,
                                                  resultColumns: N,
                                                  interiorColumns: K,
                                                  alpha: alpha,
                                                  beta: beta)
        
        // Create a command buffer in the queue.
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // Encode the kernel to the command buffer.
        sgemmKernel.encode(commandBuffer:commandBuffer,
                           leftMatrix: A,
                           rightMatrix: B,
                           resultMatrix: C)
        
        // Commit the buffer and wait for it to complete.
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}

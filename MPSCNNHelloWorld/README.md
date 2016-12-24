# MPSCNNHelloWorld: Simple Digit Detection Convolution Neural Networks (CNN)

This sample is a port of the open source library, TensorFlow trained networks trained on MNIST Dataset (http://yann.lecun.com/exdb/mnist/) via inference using Metal Performance Shaders. 
The sample demonstrates how to encode different layers to the GPU and perform image recognition using trained parameters(weights and bias) that have been fetched from, pre-trained and saved network on TensorFlow.

The Single Network can be found at:
https://www.tensorflow.org/versions/r0.8/tutorials/mnist/beginners/index.html#mnist-for-ml-beginners

The Deep Network can be found at:
https://www.tensorflow.org/versions/r0.8/tutorials/mnist/pros/index.html#deep-mnist-for-experts

The network parameters are stored a binary .dat files that are memory-mapped when needed.

## Requirements

### Build

Xcode 8.0 or later; iOS 10.0 SDK or later

### Runtime

iOS 10.0 or later

### Device Feature Set

iOS GPU Family 2 v1
iOS GPU Family 2 v2
iOS GPU Family 3 v1

Copyright (C) 2016 Apple Inc. All rights reserved.

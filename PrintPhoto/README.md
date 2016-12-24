# PrintPhoto

Demonstrates how to print an image via share sheets with the UIActivityViewController class. The sample also shows how to print simple images and custom drawings.

## Requirements

### Build

Xcode 7.1 and iOS 9.0 SDK or later

### Runtime

iOS 9.0 or later

## Architecture

This sample can be run on a device or on the simulator.

PrintPhoto demonstrates how to enable users to print an image using a share sheet. To do this you need to present a customized UIActivityViewController with the data you want to print. This sample shows two ways of doing this:

1) Providing a UIImage instance to the UIActivityViewController. Using this approach allows UIKit to pick the optimal way to print an image. You can see how this works in the StandardAssetPrintViewController.

2) Providing a UIPrintPageRenderer subclass that renders an image with customized UI. In this example we show how to draw the image as a vignette. However, the purpose of this sample _is not_ to show how to print a vignette but to show you that you can render any custom graphics you may have in your application. You can do this using CoreGraphics. For more information on how to print pages with custom graphics, see the CustomAssetPrintPageRenderer class. To see how you set up a UIActivityViewController with activity items that will allow you to use a custom UIPrintPageRenderer to print, see the CustomAssetPrintViewController class. Note that this class is very similar to the StandardAssetPrintViewController class: the only difference is that the standard view controller provides an image and the custom view controller passes a UIPrintPageRenderer subclass.

Copyright (C) 2015 Apple Inc. All rights reserved.

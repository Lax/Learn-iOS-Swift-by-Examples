# AdaptiveElements: Implementing Your Own Adaptive Design with UIKit

This sample shows how to use UIKit to lay out your app's elements in different sizes, from full-screen on the smallest iPhone to Multitasking on the biggest iPad. It shows how to make smart decisions about implementing your own design. It also demonstrates how to reuse elements in different sizes, so you can take advantage of all the available space without having to rewrite your entire app.

- SimpleExampleViewController demonstrates how to use a view's size to determine an arrangement of its subviews. Also, it shows how to add an animation effect during app size changes.

- ExampleContainerViewController is a more complete example of a container view controller. It demonstrates how to define an instance to represent a design, how to make a complex decision of which design to use for the app's size, and how to apply the design to the UI.

- SmallElementViewController and LargeElementViewController are contained within ExampleContainerViewController. LargeElementController, specifically, is reused in different ways. These two view controllers handle taps to present and dismiss.

For more information, see:

- Session 222 "Making Apps Adaptive, Part 1" from WWDC 2016 (https://developer.apple.com/videos/wwdc/2016/#222)

- Session 233 "Making Apps Adaptive, Part 2" from WWDC 2016 (https://developer.apple.com/videos/wwdc/2016/#233)

- Session 205 "Adopting Multitasking in iOS 9" from WWDC 2015 (https://developer.apple.com/videos/wwdc/2015/#205)

- Session 216 "Building Adaptive Apps with UIKit" from WWDC 2014 (https://developer.apple.com/videos/wwdc/2014/#216)

## Requirements

### Build

Xcode 8.0 or later; iOS 10.0 SDK or later

### Runtime

iOS 9.0 or later

Copyright (C) 2016 Apple Inc. All rights reserved.

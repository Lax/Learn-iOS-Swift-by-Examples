# User Interface 3D Transforms

This sample code demonstrates applying 3D effects to an arbitrary UIView. A few different views are chosen randomly to facilitate this example: images, a map view, and a web view. A view hierarchy is shown that is akin to the tab switching user experience in Safari on iOS and the 3D nature of this effect is implemented using CALayer's CATransform3D.    

Note regarding touch input: 

Views that handle touch input continue to function normally while in the "switcher" mode by default in this sample code, and by that, they respond to touch input while transformed in 3D space. There are occasions where this might be desired bahavior, but in cases where it is not, set SwitcherView.enableUserInteractionInSwitcher to false.     

## Requirements

### Build

Xcode 6 or later 

### Runtime

iOS 8 or later 

Copyright (C) 2015 Apple Inc. All rights reserved.

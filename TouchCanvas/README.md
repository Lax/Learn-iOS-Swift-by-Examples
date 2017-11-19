# TouchCanvas: Using UITouch efficiently and effectively

TouchCanvas illustrates responsive touch handling using coalesced and predictive touches (when available) via a simple drawing app. The sample uses force information (when available) to change line thickness. Apple Pencil and finger touches are distinguished via different colors. In addition, Apple Pencil only data is demonstrated through the use of estimated properties and updates providing the actual property data including the azimuth and altitude of the Apple Pencil while in use.

The sample includes a debug and precise options as follows:

* precise will force the use of UITouch's preciseLocation method over UITouch's location method for retrieving more precise screen coordinates.
* debug will draw the lines displayed in different colors depending on properties gathered from the UITouch APIs.  See the enclosed LinePoint class in Line.swift.

## Requirements

### Build

Xcode 9.0 or later, iOS 10.0 SDK or later

### Runtime

iOS 9.1

### Changes

version 2.1 - updated to Swift 4.0
version 2.0 - first release

Copyright (C) 2017 Apple Inc. All rights reserved.


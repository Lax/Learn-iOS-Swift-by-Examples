/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Depending on the platform that we're running our tests in, we import UIKit or Cocoa to make sure that XCTest can run correctly.
*/

#if os(iOS)
import UIKit
#elseif os(OSX)
import Cocoa
#endif

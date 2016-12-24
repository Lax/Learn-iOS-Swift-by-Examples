/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `UIColor+Custom` method provides a generator method for a custom color.
*/

import UIKit

extension UIColor {
    
    /// - returns:  A nice blue color which suggests editability.
    static func editableBlueColor() -> UIColor {
        return UIColor(red:0/255.0, green:122/255.0, blue:255/255.0, alpha:1.0)
    }
}
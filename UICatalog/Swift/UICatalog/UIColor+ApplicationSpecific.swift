/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Application-specific color convenience methods.
*/

import UIKit

extension UIColor {
    class func applicationGreenColor() -> UIColor {
        return UIColor(red: 0.255, green: 0.804, blue: 0.470, alpha: 1)
    }

    class func applicationBlueColor() -> UIColor {
        return UIColor(red: 0.333, green: 0.784, blue: 1, alpha: 1)
    }

    class func applicationPurpleColor() -> UIColor {
        return UIColor(red: 0.659, green: 0.271, blue: 0.988, alpha: 1)
    }
}

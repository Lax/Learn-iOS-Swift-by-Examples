/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                An extension on the List.Color enumeration that adds a computed property to obtain a platform-specific color object from the enumeration value.
            
*/

#if os(iOS)
import UIKit
#elseif os(OSX)
import Cocoa
#endif

extension List.Color {
    struct SharedInstances {
        // Initialze `colorType` based on the platform that is being compiled for. The initialiers we use on the type are
        // spelled the same for both UIColor and NSColor, so this is a shorthand for creating both colors.
        #if os(iOS)
        static let colorType = UIColor.self
        #elseif os(OSX)
        static let colorType = NSColor.self
        #endif

        static let mapping: Dictionary = [
            List.Color.Gray:   colorType.darkGrayColor(),
            List.Color.Blue:   colorType(red: 0.42, green: 0.70, blue: 0.88, alpha: 1),
            List.Color.Green:  colorType(red: 0.71, green: 0.84, blue: 0.31, alpha: 1),
            List.Color.Yellow: colorType(red: 0.95, green: 0.88, blue: 0.15, alpha: 1),
            List.Color.Orange: colorType(red: 0.96, green: 0.63, blue: 0.20, alpha: 1),
            List.Color.Red:    colorType(red: 0.96, green: 0.42, blue: 0.42, alpha: 1)
        ]
    }

    #if os(iOS)
    var colorValue: UIColor {
        return SharedInstances.mapping[self]!
    }
    #elseif os(OSX)
    var colorValue: NSColor {
        return SharedInstances.mapping[self]!
    }
    #endif
}


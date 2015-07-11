/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension on the `List.Color` enumeration that adds a computed property to obtain a platform-specific color object from the enumeration value.
*/

#if os(iOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import Cocoa
#endif

// Provide a private typealias for a platform specific color.
#if os(iOS) || os(watchOS)
private typealias AppColor = UIColor
#elseif os(OSX)
private typealias AppColor = NSColor
#endif

public extension List.Color {
    private static let colorMapping = [
        List.Color.Gray:   AppColor.darkGrayColor(),
        List.Color.Blue:   AppColor(red: 0.42, green: 0.70, blue: 0.88, alpha: 1),
        List.Color.Green:  AppColor(red: 0.71, green: 0.84, blue: 0.31, alpha: 1),
        List.Color.Yellow: AppColor(red: 0.95, green: 0.88, blue: 0.15, alpha: 1),
        List.Color.Orange: AppColor(red: 0.96, green: 0.63, blue: 0.20, alpha: 1),
        List.Color.Red:    AppColor(red: 0.96, green: 0.42, blue: 0.42, alpha: 1)
    ]
    
    private static let notificationCenterColorMapping = [
        List.Color.Gray:   AppColor.lightGrayColor(),
        List.Color.Blue:   AppColor(red: 0.42, green: 0.70, blue: 0.88, alpha: 1),
        List.Color.Green:  AppColor(red: 0.71, green: 0.84, blue: 0.31, alpha: 1),
        List.Color.Yellow: AppColor(red: 0.95, green: 0.88, blue: 0.15, alpha: 1),
        List.Color.Orange: AppColor(red: 0.96, green: 0.63, blue: 0.20, alpha: 1),
        List.Color.Red:    AppColor(red: 0.96, green: 0.42, blue: 0.42, alpha: 1)
    ]

    #if os(iOS) || os(watchOS)
    public var colorValue: UIColor {
        return List.Color.colorMapping[self]!
    }
    
    public var notificationCenterColorValue: UIColor {
        return List.Color.notificationCenterColorMapping[self]!
    }
    #elseif os(OSX)
    public var colorValue: NSColor {
        return List.Color.colorMapping[self]!
    }
    public var notificationCenterColorValue: NSColor {
        return List.Color.notificationCenterColorMapping[self]!
    }
    #endif
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The protocol and enums that define the different types of body parts that are used to build a robot.
*/

import UIKit

protocol IceCreamPart {
    var rawValue: String { get }
    
    var image: UIImage { get }
    
    var stickerImage: UIImage { get }
}


enum Topping: String, IceCreamPart, QueryItemRepresentable {
    case topping01, topping02, topping03, topping04, topping05, topping06, topping07, topping08, topping09, topping10, topping11, topping12
    
    static let all: [Topping] = [.topping01, .topping02, .topping03, .topping04, .topping05, .topping06, .topping07, .topping08, .topping09, .topping10, .topping11, .topping12]
    
    static var queryItemKey: String {
        return "Topping"
    }
}

enum Scoops: String, IceCreamPart, QueryItemRepresentable {
    case scoops01, scoops02, scoops03, scoops04, scoops05, scoops06, scoops07, scoops08, scoops09, scoops10
    
    static let all: [Scoops] = [.scoops01, .scoops02, .scoops03, .scoops04, .scoops05, .scoops06, .scoops07, .scoops08, .scoops09, .scoops10]
    
    static var queryItemKey: String {
        return "Scoops"
    }
}

enum Base: String, IceCreamPart, QueryItemRepresentable {
    case base01, base02, base03, base04
    
    static let all: [Base] = [.base01, .base02, .base03, .base04]
    
    static var queryItemKey: String {
        return "Base"
    }
}



/// Extends `IceCreamPart` to provide a default implementation of the `image` and `stickerImage` properties.
extension IceCreamPart {
    var image: UIImage {
        let imageName = self.rawValue
        guard let image = UIImage(named: imageName) else { fatalError("Unable to find image named \(imageName)") }
        return image
    }

    var stickerImage: UIImage {
        let imageName = "\(self.rawValue)_sticker"
        guard let image = UIImage(named: imageName) else { fatalError("Unable to find image named \(imageName)") }
        return image
    }
}

/**
 Extends instances of `QueryItemRepresentable` that also conformt to `IceCreamPart`
 to provide a default implementation of `queryItem`.
 */
extension QueryItemRepresentable where Self: IceCreamPart {
    var queryItem: URLQueryItem {
        return URLQueryItem(name: Self.queryItemKey, value: rawValue)
    }
}

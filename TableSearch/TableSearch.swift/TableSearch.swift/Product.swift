/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:

The data model object describing the product displayed in both main and results tables.

*/

import Foundation

class Product: NSObject, NSCoding {
    // MARK: Types
    
    struct CoderKeys {
        static let name = "nameKey"
        static let type = "typeKey"
        static let year = "yearKey"
        static let price = "priceKey"
    }
    
    // MARK: Properties
    
    let title: String
    let hardwareType: String
    let yearIntroduced: Int
    let introPrice: Double
    
    // MARK: Initializers
    
    init(type: String, name: String, year: Int, price: Double) {
        hardwareType = type
        title = name
        yearIntroduced = year
        introPrice = price
    }
    
    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder) {
        title = aDecoder.decodeObjectForKey(CoderKeys.name) as String
        hardwareType = aDecoder.decodeObjectForKey(CoderKeys.type) as String
        yearIntroduced = aDecoder.decodeIntegerForKey(CoderKeys.year)
        introPrice = aDecoder.decodeDoubleForKey(CoderKeys.price)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(title, forKey: CoderKeys.name)
        aCoder.encodeObject(hardwareType, forKey: CoderKeys.type)
        aCoder.encodeInteger(yearIntroduced, forKey: CoderKeys.year)
        aCoder.encodeDouble(introPrice, forKey: CoderKeys.price)
    }
    
    // MARK: Device Type Info

    class var deviceTypeNames: [String] {
        return [
            Product.deviceTypeTitle,
            Product.desktopTypeTitle,
            Product.portableTypeTitle
        ]
    }
    
    class var deviceTypeTitle: String {
        return NSLocalizedString("Device", comment:"Device type title")
    }

    class var desktopTypeTitle: String {
        return NSLocalizedString("Desktop", comment:"Desktop type title")
    }

    class var portableTypeTitle: String {
        return NSLocalizedString("Portable", comment:"Portable type title")
    }
}
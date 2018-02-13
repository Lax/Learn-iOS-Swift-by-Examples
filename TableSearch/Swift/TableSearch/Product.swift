/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The data model object describing the product displayed in both main and results tables.
*/

import Foundation

class Product: NSObject, NSCoding {
    
    // MARK: - Types
    
    enum CoderKeys: String {
        case nameKey
        case typeKey
        case yearKey
        case priceKey
    }
    
	struct Hardware {
		static let iPhone = "iPhone"
		static let iPod = "iPod"
		static let iPodTouch = "iPod touch"
		static let iPad = "iPad"
		static let iPadMini = "iPad Mini"
		static let iMac = "iMac"
		static let MacPro = "Mac Pro"
		static let MacBookAir = "Mac Book Air"
		static let MacBookPro = "Mac Book Pro"
	}
	
	static let deviceTypeTitle = NSLocalizedString("Device", comment:"Device type title")
	static let desktopTypeTitle = NSLocalizedString("Desktop", comment:"Desktop type title")
	static let portableTypeTitle = NSLocalizedString("Portable", comment:"Portable type title")
	
    // MARK: - Properties
    
    @objc let title: String
   	@objc let yearIntroduced: Int
   	@objc let introPrice: Double
    let hardwareType: String
	
    // MARK: - Initializers
    
    init(hardwareType: String, title: String, yearIntroduced: Int, introPrice: Double) {
        self.hardwareType = hardwareType
        self.title = title
        self.yearIntroduced = yearIntroduced
        self.introPrice = introPrice
    }
    
    // MARK: - NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        title = aDecoder.decodeObject(forKey: CoderKeys.nameKey.rawValue) as! String
        hardwareType = aDecoder.decodeObject(forKey: CoderKeys.typeKey.rawValue) as! String
        yearIntroduced = aDecoder.decodeInteger(forKey: CoderKeys.yearKey.rawValue)
        introPrice = aDecoder.decodeDouble(forKey: CoderKeys.priceKey.rawValue)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: CoderKeys.nameKey.rawValue)
        aCoder.encode(hardwareType, forKey: CoderKeys.typeKey.rawValue)
        aCoder.encode(yearIntroduced, forKey: CoderKeys.yearKey.rawValue)
        aCoder.encode(introPrice, forKey: CoderKeys.priceKey.rawValue)
    }
    
    // MARK: - Device Type Info

    class var deviceTypeNames: [String] {
        return [
            Product.deviceTypeTitle,
            Product.desktopTypeTitle,
            Product.portableTypeTitle
        ]
    }
}

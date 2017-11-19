/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An item result with a given item loader and custom label.
*/

import Cocoa

class CustomRotorsElementLoadingToken: NSObject, NSCoding, NSSecureCoding {
    var uniqueIdentifier = ""
    
    init(identifier: String) {
        uniqueIdentifier = identifier
    }
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        
        if let identifier = aDecoder.decodeObject(of: NSString.self, forKey: "uniqueIdentifier") as String? {
            uniqueIdentifier = identifier
        }
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(uniqueIdentifier, forKey: "uniqueIdentifier")
    }
    
}


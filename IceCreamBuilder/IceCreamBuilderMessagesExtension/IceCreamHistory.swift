/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A struct that persists a history of ice creams to `UserDefaults`.
*/

import Foundation

struct IceCreamHistory {
    // MARK: Properties
    
    private static let maximumHistorySize = 50
    
    private static let userDefaultsKey = "iceCreams"
    
    /// An array of previously created `IceCream`s.
    fileprivate var iceCreams: [IceCream]

    var count: Int {
        return iceCreams.count
    }

    subscript(index: Int) -> IceCream {
        return iceCreams[index]
    }
    
    // MARK: Initialization
    
    /**
        `IceCreamHistory`'s initializer is marked as private. Instead instances should
        be loaded via the `load` method.
    */
    private init(iceCreams: [IceCream]) {
        self.iceCreams = iceCreams
    }

    /// Loads previously created `IceCream`s and returns a `IceCreamHistory` instance.
    static func load() -> IceCreamHistory {
        var iceCreams = [IceCream]()
        let defaults = UserDefaults.standard
        
        if let savedIceCreams = defaults.object(forKey: IceCreamHistory.userDefaultsKey) as? [String] {
            iceCreams = savedIceCreams.flatMap { urlString in
                guard let url = URL(string: urlString) else { return nil }
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return nil }
                
                return IceCream(queryItems: queryItems)
            }
        }
        
        // If no ice creams have been loaded, create some tasty examples.
        if iceCreams.isEmpty {
            iceCreams.append(IceCream(base: .base01, scoops: .scoops01, topping: .topping01))
            iceCreams.append(IceCream(base: .base02, scoops: .scoops02, topping: .topping02))
            iceCreams.append(IceCream(base: .base03, scoops: .scoops03, topping: .topping03))
            iceCreams.append(IceCream(base: .base04, scoops: .scoops04, topping: .topping04))
            
            let historyToSave = IceCreamHistory(iceCreams: iceCreams)
            historyToSave.save()
        }
        
        return IceCreamHistory(iceCreams: iceCreams)
    }
    
    /// Saves the history.
    func save() {
        // Save a maximum number ice creams.
        let iceCreamsToSave = iceCreams.suffix(IceCreamHistory.maximumHistorySize)
        
        // Map the ice creams to an array of URL strings.
        let iceCreamURLStrings: [String] = iceCreamsToSave.flatMap { iceCream in
            var components = URLComponents()
            components.queryItems = iceCream.queryItems
            
            return components.url?.absoluteString
        }
        
        let defaults = UserDefaults.standard
        defaults.set(iceCreamURLStrings as AnyObject, forKey: IceCreamHistory.userDefaultsKey)
    }
    
    mutating func append(_ iceCream: IceCream) {
        /*
            Filter any existing instances of the new ice cream from the current
            history before adding it to the end of the history.
        */
        var newIceCreams = self.iceCreams.filter { $0 != iceCream }
        newIceCreams.append(iceCream)
        
        iceCreams = newIceCreams
    }
}



/**
 Extends `IceCreamHistory` to conform to the `Sequence` protocol so it can be used
 in for..in statements.
 */
extension IceCreamHistory: Sequence {
    typealias Iterator = AnyIterator<IceCream>
    
    func makeIterator() -> Iterator {
        var index = 0
        
        return Iterator {
            guard index < self.iceCreams.count else { return nil }
            
            let iceCream = self.iceCreams[index]
            index += 1
            
            return iceCream
        }
    }
}

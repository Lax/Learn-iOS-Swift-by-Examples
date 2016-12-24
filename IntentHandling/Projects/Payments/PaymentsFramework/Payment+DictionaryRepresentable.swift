/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Extends `Payment` to allow it to be represented as and initialized with an `NSDictionary`.
*/

import Foundation

extension Payment: DictionaryRepresentable {
    // MARK: Types
    
    private struct DictionaryKeys {
        static let contact = "contact"
        static let amount = "amount"
        static let currencyCode = "currencyCode"
        static let date = "date"
    }
    
    // MARK: DictionaryRepresentable
    
    var dictionaryRepresentation: [String : Any] {
        var dictionary = [String: Any]()
    
        dictionary[DictionaryKeys.contact] = contact.dictionaryRepresentation
        dictionary[DictionaryKeys.amount] = amount.doubleValue
        dictionary[DictionaryKeys.currencyCode] = currencyCode
        
        if let date = date {
            dictionary[DictionaryKeys.date] = date
        }
        
        return dictionary
    }
    
    init?(dictionaryRepresentation dictionary: [String: Any]) {
        guard let contactDictionary = dictionary[DictionaryKeys.contact] as? [String: AnyObject], let contact = Contact(dictionaryRepresentation: contactDictionary) else { return nil }
        guard let doubleAmount = dictionary[DictionaryKeys.amount] as? Double else { return nil }
        guard let currencyCode = dictionary[DictionaryKeys.currencyCode] as? String else { return nil }
        
        let date = dictionary[DictionaryKeys.date] as? Date
        
        self.contact = contact
        self.amount = NSDecimalNumber(value: doubleAmount)
        self.currencyCode = currencyCode
        self.date = date
    }
}

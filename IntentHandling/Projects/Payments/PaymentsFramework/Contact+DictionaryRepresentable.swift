/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Extends `Contact` to allow it to be represented as and initialized with an `NSDictionary`.
*/

import Foundation

extension Contact: DictionaryRepresentable {
    // MARK: Types
    
    private struct DictionaryKeys {
        static let familyName = "familyName"
        static let givenName = "givenName"
        static let emailAddress = "emailAddress"
    }
    
    // MARK: DictionaryRepresentable
    
    var dictionaryRepresentation: [String : Any] {
        var dictionary = [String: Any]()
        
        dictionary[DictionaryKeys.familyName] = nameComponents.familyName ?? ""
        dictionary[DictionaryKeys.givenName] = nameComponents.givenName ?? ""
        dictionary[DictionaryKeys.emailAddress] = emailAddress
        
        return dictionary
    }
    
    init?(dictionaryRepresentation dictionary: [String: Any]) {
        guard let emailAddress = dictionary[DictionaryKeys.emailAddress] as? String, !emailAddress.isEmpty else { return nil }
        
        var nameComponents = PersonNameComponents()
        nameComponents.familyName = dictionary[DictionaryKeys.familyName] as? String
        nameComponents.givenName = dictionary[DictionaryKeys.givenName] as? String
        
        self.nameComponents = nameComponents
        self.emailAddress = emailAddress
    }
}

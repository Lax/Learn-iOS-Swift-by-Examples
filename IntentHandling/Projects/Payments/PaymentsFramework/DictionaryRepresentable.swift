/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A type that implements the `DictionaryRepresentable` can be represented as and initialized with an `NSDictionary`.
*/

import Foundation

protocol DictionaryRepresentable {
    
    var dictionaryRepresentation: [String: Any] { get }
    
    init?(dictionaryRepresentation dictionary: [String: Any])
}

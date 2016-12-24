/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A struct that defines a payment made with our app.
*/

import Foundation

public struct Payment: Equatable {
    
    // MARK: Properties
    
    public let contact: Contact
    
    public let amount: NSDecimalNumber
    
    public let currencyCode: String
    
    public let date: Date?
    
    // MARK: Public initializer
    
    public init(contact: Contact, amount: NSDecimalNumber, currencyCode: String, date: Date? = nil) {
        self.contact = contact
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
    }
}

public func ==(lhs: Payment, rhs: Payment) -> Bool {
    return lhs.contact.emailAddress == rhs.contact.emailAddress &&
            lhs.amount == rhs.amount &&
            lhs.currencyCode == rhs.currencyCode &&
            lhs.date == rhs.date
}

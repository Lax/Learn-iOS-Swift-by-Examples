/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A struct that defines a contact that can receive payments from our app.
*/

import Intents

public struct Contact {
    
    private static let nameFormatter = PersonNameComponentsFormatter()
    
    public let nameComponents: PersonNameComponents
    
    public let emailAddress: String
    
    public var formattedName: String {
        return Contact.nameFormatter.string(from: nameComponents)
    }
    
    public init(givenName: String?, familyName: String?, emailAddress: String) {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = givenName
        nameComponents.familyName = familyName

        self.nameComponents = nameComponents
        self.emailAddress = emailAddress
    }
    
}

public extension Contact {
    static let sampleContacts = [
        Contact(givenName: "Anne", familyName: "Johnson", emailAddress: "anne.johnson@example.com"),
        Contact(givenName: "Maria", familyName: "Ruiz", emailAddress: "maria.ruiz@example.com"),
        Contact(givenName: "Mei", familyName: "Chen", emailAddress: "mei.chen@example.com"),
        Contact(givenName: "Gita", familyName: "Kumar", emailAddress: "gita.kumar@example.com"),
        Contact(givenName: "Bill", familyName: "James", emailAddress: "bill.james@example.com"),
        Contact(givenName: "Tom", familyName: "Clark", emailAddress: "tom.clark@example.com"),
        Contact(givenName: "Juan", familyName: "Chavez", emailAddress: "juan.chavez@example.com"),
        Contact(givenName: "Ravi", familyName: "Patel", emailAddress: "ravi.patel@example.com"),
    ]
}

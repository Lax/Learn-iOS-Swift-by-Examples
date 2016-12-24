/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Extends `INPerson` to add an initializer that accepts a `Contact`.
*/

import PaymentsFramework
import Intents

extension INPerson {
    convenience init(contact: Contact) {
        let handle = INPersonHandle(value: contact.emailAddress, type: .emailAddress)
        self.init(personHandle: handle, nameComponents: contact.nameComponents, displayName: contact.formattedName, image: nil, contactIdentifier: nil, customIdentifier: nil)
    }
}

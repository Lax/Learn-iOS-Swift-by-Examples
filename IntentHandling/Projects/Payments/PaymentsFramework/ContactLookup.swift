/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class that mimics asynchronous lookups of contacts.
*/


public class ContactLookup {
    
    public var contacts = Contact.sampleContacts
    
    public init() {}
    
    public func lookup(displayName: String, completion: (_ contacts: [Contact]) -> Void) {
        /*
            Here we are searching through a local array of contacts. This could
            instead be an asynchronous call to a remote server.
         */
        let nameFormatter = PersonNameComponentsFormatter()
        
        let matchingContacts = contacts.filter { contact in
            nameFormatter.style = .medium
            if nameFormatter.string(from: contact.nameComponents) == displayName {
                return true
            }
            
            nameFormatter.style = .short
            if nameFormatter.string(from: contact.nameComponents) == displayName {
                return true
            }
            
            return false
        }
        
        completion(matchingContacts)
    }
    
    public func lookup(emailAddress: String, completion: (_ contact: Contact?) -> Void) {
        /*
            Here we are searching through a local array of contacts. This could
            instead be an asynchronous call to a remote server.
         */
        for contact in contacts where contact.emailAddress == emailAddress {
            completion(contact)
        }
        
        completion(nil)
    }
}

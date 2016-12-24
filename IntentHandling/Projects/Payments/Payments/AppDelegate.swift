/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application delegate.
*/

import UIKit
import Intents
import PaymentsFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        // Register names of contacts that may not be in the user's address book.
        let contactNames = Contact.sampleContacts.map { $0.formattedName }
        INVocabulary.shared().setVocabularyStrings(NSOrderedSet(array: contactNames), of: .contactName)
    }
}

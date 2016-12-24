/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The main extension entry point.
*/

import Intents
import PaymentsFramework

class IntentsExtension: INExtension {
    
    let paymentProvider = PaymentProvider()
    
    let contactLookup = ContactLookup()
    
    override func handler(for intent: INIntent) -> Any? {
        // Our sample is only configured to handle the `INSendPaymentIntent`.
        guard intent is INSendPaymentIntent else { fatalError("Unhandled intent type \(intent)") }

        return SendPaymentIntentHandler(paymentProvider: paymentProvider, contactLookup: contactLookup)
    }
}

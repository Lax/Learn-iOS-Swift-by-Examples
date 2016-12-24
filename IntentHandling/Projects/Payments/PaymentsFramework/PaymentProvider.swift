/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class tha mimics asynchronous calls to send payments to a server.
*/

import Foundation

public class PaymentProvider {
    
    // MARK: Properties
    
    public var mostRecentPayment: Payment? {
        let paymentHistory = loadPaymentHistory()
        return paymentHistory.last
    }
    
    // MARK: Intialization
    
    public init() {}
    
    // MARK: Payment methods
    
    public func canSend(_ payment: Payment, completion: (_ success: Bool, _ error: NSError?) -> Void) {
        /*
            For the purposes of this sample, we don't have a server-side component.
            Instead we just accept any payment.
        */
        
        completion(true, nil)
    }
    
    public func send(_ payment: Payment, completion: (_ success: Bool, _ sentPayment: Payment?, _ error: NSError?) -> Void) {
        /*
            For the purposes of this sample, we don't have a server-side component.
            Instead we're just storing payment locally.
        */
        
        // Create a new `Payment` that includes the current date as the date it was made.
        let datedPayment = Payment(contact: payment.contact, amount: payment.amount, currencyCode: payment.currencyCode, date: Date())
        
        // Add the dated payment to the payment history and save it.
        var paymentHistory = loadPaymentHistory()
        paymentHistory.append(datedPayment)
        save(paymentHistory)
        
        // Call the completion handler.
        completion(true, datedPayment, nil)
    }
    
    // MARK: Convenience
    
    public func validate(_ currencyCode: String) -> String? {
        if currencyCode == "USD" || currencyCode == "AMBIGUOUS_DOLLAR" {
            return "USD"
        }
        else {
            return nil
        }
    }
    
    public func loadPaymentHistory() -> [Payment] {
        var paymentHistory = [Payment]()
        
        // Parse payments from the shared `NSUserDefaults`.
        let defaults = makeUserDefaults()
        if let paymentsDictionaries = defaults.object(forKey: "paymentHistory") as? [[String: AnyObject]] {
            paymentHistory = paymentsDictionaries.flatMap { Payment(dictionaryRepresentation: $0) }
        }
        
        return paymentHistory
    }
    
    private func save(_ payments: [Payment]) {
        // Make sure the number of payments isn't too large
        let paymentsToSave = payments.suffix(50)
        
        /*
            Convert the payments to an array of dictionaries that can be saved in
            user defaults.
        */
        let paymentsDictionaries: [[String: Any]] = paymentsToSave.map { $0.dictionaryRepresentation }
        
        // Save the payments to shared `NSUserDefaults`.
        let defaults = makeUserDefaults()
        defaults.set(paymentsDictionaries as AnyObject, forKey: "paymentHistory")
    }
    
    private func makeUserDefaults() -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: "group.com.example.apple-samplecode.Payments") else { fatalError("Unable to make shared NSUserDefaults object") }
        return defaults
    }
}

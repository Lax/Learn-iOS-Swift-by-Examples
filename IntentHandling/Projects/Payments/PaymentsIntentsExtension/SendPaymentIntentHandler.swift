/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class that implements `INSendPaymentIntentHandling` to handle `INSendPaymentIntent`s
*/

import Intents
import PaymentsFramework

class SendPaymentIntentHandler: NSObject, INSendPaymentIntentHandling {
    // MARK: Properties
    
    private let paymentProvider: PaymentProvider
    
    private let contactLookup: ContactLookup
    
    // MARK: Initialization
    
    init(paymentProvider: PaymentProvider, contactLookup: ContactLookup) {
        self.paymentProvider = paymentProvider
        self.contactLookup = contactLookup
    }
    
    // MARK: INSendPaymentIntentHandling parameter resolution

    func resolvePayee(forSendPayment intent: INSendPaymentIntent, with completion: @escaping (INPersonResolutionResult) -> Void) {
        if let payee = intent.payee {
            // Lookup contacts that match the payee.
            contactLookup.lookup(displayName: payee.displayName) { contacts in
                // Build the `INIntentResolutionResult` to pass to the `completion` closure.
                let result: INPersonResolutionResult
                
                if let contact = contacts.first, contacts.count == 1 {
                    // A single match was found, the payee was successfully resolved.
                    let resolvedPayee = INPerson(contact: contact)
                    result = INPersonResolutionResult.success(with: resolvedPayee)
                }
                else if contacts.isEmpty {
                    // No matches were found.
                    result = INPersonResolutionResult.unsupported()
                }
                else {
                    /*
                        More than one match was made, the user needs to clarify which
                        contact they intended.
                     */
                    let people: [INPerson] = contacts.map { contact in
                        return INPerson(contact: contact)
                    }
                    result = INPersonResolutionResult.disambiguation(with: people)
                }

                completion(result)
            }
        }
        else if let mostRecentPayee = paymentProvider.mostRecentPayment?.contact {
            // No payee has been provided, suggest the last payee.
            let result = INPersonResolutionResult.confirmationRequired(with: INPerson(contact: mostRecentPayee))
            completion(result)
        }
        else {
            // No payee has been provided and there was no previous payee.
            let result = INPersonResolutionResult.needsValue()
            completion(result)
        }
    }
    
    func resolveCurrencyAmount(forSendPayment intent: INSendPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void) {
        let result: INCurrencyAmountResolutionResult
        
        // Resolve the currency amount.
        if let currencyAmount = intent.currencyAmount, let amount = currencyAmount.amount, let currencyCode = currencyAmount.currencyCode {
            if amount.intValue <= 0 {
                // The amount needs to be a positive value.
                result = INCurrencyAmountResolutionResult.unsupported()
            }
            else if let currencyCode = paymentProvider.validate(currencyCode) {
                // Make a new `INCurrencyAmount` with the resolved currency code.
                let resolvedAmount = INCurrencyAmount(amount: amount, currencyCode: currencyCode)
                result = INCurrencyAmountResolutionResult.success(with: resolvedAmount)
            }
            else {
                // The currency is unsupported.
                result = INCurrencyAmountResolutionResult.unsupported()
            }
        }
        else if let mostRecentPayment = paymentProvider.mostRecentPayment {
            // No amount has been provided, suggest the last amount sent.
            let suggestedAmount = INCurrencyAmount(amount: mostRecentPayment.amount, currencyCode: mostRecentPayment.currencyCode)
            result = INCurrencyAmountResolutionResult.confirmationRequired(with: suggestedAmount)
        }
        else {
            // No amount has been provided and there was no previous payment.
            result = INCurrencyAmountResolutionResult.needsValue()
        }
        
        completion(result)
    }
    
    // MARK: INSendPaymentIntentHandling intent confirmation

    func confirm(sendPayment intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Void) {
        guard let payee = intent.payee,
            let payeeHandle = payee.personHandle,
            let currencyAmount = intent.currencyAmount,
            let amount = currencyAmount.amount,
            let currencyCode = currencyAmount.currencyCode
        else {
            completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        contactLookup.lookup(emailAddress: payeeHandle.value) { contact in
            guard let contact = contact else {
                completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
                return
            }
            
            let payment = Payment(contact: contact, amount: amount, currencyCode: currencyCode)

            self.paymentProvider.canSend(payment) { success, error in
                guard success else {
                    completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
                    return
                }

                let response = INSendPaymentIntentResponse(code: .success, userActivity: nil)
                response.paymentRecord = self.makePaymentRecord(for: intent)
                
                completion(response)
            }
        }
    }
    
    // MARK: INSendPaymentIntentHandling intent handling

    func handle(sendPayment intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Void) {
        guard let payee = intent.payee,
            let payeeHandle = payee.personHandle,
            let currencyAmount = intent.currencyAmount,
            let amount = currencyAmount.amount,
            let currencyCode = currencyAmount.currencyCode
        else {
            completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        contactLookup.lookup(emailAddress: payeeHandle.value) { contact in
            guard let contact = contact else {
                completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
                return
            }

            let payment = Payment(contact: contact, amount: amount, currencyCode: currencyCode)

            self.paymentProvider.send(payment) { success, _, _ in
                guard success else {
                    completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
                    return
                }

                let response = INSendPaymentIntentResponse(code: .success, userActivity: nil)
                response.paymentRecord = self.makePaymentRecord(for: intent)
                
                completion(response)
            }
        }
    }
    
    // MARK: Convenience
    
    func makePaymentRecord(for intent: INSendPaymentIntent, status: INPaymentStatus = .completed) -> INPaymentRecord? {
        let paymentMethod = INPaymentMethod(type: .unknown, name: "Payments Sample", identificationHint: nil, icon: nil)
        
        return INPaymentRecord(
            payee: intent.payee,
            payer: nil,
            currencyAmount: intent.currencyAmount,
            paymentMethod: paymentMethod,
            note: intent.note,
            status: status
        )
    }
}

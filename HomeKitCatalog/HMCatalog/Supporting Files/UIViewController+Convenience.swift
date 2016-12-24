/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `UIViewController+Convenience` methods allow for easy presentation of common views.
*/

import HomeKit
import UIKit

extension UIViewController {
    
    /**
        Displays a `UIAlertController` on the main thread with the error's `localizedDescription` at the body.
        
        - parameter error: The error to display.
    */
    func displayError(error: NSError) {
        if let errorCode = HMErrorCode(rawValue: error.code) {
            if self.presentedViewController != nil || errorCode == .OperationCancelled || errorCode == .UserDeclinedAddingUser {
                print(error.localizedDescription)
            }
            else {
                self.displayErrorMessage(error.localizedDescription)
            }
        }
        else {
            self.displayErrorMessage(error.description)
        }
    }
    
    /**
        Displays a collection of errors, separated by newlines.
        
        - parameter errors: An array of `NSError`s to display.
    */
    func displayErrors(errors: [NSError]) {
        var messages = [String]()
        for error in errors {
            if let errorCode = HMErrorCode(rawValue: error.code) {
                if self.presentedViewController != nil || errorCode == .OperationCancelled || errorCode == .UserDeclinedAddingUser {
                    print(error.localizedDescription)
                }
                else {
                    messages.append(error.localizedDescription)
                }
            }
            else {
                messages.append(error.description)
            }
        }
        
        if messages.count > 0 {
            // There were errors in the list, reduce the messages into a single one.
            let collectedMessage = messages.reduce("", combine: { (accumulator, message) -> String in
                return accumulator + "\n" + message
            })
            self.displayErrorMessage(collectedMessage)
        }
    }
    
    /// Displays a `UIAlertController` with the passed-in text and an 'Okay' button.
    func displayMessage(title: String, message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: title, body: message)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    /**
        Displays `UIAlertController` with a message and a localized "Error" title.
        
        - parameter message: The message to display.
    */
    private func displayErrorMessage(message: String) {
        let errorTitle = NSLocalizedString("Error", comment: "Error")
        displayMessage(errorTitle, message: message)
    }
    
    /**
        Presents a simple `UIAlertController` with a textField, set up to
        accept a name. Once the name is entered, the completion handler will
        be called and the name will be passed in.
        
        - parameter attributeType: The kind of object being added
        - parameter completion:    The block to run when the user taps the add button.
    */
    func presentAddAlertWithAttributeType(type: String, placeholder: String? = nil, shortType: String? = nil, completion: (String) -> Void) {
        let alertController = UIAlertController(attributeType: type, completionHandler: completion, placeholder: placeholder, shortType: shortType)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}
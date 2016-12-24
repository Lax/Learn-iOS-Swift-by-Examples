/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `UIAlertController+Convenience` methods allow for quick construction of `UIAlertController`s with common structures.
*/

import UIKit

extension UIAlertController {
    
    /**
        A simple `UIAlertController` that prompts for a name, then runs a completion block passing in the name.
        
        - parameter attributeType:  The type of object that will be named.
        - parameter completion:     A block to call, passing in the provided text.
        - parameter placeholder:    An optional string used as text field's placeholder text.
        - parameter shortType:      An optional string used as to form the alert's action title.
     
        - returns:   A `UIAlertController` instance with a UITextField, cancel button, and add button.
    */
    convenience init(attributeType: String, completionHandler: (name: String) -> Void, placeholder: String? = nil, shortType: String? = nil) {
        let title = NSLocalizedString("New", comment: "New") + " \(attributeType)"
        let message = NSLocalizedString("Enter a name.", comment: "Enter a name.")
        self.init(title: title, message: message, preferredStyle: .Alert)
        self.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = placeholder ?? attributeType
            textField.autocapitalizationType = .Words
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel) { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        let add = NSLocalizedString("Add", comment: "Add")
        let actionTitle = "\(add) \(shortType ?? attributeType)"
        let addNewObject = UIAlertAction(title: actionTitle, style: .Default) { action in
            if let name = self.textFields!.first!.text {
                let trimmedName = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                completionHandler(name: trimmedName)
            }
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.addAction(cancelAction)
        self.addAction(addNewObject)
    }
    
    /**
        A simple `UIAlertController` made to show an error message that's passed in.
        
        - parameter body: The body of the alert.
        
        - returns:  A `UIAlertController` with an 'Okay' button.
    */
    convenience init(title: String, body: String) {
        self.init(title: title, message: body, preferredStyle: .Alert)
        let okayAction = UIAlertAction(title: NSLocalizedString("Okay", comment: "Okay"), style: .Default) { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        self.addAction(okayAction)
    }
}
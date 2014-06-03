/*
        File: AlertControllerViewController.swift
    Abstract: 
                The view controller that demonstrates how to use UIAlertController.
            
     Version: 1.0
    
    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
    Inc. ("Apple") in consideration of your agreement to the following
    terms, and your use, installation, modification or redistribution of
    this Apple software constitutes acceptance of these terms.  If you do
    not agree with these terms, please do not use, install, modify or
    redistribute this Apple software.
    
    In consideration of your agreement to abide by the following terms, and
    subject to these terms, Apple grants you a personal, non-exclusive
    license, under Apple's copyrights in this original Apple software (the
    "Apple Software"), to use, reproduce, modify and redistribute the Apple
    Software, with or without modifications, in source and/or binary forms;
    provided that if you redistribute the Apple Software in its entirety and
    without modifications, you must retain this notice and the following
    text and disclaimers in all such redistributions of the Apple Software.
    Neither the name, trademarks, service marks or logos of Apple Inc. may
    be used to endorse or promote products derived from the Apple Software
    without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or
    implied, are granted by Apple herein, including but not limited to any
    patent rights that may be infringed by your derivative works or by other
    works in which the Apple Software may be incorporated.
    
    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
    MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
    OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
    
    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
    MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
    AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
    STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
    
    Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/

import UIKit

class AlertControllerViewController : UITableViewController {
    // MARK: Properties
    weak var secureTextAlertAction: UIAlertAction?

    // MARK: UIAlertControllerStyleAlert Style Alerts

    // Show an alert with an "Okay" button.
    func showSimpleAlert() {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("OK", comment: "")

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        // Create the action.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .Cancel) { action in
            NSLog("The simple alert's cancel action occured.")
        }

        // Add the action.
        alertController.addAction(cancelAction)

        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // Show an alert with an "Okay" and "Cancel" button.
    func showOkayCancelAlert() {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitle = NSLocalizedString("OK", comment: "")
        
        let alertCotroller = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .Cancel) { action in
            NSLog("The \"Okay/Cancel\" alert's cancel action occured.")
        }
        
        let otherAction = UIAlertAction(title: otherButtonTitle, style: .Default) { action in
            NSLog("The \"Okay/Cancel\" alert's other action occured.")
        }
        
        // Add the actions.
        alertCotroller.addAction(cancelAction)
        alertCotroller.addAction(otherAction)

        presentViewController(alertCotroller, animated: true, completion: nil)
    }

    // Show an alert with two custom buttons.
    func showOtherAlert() {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitleOne = NSLocalizedString("Coice One", comment: "")
        let otherButtonTitleTwo = NSLocalizedString("Choice Two", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .Cancel) { action in
            NSLog("The \"Other\" alert's cancel action occured.")
        }
        
        let otherButtonOneAction = UIAlertAction(title: otherButtonTitleOne, style: .Default) { action in
            NSLog("The \"Other\" alert's other button one action occured.")
        }
        
        let otherButtonTwoAction = UIAlertAction(title: otherButtonTitleTwo, style: .Default) { action in
            NSLog("The \"Other\" alert's other button two action occured.")
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherButtonOneAction)
        alertController.addAction(otherButtonTwoAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }

    // Show a text entry alert with two custom buttons.
    func showTextEntryAlert() {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitle = NSLocalizedString("OK", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        // Add the text field for text entry.
        alertController.addTextFieldWithConfigurationHandler { textField in
            // If you need to customize the text field, you can do so here.
        }

        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .Cancel) { action in
            NSLog("The \"Text Entry\" alert's cancel action occured.")
        }
        
        let otherAction = UIAlertAction(title: otherButtonTitle, style: .Default) { action in
            NSLog("The \"Text Entry\" alert's other action occured.")
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // Show a secure text entry alert with two custom buttons.
    func showSecureTextEntryAlert() {
        let title = NSLocalizedString("A Short Title is Best", comment: "")
        let message = NSLocalizedString("A message should be a short, complete sentence.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitle = NSLocalizedString("OK", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        // Add the text field for the secure text entry.
        alertController.addTextFieldWithConfigurationHandler { textField in
            // Listen for changes to the text field's text so that we can toggle the current
            // action's enabled property based on whether the user has entered a sufficiently
            // secure entry.
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleTextFieldTextDidChangeNotification:", name: UITextFieldTextDidChangeNotification, object: textField)
            
            textField.secureTextEntry = true
        }
        
        // Stop listening for text change notifications on the text field. This func will be called in the two action handlers.
        func removeTextFieldObserver() {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: alertController.textFields[0])
        }
        
        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .Cancel) { action in
            NSLog("The \"Secure Text Entry\" alert's cancel action occured.")
            
            removeTextFieldObserver()
        }
        
        let otherAction = UIAlertAction(title: otherButtonTitle, style: .Default) { action in
            NSLog("The \"Secure Text Entry\" alert's other action occured.")
            
            removeTextFieldObserver()
        }
        
        // The text field initially has no text in the text field, so we'll disable it.
        otherAction.enabled = false
        
        // Hold onto the secure text alert action to toggle the enabled/disabled state when the text changed.
        secureTextAlertAction = otherAction
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(otherAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: UIAlertControllerStyleActionSheet Style Alerts
    
    // Show a dialog with an "Okay" and "Cancel" button.
    func showOkayCancelActionSheet() {
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "OK")
        let destructiveButtonTitle = NSLocalizedString("OK", comment: "")
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        // Create the actions.
        let cancelAction = UIAlertActiotryAlert
            ],
            // Action sheet style alerts.
            [
                showOkayCancelActionSheet,
                showOtherActionSheet
            ]
        ]

        let action = actionMap[indexPath.section][indexPath.row]
        
        action()

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

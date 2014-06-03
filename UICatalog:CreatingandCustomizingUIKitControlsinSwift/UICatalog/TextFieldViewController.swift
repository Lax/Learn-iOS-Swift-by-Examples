/*
        File: TextFieldViewController.swift
    Abstract: 
                A view controller that demonstrates how to use UITextField.
            
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

class TextFieldViewController: UITableViewController, UITextFieldDelegate {
    // MARK: Properties
    @IBOutlet var textField: UITextField
    @IBOutlet var tintedTextField: UITextField
    @IBOutlet var secureTextField: UITextField
    @IBOutlet var specificKeyboardTextField: UITextField
    @IBOutlet var customTextField: UITextField

    // Mark: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTextField()
        configureTintedTextField()
        configureSecureTextField()
        configureSpecificKeyboardTextField()
        configureCustomTextField()
    }

    // MARK: Configuration
    func configureTextField() {
        textField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        textField.autocorrectionType = .Yes
        textField.returnKeyType = .Done
        textField.clearButtonMode = .Never
    }

    func configureTintedTextField() {
        tintedTextField.tintColor = UIColor.applicationBlueColor()
        tintedTextField.textColor = UIColor.applicationGreenColor()

        tintedTextField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        tintedTextField.returnKeyType = .Done
        tintedTextField.clearButtonMode = .Never
    }

    func configureSecureTextField() {
        secureTextField.secureTextEntry = true

        secureTextField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        secureTextField.returnKeyType = .Done
        secureTextField.clearButtonMode = .Always
    }

    // There are many different types of keyboards that you may choose to use.
    // The different types of keyboards are defined in the UITextInputTraits interface.
    // This example shows how to display a keyboard to help enter email addresses.
    func configureSpecificKeyboardTextField() {
        specificKeyboardTextField.keyboardType = .EmailAddress

        specificKeyboardTextField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        specificKeyboardTextField.returnKeyType = .Done
    }

    func configureCustomTextField() {
        // Text fields with custom image backgrounds must have no border.
        customTextField.borderStyle = .None

        customTextField.background = UIImage(named: "text_field_background")

        // Create a purple button that, when selected, turns the custom text field's text color
        // to purple.
        let purpleImage = UIImage(named: "text_field_purple_right_view")
        let purpleImageButton = UIButton.buttonWithType(.Custom) as UIButton
        purpleImageButton.bounds = CGRect(x: 0, y: 0, width: purpleImage.size.width, height: purpleImage.size.height)
        purpleImageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        purpleImageButton.setImage(purpleImage, forState: .Normal)
        purpleImageButton.addTarget(self, action: "customTextFieldPurpleButtonClicked", forControlEvents: .TouchUpInside)
        customTextField.rightView = purpleImageButton
        customTextField.rightViewMode = .Always

        // Add an empty view as the left view to ensure inset between the text and the bounding rectangle.
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        leftPaddingView.backgroundColor = UIColor.clearColor()
        customTextField.leftView = leftPaddingView
        customTextField.leftViewMode = .Always

        customTextField.placeholder = NSLocalizedString("Placeholder text", comment: "")
        customTextField.autocorrectionType = .No
        customTextField.returnKeyType = .Done
    }

    // MARK: UITextFieldDelegate (set in Interface Builder)
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }

    // MARK: Actions
    func customTextFieldPurpleButtonClicked() {
        customTextField.textColor = UIColor.applicationPurpleColor()

        NSLog("The custom text field's purple right view button was clicked.")
    }
}

/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UITextField.
*/

import UIKit

class TextFieldViewController: UITableViewController, UITextFieldDelegate {
    // MARK: Properties

    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var tintedTextField: UITextField!
    
    @IBOutlet weak var secureTextField: UITextField!
    
    @IBOutlet weak var specificKeyboardTextField: UITextField!
    
    @IBOutlet weak var customTextField: UITextField!

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

    /// There are many different types of keyboards that you may choose to use.
    /// The different types of keyboards are defined in the UITextInputTraits interface.
    /// This example shows how to display a keyboard to help enter email addresses.
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
        let purpleImage = UIImage(named: "text_field_purple_right_view")!
        let purpleImageButton = UIButton.buttonWithType(.Custom) as! UIButton
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

    // MARK: UITextFieldDelegate

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

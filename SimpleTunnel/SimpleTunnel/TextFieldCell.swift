/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the TextFieldCell class, which is a UITableViewCell sub-class for a cell that contains a UITextField.
*/

import UIKit

/// A custom table view object that contains a text field.
class TextFieldCell : UITableViewCell, UITextFieldDelegate {

	// MARK: Properties

	/// The text input field.
	@IBOutlet weak var textField: UITextField!

	/// The block to call when the value of the text field changes.
	var valueChanged: ((Void) -> Void)?

	// MARK: UITextFieldDelegate

	/// Handle the event of the user finishing changing the value of the text field.
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.resignFirstResponder()

		valueChanged?()
	}

	/// Dismiss the keyboard
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}

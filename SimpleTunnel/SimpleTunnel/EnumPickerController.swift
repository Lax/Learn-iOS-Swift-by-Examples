/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the EnumPickerController class, which is used to control a view containing a UIPickerView.
*/

import UIKit

/// A view controller for a view that contains a picker view for selecting a value in an enum.
class EnumPickerController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

	// MARK: Properties

	/// The values that can be selected in the picker view.
	var enumValues = [String]()

	/// The index of the currently-selected value.
	var currentValue: Int?

	/// The picker view.
	@IBOutlet weak var enumPicker: UIPickerView!

	/// The title to display for the view.
	var enumTitle: String?

	/// A block to execute when the selected value changes.
	var selectionChangeHandler: (Int) -> Void = { newRow in return }

	// MARK: Interface

	/// Set the enum values to display, the title of the view, the index of the currently-selected value, and a block to execute when the selected value changes.
	func setValues(_ values: [String], title: String, currentSelection: Int?, selectionChanged: @escaping (Int) -> Void) {
		enumValues = values
		enumTitle = title
		currentValue = currentSelection
		selectionChangeHandler = selectionChanged
	}

	// MARK: UIViewController

	/// Handle the event when the view is being displayed.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationItem.title = enumTitle

		enumPicker.reloadAllComponents()
		if let row = currentValue {
			enumPicker.selectRow(row, inComponent: 0, animated: false)
		}
	}

	// MARK: UIPickerViewDataSource

	/// Return the number of components in the picker, always returns 1.
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}

	/// Returns the number of enum values.
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return enumValues.count 
	}

	// MARK: UIPickerViewDelegate

	/// Returns the enum value at the given row.
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
		return NSAttributedString(string: enumValues[row])
	}

	/// Handle the user selecting a value in the picker.
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		selectionChangeHandler(row)
	}
}

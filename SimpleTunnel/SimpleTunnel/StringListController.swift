/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the StringListController class, which controls a list of strings.
*/

import UIKit

/// A view controller of a view that displays an editable list of strings.
class StringListController: ListViewController {

	// MARK: Properties

	/// The current list of strings.
	var targetStrings = [String]()

	/// The text to display in the "add a string" text field.
	var addText: String?

	/// The title to display for the list.
	var listTitle: String?

	/// The block to execute when the list of strings changes.
	var stringsChangedHandler: ([String]) -> Void = { strings in return }

	/// A table view cell containing a text field used to enter new strings to be added to the list.
	@IBOutlet weak var addStringCell: TextFieldCell!

	/// The number of strings in the list.
	override var listCount: Int {
		return targetStrings.count 
	}

	/// Returns UITableViewCellSelectionStyle.None
	override var listCellSelectionStyle: UITableViewCellSelectionStyle {
		return .none
	}

	// MARK: UIViewController

	/// Handle the event when the view is loaded into memory.
	override func viewDidLoad() {
		isAddEnabled = true
		isAlwaysEditing = true

		addStringCell.valueChanged = {
			guard let enteredText = self.addStringCell.textField.text else { return }

			self.targetStrings.append(enteredText)
			self.listInsertItemAtIndex(self.targetStrings.count - 1)
			self.addStringCell.textField.text = ""
			self.stringsChangedHandler(self.targetStrings)
		}

		// Set addStringCell as a custom "add a new item" cell.
		addCell = addStringCell

		super.viewDidLoad()
	}

	/// Handle the event when the view is being displayed.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		addStringCell.textField.placeholder = addText
		navigationItem.title = listTitle
	}

	// MARK: ListViewController

	/// Return the string at the given index.
	override func listTextForItemAtIndex(_ index: Int) -> String {
		return targetStrings[index] 
	}

	/// Remove the string at the given index.
	override func listRemoveItemAtIndex(_ index: Int) {
		targetStrings.remove(at: index)
		stringsChangedHandler(targetStrings)
	}

	// MARK: Interface

	/// Set the list of strings, the title to display for the list, the text used to prompt the user for a new string, and a block to execute when the list of strings changes.
	func setTargetStrings(_ strings: [String]?, title: String, addTitle: String, saveHandler: @escaping ([String]) -> Void) {
		targetStrings = strings ?? [String]()
		listTitle = title
		addText = addTitle
		stringsChangedHandler = saveHandler
	}
}

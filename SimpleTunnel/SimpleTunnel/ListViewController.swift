/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ListViewController class, which is responsible for controlling a list items.
*/

import UIKit

/// A view controller base class for a view that displays a list of items in table form.
class ListViewController: UITableViewController {

	// MARK: Properties

	/// A flag indicating that UI controls for adding an item to the list should be displayed.
	var isAddEnabled = false

	/// A flag indicating that UI controls for adding an item to the list should always be displayed.
	var isAlwaysEditing = false

	/// A custom cell for adding items to the list.
	var addCell: UITableViewCell?

	/// The number of items currently in the list.
	var listCount: Int { return 0 }

	/// The type of table view cell accessory image to display for each item in the list.
	var listAccessoryType: UITableViewCellAccessoryType {
		return .none
	}

	/// The type of table view cell accessory image to display for each item in the list while the list is being edited.
	var listEditingAccessoryType: UITableViewCellAccessoryType {
		return .none
	}

	/// The type of selection feedback to display items in the list.
	var listCellSelectionStyle: UITableViewCellSelectionStyle {
		return .default
	}

	/// The text to display in the "add a new item" cell.
	var listAddButtonText: String {
		return "Add Configuration..."
	}

	// MARK: Initializers

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	init() {
		super.init(style: .grouped)
	}

	// MARK: UIViewController

	/// Handle the event of the view being loaded into memory.
	override func viewDidLoad() {
		super.viewDidLoad()
		if isAlwaysEditing {
			tableView.isEditing = true
		}
		else {
			navigationItem.rightBarButtonItem = editButtonItem
		}
	}

	/// Handle the event of the view being displayed.
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		tableView.reloadData()
	}

	/// Prepare for a segue away from this view controller.
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let cell = sender as? UITableViewCell,
			let indexPath = tableView.indexPath(for: cell)
			else { return }

		listSetupSegue(segue, forItemAtIndex: (indexPath as NSIndexPath).row)
	}

	// MARK: UITableView

	/// Enable editing mode on the UITableView.
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)

		if isAddEnabled {
			// Insert or delete the last row in the table (i.e., the "add a new item" row).
			let indexPath = IndexPath(item: listCount, section: 0)
			if editing {
				tableView.insertRows(at: [indexPath], with: .bottom)
			}
			else {
				tableView.deleteRows(at: [indexPath], with: .bottom)
			}
		}
	}

	// MARK: UITableViewDataSource

	/// Always returns 1.
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	/// Returns the number of items in the list, incremented by 1 if the list is in edit mode.
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		var count = listCount
		if tableView.isEditing {
			count += 1
		}
		return count
	}

	/// Returns a cell displaying details about the item at the given index path.
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell = UITableViewCell()
		if (indexPath as NSIndexPath).item < listCount {
			// Return a cell containing details about an item in the list.
			if let itemCell = tableView.dequeueReusableCell(withIdentifier: "item-cell") {
				cell = itemCell
				cell.textLabel?.text = listTextForItemAtIndex((indexPath as NSIndexPath).row)
				cell.accessoryType = listAccessoryType
				cell.editingAccessoryType = listEditingAccessoryType
				cell.imageView?.image = listImageForItemAtIndex((indexPath as NSIndexPath).row)
			}
		}
		else if tableView.isEditing && (indexPath as NSIndexPath).item == listCount {
			// The list is in edit mode, return the appropriate "add" cell.
			if addCell != nil {
				cell = addCell!
			}
			else if let addButtonCell = tableView.dequeueReusableCell(withIdentifier: "add-button") {
				cell = addButtonCell
				cell.textLabel?.text = listAddButtonText
				cell.editingAccessoryType = .none
			}
		}

		return cell
	}

	/// Always returns true, all cells can be edited in the list
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	/// Make changes to the list per the given editing style and target row.
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		switch editingStyle {
		case .delete:
			listRemoveItemAtIndex((indexPath as NSIndexPath).row)
			tableView.deleteRows(at: [ indexPath ], with: .bottom)
		default:
			break
		}
	}

	// MARK: UITableViewDelegate

	/// Return the editing style for a row in the table. Returns "Delete" editing style for all items except for the last item, which uses the "Insert" style.
	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		if (indexPath as NSIndexPath).item < listCount {
			return .delete
		}
		else {
			return .insert
		}
	}

	// MARK: Interface 

	/// Prepare to segue away from this view controller as the result of the user tapping on an item in the list.
	func listSetupSegue(_ segue: UIStoryboardSegue, forItemAtIndex index: Int) {
	}

	/// Insert a new item into the list.
	func listInsertItemAtIndex(_ index: Int) {
		tableView.insertRows(at: [ IndexPath(row: index, section: 0) ], with: .bottom)
	}

	/// Get the text to display for an item in the list.
	func listTextForItemAtIndex(_ index: Int) -> String {
		return ""
	}

	/// Get the image to display for an item in the list.
	func listImageForItemAtIndex(_ index: Int) -> UIImage? {
		return nil
	}

	/// Remove an item from the list.
	func listRemoveItemAtIndex(_ index: Int) {
	}
}

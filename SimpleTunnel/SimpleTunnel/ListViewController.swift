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
		return .None
	}

	/// The type of table view cell accessory image to display for each item in the list while the list is being edited.
	var listEditingAccessoryType: UITableViewCellAccessoryType {
		return .None
	}

	/// The type of selection feedback to display items in the list.
	var listCellSelectionStyle: UITableViewCellSelectionStyle {
		return .Default
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
		super.init(style: .Grouped)
	}

	// MARK: UIViewController

	/// Handle the event of the view being loaded into memory.
	override func viewDidLoad() {
		super.viewDidLoad()
		if isAlwaysEditing {
			tableView.editing = true
		}
		else {
			navigationItem.rightBarButtonItem = editButtonItem()
		}
	}

	/// Handle the event of the view being displayed.
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		tableView.reloadData()
	}

	/// Prepare for a segue away from this view controller.
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let cell = sender as? UITableViewCell,
			indexPath = tableView.indexPathForCell(cell)
			else { return }

		listSetupSegue(segue, forItemAtIndex: indexPath.row)
	}

	// MARK: UITableView

	/// Enable editing mode on the UITableView.
	override func setEditing(editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)

		if isAddEnabled {
			// Insert or delete the last row in the table (i.e., the "add a new item" row).
			let indexPath = NSIndexPath(forItem: listCount, inSection: 0)
			if editing {
				tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
			}
			else {
				tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
			}
		}
	}

	// MARK: UITableViewDataSource

	/// Always returns 1.
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	/// Returns the number of items in the list, incremented by 1 if the list is in edit mode.
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		var count = listCount
		if tableView.editing {
			count += 1
		}
		return count
	}

	/// Returns a cell displaying details about the item at the given index path.
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = UITableViewCell()
		if indexPath.item < listCount {
			// Return a cell containing details about an item in the list.
			if let itemCell = tableView.dequeueReusableCellWithIdentifier("item-cell") {
				cell = itemCell
				cell.textLabel?.text = listTextForItemAtIndex(indexPath.row)
				cell.accessoryType = listAccessoryType
				cell.editingAccessoryType = listEditingAccessoryType
				cell.imageView?.image = listImageForItemAtIndex(indexPath.row)
			}
		}
		else if tableView.editing && indexPath.item == listCount {
			// The list is in edit mode, return the appropriate "add" cell.
			if addCell != nil {
				cell = addCell!
			}
			else if let addButtonCell = tableView.dequeueReusableCellWithIdentifier("add-button") {
				cell = addButtonCell
				cell.textLabel?.text = listAddButtonText
				cell.editingAccessoryType = .None
			}
		}

		return cell
	}

	/// Always returns true, all cells can be edited in the list
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}

	/// Make changes to the list per the given editing style and target row.
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		switch editingStyle {
		case .Delete:
			listRemoveItemAtIndex(indexPath.row)
			tableView.deleteRowsAtIndexPaths([ indexPath ], withRowAnimation: .Bottom)
		default:
			break
		}
	}

	// MARK: UITableViewDelegate

	/// Return the editing style for a row in the table. Returns "Delete" editing style for all items except for the last item, which uses the "Insert" style.
	override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		if indexPath.item < listCount {
			return .Delete
		}
		else {
			return .Insert
		}
	}

	// MARK: Interface 

	/// Prepare to segue away from this view controller as the result of the user tapping on an item in the list.
	func listSetupSegue(segue: UIStoryboardSegue, forItemAtIndex index: Int) {
	}

	/// Insert a new item into the list.
	func listInsertItemAtIndex(index: Int) {
		tableView.insertRowsAtIndexPaths([ NSIndexPath(forRow: index, inSection: 0) ], withRowAnimation: .Bottom)
	}

	/// Get the text to display for an item in the list.
	func listTextForItemAtIndex(index: Int) -> String {
		return ""
	}

	/// Get the image to display for an item in the list.
	func listImageForItemAtIndex(index: Int) -> UIImage? {
		return nil
	}

	/// Remove an item from the list.
	func listRemoveItemAtIndex(index: Int) {
	}
}
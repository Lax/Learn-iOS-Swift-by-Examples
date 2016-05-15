/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the ConfigurationParametersViewController, which is a UITableViewController sub-class that contains a table of configuration parameters.
*/

import UIKit

/// A table view controller for a view that contains a table of configuration parameter input fields.
class ConfigurationParametersViewController: UITableViewController {

	// MARK: Properties

	/// The cells to display in the table.
	var cells = [UITableViewCell]()

	// MARK: UITableViewDataSource

	/// Returns the number of sections in the table (always 1).
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	/// Returns the number of cells currently in the cells list.
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cells.count
	}

	/// Returns the cell at the given index in the cells list.
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return cells[indexPath.row]
	}

	// MARK: Interface

	/// Insert or remove cells into the cells list per the current value of a SwitchCell object.
	func updateCellsWithDependentsOfCell(cell: SwitchCell) {
		if let indexPath = getIndexPathOfCell(cell)
			where !cell.dependentCells.isEmpty
		{
			let index = indexPath.row + 1
			if cell.isOn {
				cells.insertContentsOf(cell.dependentCells, at: index)
			}
			else {
				let removeRange = index..<(index + cell.dependentCells.count)
				cells.removeRange(removeRange)
			}
		}
	}

	/// Return the index of a given cell in the cells list.
	func getIndexPathOfCell(cell: UITableViewCell) -> NSIndexPath? {
		if let row = cells.indexOf({ $0 == cell }) {
			return NSIndexPath(forRow: row, inSection: 0)
		}
		return nil
	}

	/// Construct a description string for a list of items, given a description of a single item.
	func getDescriptionForListValue(listValue: [AnyObject]?, itemDescription: String, placeHolder: String = "Optional") -> String {
		if let list = listValue where !list.isEmpty {
			return "\(list.count) \(itemDescription)" + (list.count > 1 ? "s" : "")
		} else {
			return placeHolder
		}
	}

	/// Construct a description string for a list of strings, given a description of a single string.
	func getDescriptionForStringList(stringList: [String]?, itemDescription: String, placeHolder: String = "Optional") -> String {
		if let list = stringList where !list.isEmpty {
            
			return (list.count <= 3 ? list.joinWithSeparator(", ") : "\(list.count) \(itemDescription)s")
		} else {
			return placeHolder
		}
	}
}

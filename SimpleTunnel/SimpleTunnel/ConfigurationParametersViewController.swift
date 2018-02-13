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
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	/// Returns the number of cells currently in the cells list.
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cells.count
	}

	/// Returns the cell at the given index in the cells list.
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return cells[(indexPath as NSIndexPath).row]
	}

	// MARK: Interface

	/// Insert or remove cells into the cells list per the current value of a SwitchCell object.
	func updateCellsWithDependentsOfCell(_ cell: SwitchCell) {
		if let indexPath = getIndexPathOfCell(cell)
			, !cell.dependentCells.isEmpty
		{
			let index = (indexPath as NSIndexPath).row + 1
			if cell.isOn {
				cells.insert(contentsOf: cell.dependentCells, at: index)
			}
			else {
				let removeRange = index..<(index + cell.dependentCells.count)
				cells.removeSubrange(removeRange)
			}
		}
	}

	/// Return the index of a given cell in the cells list.
	func getIndexPathOfCell(_ cell: UITableViewCell) -> IndexPath? {
		if let row = cells.index(where: { $0 == cell }) {
			return IndexPath(row: row, section: 0)
		}
		return nil
	}

	/// Construct a description string for a list of items, given a description of a single item.
	func getDescriptionForListValue(_ listValue: [AnyObject]?, itemDescription: String, placeHolder: String = "Optional") -> String {
		if let list = listValue , !list.isEmpty {
			return "\(list.count) \(itemDescription)" + (list.count > 1 ? "s" : "")
		} else {
			return placeHolder
		}
	}

	/// Construct a description string for a list of strings, given a description of a single string.
	func getDescriptionForStringList(_ stringList: [String]?, itemDescription: String, placeHolder: String = "Optional") -> String {
		if let list = stringList , !list.isEmpty {
            
			return (list.count <= 3 ? list.joined(separator: ", ") : "\(list.count) \(itemDescription)s")
		} else {
			return placeHolder
		}
	}
}

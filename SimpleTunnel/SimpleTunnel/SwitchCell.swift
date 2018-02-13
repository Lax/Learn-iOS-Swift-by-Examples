/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	This file contains the SwitchCell class, which is a UITableViewCell sub-class for a cell that contains a UISwitch.
*/

import UIKit

/// A custom table cell object that contains a switch
class SwitchCell: UITableViewCell {

	// MARK: Properties

	/// The switch contained in the cell.
	@IBOutlet weak var toggle: UISwitch!

	/// The table view controller of the table view that contains this cell. Used when inserting and removing cells that are conditionally displayed by the switch.
	@IBOutlet weak var tableViewController: UITableViewController!

	/// A list of cells that are inserted/removed from the table based on the value of the switch.
	var dependentCells = [UITableViewCell]()

	/// A block to call to get the index path of this cell int its containing table.
	var getIndexPath: ((Void) -> IndexPath?)?

	/// A block to call when the value of the switch changes.
	var valueChanged: ((Void) -> Void)?

	/// A boolean that toggles the switch.
	var isOn: Bool {
		get {
			return toggle.isOn
		}
		set (newValue) {
			let changed = toggle.isOn != newValue
			toggle.isOn = newValue
			if changed {
				handleValueChanged()
			}
		}
	}

	// MARK: Interface

	/// Handle the user toggling the switch.
	@IBAction func toggled(_ sender: AnyObject) {
		handleValueChanged()
	}

	/// Handle changes in the switch's value.
	func handleValueChanged() {
		valueChanged?()

		guard let switchIndexPath = getIndexPath?() else { return }

		guard dependentCells.count > 0 else { return }
		var indexPaths = [IndexPath]()

		// Create index paths for the dependent cells based on the index path of this cell.
		for row in 1...dependentCells.count {
			indexPaths.append(IndexPath(row: (switchIndexPath as NSIndexPath).row + row, section: (switchIndexPath as NSIndexPath).section))
		}

		guard !indexPaths.isEmpty else { return }

		if toggle.isOn {
			tableViewController.tableView.insertRows(at: indexPaths, with: .bottom)
		} else {
			tableViewController.tableView.deleteRows(at: indexPaths, with: .bottom)
		}
	}
}

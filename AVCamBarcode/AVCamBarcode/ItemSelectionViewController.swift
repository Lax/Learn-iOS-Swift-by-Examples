/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller for selecting items.
*/

import UIKit

protocol ItemSelectionViewControllerDelegate: class {
	func itemSelectionViewController(_ itemSelectionViewController: ItemSelectionViewController, didFinishSelectingItems selectedItems: [String])
}

class ItemSelectionViewController: UITableViewController {
	weak var delegate: ItemSelectionViewControllerDelegate?
	
	var identifier = ""
	
	var allItems = [String]()
	
	var selectedItems = [String]()
	
	var allowsMultipleSelection = false
	
	@IBAction private func done() {
		// Notify the delegate that selecting items is finished.
		delegate?.itemSelectionViewController(self, didFinishSelectingItems: selectedItems)
		
		// Dismiss the view controller.
		dismiss(animated: true, completion: nil)
	}
	
    // MARK: UITableViewDataSource
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = allItems[indexPath.row]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath)
		cell.tintColor = UIColor.black
		cell.textLabel?.text = item
		
		if selectedItems.contains(item) {
			cell.accessoryType = .checkmark
		}
		else {
			cell.accessoryType = .none
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return allItems.count
	}
	
	// MARK: - UITableViewDelegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if allowsMultipleSelection {
			let item = allItems[indexPath.row]
			
			if selectedItems.contains(item) {
				selectedItems = selectedItems.filter({ $0 != item })
			}
			else {
				selectedItems.append(item)
			}
			
			tableView.deselectRow(at: indexPath, animated: true)
			tableView.reloadRows(at: [indexPath], with: .automatic)
		}
		else {
			let indexPathsToReload: [IndexPath]
			if selectedItems.count > 0 {
				indexPathsToReload = [indexPath, IndexPath(row: allItems.index(of: selectedItems[0])!, section: 0)]
			}
			else {
				indexPathsToReload = [indexPath]
			}
			
			selectedItems = [allItems[indexPath.row]]
			
			// Deselect the selected row & reload the table view cells for the old and new items to swap checkmarks.
			tableView.deselectRow(at: indexPath, animated: true)
			tableView.reloadRows(at: indexPathsToReload, with: .automatic)
		}
	}
}

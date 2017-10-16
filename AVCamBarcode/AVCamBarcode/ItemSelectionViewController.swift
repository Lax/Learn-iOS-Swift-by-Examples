/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller for selecting items.
*/

import UIKit

protocol ItemSelectionViewControllerDelegate: class {
	func itemSelectionViewController<Item>(_ itemSelectionViewController: ItemSelectionViewController<Item>, didFinishSelectingItems selectedItems: [Item])
}

class ItemSelectionViewController<Item: Equatable & RawRepresentable>: UITableViewController {
	weak var delegate: ItemSelectionViewControllerDelegate?
	
	let identifier: String
	
	let allItems: [Item]
	
	var selectedItems: [Item]
	
	let allowsMultipleSelection: Bool
	
	private let itemCellIdentifier = "Item"
	
	init(delegate: ItemSelectionViewControllerDelegate, identifier: String, allItems: [Item], selectedItems: [Item], allowsMultipleSelection: Bool) {
		self.delegate = delegate
		self.identifier = identifier
		self.allItems = allItems
		self.selectedItems = selectedItems
		self.allowsMultipleSelection = allowsMultipleSelection
		
		super.init(style: .grouped)
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: itemCellIdentifier)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("`ItemSelectionViewController` cannot be initialized with `init(coder:)`")
	}
	
	@IBAction private func done() {
		// Notify the delegate that selecting items is finished.
		delegate?.itemSelectionViewController(self, didFinishSelectingItems: selectedItems)
		
		// Dismiss the view controller.
		dismiss(animated: true, completion: nil)
	}
	
    // MARK: UITableViewDataSource
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = allItems[indexPath.row]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: itemCellIdentifier, for: indexPath)
		cell.tintColor = UIColor.black
		cell.textLabel?.text = "\(item.rawValue)"
		
		if selectedItems.contains(item) {
			cell.accessoryType = .checkmark
		} else {
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
			} else {
				selectedItems.append(item)
			}
			
			tableView.deselectRow(at: indexPath, animated: true)
			tableView.reloadRows(at: [indexPath], with: .automatic)
		} else {
			let indexPathsToReload: [IndexPath]
			if selectedItems.isEmpty {
				indexPathsToReload = [indexPath]
			} else {
				indexPathsToReload = [indexPath, IndexPath(row: allItems.index(of: selectedItems[0])!, section: 0)]
			}
			
			selectedItems = [allItems[indexPath.row]]
			
			// Deselect the selected row & reload the table view cells for the old and new items to swap checkmarks.
			tableView.deselectRow(at: indexPath, animated: true)
			tableView.reloadRows(at: indexPathsToReload, with: .automatic)
		}
	}
}

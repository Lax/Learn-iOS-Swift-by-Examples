/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `ListViewController` class displays the contents of a list document. It also allows the user to create, update, and delete items, change the color of the list, or delete the list.
            
*/

import UIKit
import NotificationCenter
import ListerKit

class ListViewController: UITableViewController, UITextFieldDelegate, ListColorCellDelegate, ListDocumentDelegate {
    // MARK: Types
    
    struct MainStoryboard {
        struct TableViewCellIdentifiers {
            // Used for normal items and the add item cell.
            static let listItemCell = "listItemCell"
            
            // Used in edit mode to allow the user to change colors.
            static let listColorCell = "listColorCell"
        }
    }
    
    // MARK: Properties
    
    var listController: ListController!
    
    /// Set in `textFieldDidBeginEditing(_:)`. `nil` otherwise.
    weak var activeTextField: UITextField?
    
    /// Set in `configureWithListInfo(_:)`. `nil` otherwise.
    var listInfo: ListInfo?
    
    var document: ListDocument!
    
    var documentURL: NSURL {
        return document.fileURL
    }
    
    var list: List! {
        return document.list
    }
    
    // Return the toolbar items since they are used in edit mode.
    var listToolbarItems: [UIBarButtonItem] {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let title = NSLocalizedString("Delete List", comment: "The title of the button to delete the current list.")
        let deleteList = UIBarButtonItem(title: title, style: .Plain, target: self, action: "deleteList:")
        deleteList.tintColor = UIColor.redColor()
        
        // Disable the delete list button if this is the Today document.
        if documentURL.lastPathComponent == AppConfiguration.localizedTodayDocumentNameAndExtension {
            deleteList.enabled = false
        }
            
        return [flexibleSpace, deleteList, flexibleSpace]
    }

    var textAttributes: [String: AnyObject] = [:] {
        didSet {
            if isViewLoaded() {
                updateInterfaceWithTextAttributes()
            }
        }
    }
    
    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateInterfaceWithTextAttributes()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.rightBarButtonItem = editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        document.openWithCompletionHandler { success in
            if !success {
                // In your app you should handle this gracefully.
                println("Couldn't open document: \(self.documentURL).")
                abort()
            }
            
            self.tableView.reloadData()

            self.textAttributes = [
                NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
                NSForegroundColorAttributeName: self.document.list.color.colorValue
            ]

            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleDocumentStateChangedNotification:", name: UIDocumentStateChangedNotification, object: self.document)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        document.delegate = nil
        document.closeWithCompletionHandler(nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDocumentStateChangedNotification, object: document)
        
        // Hide the toolbar so the list can't be edited.
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    // MARK: Setup

    func configureWithListInfo(aListInfo: ListInfo) {
        listInfo = aListInfo

        document = ListDocument(fileURL: aListInfo.URL)
        document.delegate = self
                
        navigationItem.title = aListInfo.name
                
        textAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: aListInfo.color?.colorValue ?? List.Color.Gray.colorValue
        ]
    }
    
    // MARK: Notifications

    func handleDocumentStateChangedNotification(notification: NSNotification) {
        if document.documentState & .InConflict == .InConflict {
            resolveConflicts()
        }

        dispatch_async(dispatch_get_main_queue(), tableView.reloadData)
    }

    // MARK: UIViewController Overrides

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // Prevent navigating back in edit mode.
        navigationItem.setHidesBackButton(editing, animated: animated)
        
        // Make sure to resign first responder on the active text field if needed.
        activeTextField?.endEditing(false)
        
        // Reload the first row to switch from "Add Item" to "Change Color".
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        // If moving out of edit mode, notify observers about the list color and trigger a save.
        if !editing {
            // Notify the document of a change.
            document.updateChangeCount(.Done)

            // If the list info doesn't already exist (but it should), then create a new one.
            if listInfo == nil {
                listInfo = ListInfo(URL: documentURL)
            }
            listInfo!.color = list.color
            listController!.setListInfoHasNewContents(listInfo!)

            triggerNewDataForWidget()
        }
        
        navigationController?.setToolbarHidden(!editing, animated: animated)
        navigationController?.toolbar?.setItems(listToolbarItems, animated: animated)
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Don't show anything if the document hasn't been loaded.
        if document == nil {
            return 0
        }

        // Show the items in a list, plus a separate row that lets users enter a new item.
        return list.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var identifier: String

        if editing && indexPath.row == 0 {
            identifier = MainStoryboard.TableViewCellIdentifiers.listColorCell
        }
        else {
            identifier = MainStoryboard.TableViewCellIdentifiers.listItemCell
        }
        
        return tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as UITableViewCell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // The initial row is reserved for adding new items so it can't be deleted or edited.
        if indexPath.row == 0 {
            return false
        }
        
        return true
    }

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // The initial row is reserved for adding new items so it can't be moved.
        if indexPath.row == 0 {
            return false
        }
        
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle != .Delete {
            return
        }
        
        let item = list[indexPath.row - 1]
        list.removeItems([item])
        
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        triggerNewDataForWidget()
        
        // Notify the document of a change.
        document.updateChangeCount(.Done)
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let item = list[fromIndexPath.row - 1]
        list.moveItem(item, toIndex: toIndexPath.row - 1)

        // Notify the document of a change.
        document.updateChangeCount(.Done)
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        switch cell {
            case let colorCell as ListColorCell:
                colorCell.configure()
                colorCell.selectedColor = list.color
                colorCell.delegate = self
            case let itemCell as ListItemCell:
                configureListItemCell(itemCell, usingColor: list.color, forRow: indexPath.row)
            default:
                fatalError("Attempting to configure an unknown or unsupported cell type in ListViewController.")
        }
    }
    
    override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath: NSIndexPath) {
        // When the user swipes to show the delete confirmation, don't enter editing mode.
        // UITableViewController enters editing mode by default so we override without calling super.
    }
    
    override func tableView(tableView: UITableView, didEndEditingRowAtIndexPath: NSIndexPath) {
        // When the user swipes to hide the delete confirmation, no need to exit edit mode because we didn't enter it.
        // UITableViewController enters editing mode by default so we override without calling super.
    }
    
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath fromIndexPath: NSIndexPath, toProposedIndexPath proposedIndexPath: NSIndexPath) -> NSIndexPath {
        let item = list[fromIndexPath.row - 1]
        
        if proposedIndexPath.row == 0 {
            let row = item.isComplete ? list.indexOfFirstCompletedItem! + 1 : 1
            
            return NSIndexPath(forRow: row, inSection: 0)
        }
        else if list.canMoveItem(item, toIndex: proposedIndexPath.row - 1, inclusive: false) {
            return proposedIndexPath
        }
        else if item.isComplete {
            return NSIndexPath(forRow: list.indexOfFirstCompletedItem! + 1, inSection: 0)
        }
        else {
            return NSIndexPath(forRow: list.indexOfFirstCompletedItem!, inSection: 0)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        // Keep track of a flag that determines whether or not we'll notify
        var shouldNotifyDocumentOfChange = false
        
        if let indexPath = indexPathForView(textField) {
            // Check to see if a change needs to be made to an existing list item (i.e. row > 0)
            // or if we need to insert a new list item.
            let isForExistingListItem = indexPath.row > 0
            
            if isForExistingListItem {
                // Edit the item in place.
                let item = list[indexPath.row - 1]

                // Delete the item row if the user deletes all characters in the text field.
                if textField.text.isEmpty {
                    list.removeItems([item])
                    
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    
                    triggerNewDataForWidget()
                    
                    shouldNotifyDocumentOfChange = true
                }
                // Update the item's text if it changed (besides removing all characters, which is a delete).
                else if item.text != textField.text {
                    item.text = textField.text
                    
                    triggerNewDataForWidget()
                    
                    shouldNotifyDocumentOfChange = true
                }
            }
            else if !textField.text.isEmpty {
                // Adds the item to the top of the list.
                let newItem = ListItem(text: textField.text)
                let insertedIndex = list.insertItem(newItem)

                // Update the edit row to show the check box.
                let itemCell = tableView.cellForRowAtIndexPath(indexPath) as ListItemCell
                itemCell.checkBox.hidden = false
                
                // Update the edit row to indicate that deleting all text in an item will delete the item.
                itemCell.textField.placeholder = NSLocalizedString("Delete Item", comment: "")
                
                // Insert a new add item row into the table view.
                tableView.beginUpdates()
                
                let targetIndexPath = NSIndexPath(forRow: insertedIndex, inSection: 0)
                tableView.insertRowsAtIndexPaths([targetIndexPath], withRowAnimation: .Automatic)
                
                tableView.endUpdates()
                
                triggerNewDataForWidget()
                
                shouldNotifyDocumentOfChange = true
            }
        }
        
        if shouldNotifyDocumentOfChange {
            document.updateChangeCount(.Done)
        }

        activeTextField = nil
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Always resign first responder and return. If the field is empty, the item will be deleted.
        textField.resignFirstResponder()

        return true
    }
    
    // MARK: ListColorCellDelegate
    
    func listColorCellDidChangeSelectedColor(listColorCell: ListColorCell) {
        list.color = listColorCell.selectedColor

        textAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: list.color.colorValue
        ]

        let indexPaths = tableView.indexPathsForVisibleRows()
        if let indexPaths = indexPaths {
            tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
        }
    }

    // MARK: IBActions

    @IBAction func deleteList(_: UIBarButtonItem) {
        listController.removeListInfo(listInfo!)

        hideViewControllerAfterListWasDeleted()
    }
    
    @IBAction func checkBoxTapped(sender: CheckBox) {
        let indexPath = indexPathForView(sender)!

        // Check to see if the tapped row is within the list item rows.
        if 1...list.count ~= indexPath.row {
            let item = list[indexPath.row - 1]
            
            let (fromIndex, toIndex) = list.toggleItem(item)
            
            if fromIndex == toIndex {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
            else {
                // Animate the row up or down depending on whether it was complete / incomplete.
                let targetRow = NSIndexPath(forRow: toIndex + 1, inSection: 0)

                tableView.beginUpdates()
                tableView.moveRowAtIndexPath(indexPath, toIndexPath: targetRow)
                tableView.endUpdates()
                tableView.reloadRowsAtIndexPaths([targetRow], withRowAnimation: .Automatic)
            }
            
            triggerNewDataForWidget()
            
            // Notify the document of a change.
            document.updateChangeCount(.Done)
        }
    }
    
    // MARK: ListDocumentDelegate
    
    func listDocumentWasDeleted(listDocument: ListDocument) {
        hideViewControllerAfterListWasDeleted()
    }
    
    // MARK: Convenience
    
    func updateInterfaceWithTextAttributes() {
        let controller = navigationController?.navigationController ?? navigationController!
        
        controller.navigationBar.titleTextAttributes = textAttributes
        controller.navigationBar.tintColor = textAttributes[NSForegroundColorAttributeName] as UIColor
        controller.toolbar?.tintColor = textAttributes[NSForegroundColorAttributeName] as UIColor

        tableView.tintColor = textAttributes[NSForegroundColorAttributeName] as UIColor
    }

    func hideViewControllerAfterListWasDeleted() {
        if splitViewController != nil && splitViewController!.collapsed {
            let controller = navigationController?.navigationController ?? navigationController!
            controller.popViewControllerAnimated(true)
        }
        else {
            let emptyViewController = storyboard?.instantiateViewControllerWithIdentifier(AppDelegate.MainStoryboard.Identifiers.emptyViewController) as UINavigationController
            emptyViewController.topViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
            
            let masterViewController = splitViewController?.viewControllers.first! as UINavigationController
            splitViewController?.viewControllers = [masterViewController, emptyViewController]
        }
    }
    
    func configureListItemCell(itemCell: ListItemCell, usingColor color: List.Color, forRow row: Int) {
        itemCell.checkBox.isChecked = false
        itemCell.checkBox.hidden = false
        
        itemCell.textField.text = ""
        itemCell.textField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        itemCell.textField.delegate = self
        itemCell.textField.textColor = UIColor.darkTextColor()
        itemCell.textField.enabled = true
        
        if row == 0 {
            // Configure an "Add Item" list item cell.
            itemCell.textField.placeholder = NSLocalizedString("Add Item", comment: "")
            itemCell.checkBox.hidden = true
        }
        else {
            let item = list[row - 1]
            
            itemCell.isComplete = item.isComplete
            itemCell.textField.text = item.text
        }
    }
    
    func triggerNewDataForWidget() {
        if document.localizedName == AppConfiguration.localizedTodayDocumentName {
            NCWidgetController.widgetController().setHasContent(true, forWidgetWithBundleIdentifier: AppConfiguration.Extensions.widgetBundleIdentifier)
        }
    }

    func resolveConflicts() {
        // Any automatic merging logic or presentation of conflict resolution UI should go here.
        // For Lister we'll pick the current version and mark the conflict versions as resolved.
        NSFileVersion.removeOtherVersionsOfItemAtURL(documentURL, error: nil)

        let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItemAtURL(documentURL) as [NSFileVersion]
        
        for fileVersion in conflictVersions {
            fileVersion.resolved = true
        }
    }
    
    func indexPathForView(view: UIView) -> NSIndexPath? {
        let viewOrigin = view.bounds.origin
        
        let viewLocation = tableView.convertPoint(viewOrigin, fromView: view)
        
        return tableView.indexPathForRowAtPoint(viewLocation)
    }
}

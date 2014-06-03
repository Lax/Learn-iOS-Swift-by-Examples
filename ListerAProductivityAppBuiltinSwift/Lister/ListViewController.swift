/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Displays the contents of a list document, allows a user to create, update, and delete items, change the color of the list, or delete the list.
            
*/

import UIKit
import NotificationCenter
import ListerKit

@objc protocol ListViewControllerDelegate {
    func listViewControllerDidDeleteList(listViewController: ListViewController)
}

class ListViewController: UITableViewController, UITextFieldDelegate, ListColorCellDelegate, ListDocumentDelegate {
    // MARK: Types

    struct Notifications {
        struct ListColorDidChange {
            static let name = "ListDidUpdateColorNotification"
            static let colorUserInfoKey = "ListDidUpdateColorUserInfoKey"
            static let URLUserInfoKey = "ListDidUpdateURLUserInfoKey"
        }
    }
    
    struct MainStoryboard {
        struct TableViewCellIdentifiers {
            static let listItemCell = "listItemCell" // used for normal items and the add item cell
            static let listColorCell = "listColorCell" // used in edit mode to allow the user to change colors
        }
    }
    
    // MARK: Properties

    weak var delegate: ListViewControllerDelegate?
    
    var document: ListDocument!
    
    var documentURL: NSURL {
        return document.fileURL
    }
    
    var list: List {
        return document.list
    }
    
    // Lazily load and cache the toolbar items since they are used in edit mode (possibly more than once).
    @lazy var listToolbarItems: UIBarButtonItem[] = {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let title = NSLocalizedString("Delete List", comment: "The title of the button to delete the current list.")
        let deleteList = UIBarButtonItem(title: title, style: .Plain, target: self, action: "deleteList:")
        return [flexibleSpace, deleteList, flexibleSpace]
    }()
    
    var textAttributes: Dictionary<String, AnyObject> = [:] {
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
                NSLog("Couldn't open document: \(self.documentURL.absoluteString).")
                abort()
            }
            
            self.tableView.reloadData()
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false

            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleDocumentStateChangedNotification:", name: UIDocumentStateChangedNotification, object: self.document)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        document.closeWithCompletionHandler(nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDocumentStateChangedNotification, object: document)
        
        // Hide the toolbar so the list can't be edited.
        navigationController.setToolbarHidden(true, animated: animated)
    }
    
    // MARK: Setup

    func configureWithListInfo(listInfo: ListInfo) {
        listInfo.fetchInfoWithCompletionHandler { [weak self] in
            if let strongSelf = self {
                strongSelf.document = ListDocument(fileURL: listInfo.URL)
                strongSelf.document.delegate = self
                
                strongSelf.navigationItem.title = listInfo.name
                
                strongSelf.textAttributes = [
                    NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
                    NSForegroundColorAttributeName: listInfo.color!.colorValue
                ]
            }
        }
    }
    
    // MARK: Notifications

    func handleDocumentStateChangedNotification(_: NSNotification) {
        let state = document.documentState

        if state & .InConflict {
            resolveConflicts()
        }
        
        // Passing `tableView.reloadData` passes the table view's reloadData method as a () -> Void closure
        // to the dispatch_async method.
        dispatch_async(dispatch_get_main_queue(), tableView.reloadData)
    }

    // MARK: UIViewController Overrides

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // Prevent navigating back in edit mode.
        navigationItem.setHidesBackButton(editing, animated: animated)
        
        // Reload the first row to switch from "Add Item" to "Change Color"
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        // If moving out of edit mode, notify observers about the list color and trigger a save.
        if !editing {
            // Notify the document of a change.
            document.updateChangeCount(.Done)
            
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.ListColorDidChange.name, object: nil, userInfo: [
                Notifications.ListColorDidChange.colorUserInfoKey: list.color.toRaw(),
                Notifications.ListColorDidChange.URLUserInfoKey: documentURL
            ])
            
            triggerNewDataForWidget()
        }
        
        navigationController.setToolbarHidden(!editing, animated: animated)
        navigationController.toolbar.setItems(listToolbarItems, animated: animated)
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Don't show anything if the document hasn't been loaded.
        if !document {
            return 0
        }
        
        // We show the items in a list, plus a separate row that lets users enter a new item.
        return list.count + 1
    }
    
    override func tableView(_: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 && editing {
            let colorCell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.listColorCell, forIndexPath: indexPath) as ListColorCell
            
            colorCell.configure()
            colorCell.delegate = self
            
            return colorCell
        }
        else {
            let itemCell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.listItemCell, forIndexPath: indexPath) as ListItemCell
            
            configureListItemCell(itemCell, usingColor: list.color, forRow: indexPath.row)
            
            return itemCell
        }
    }
    
    func configureListItemCell(itemCell: ListItemCell, usingColor color: List.Color, forRow row: Int) {
        itemCell.textField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        itemCell.textField.delegate = self
        
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
    
    override func tableView(_: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // The initial row is reserved for adding new items so it can't be deleted or edited.
        if indexPath.row == 0 {
            return false
        }
        
        return true
    }
    
    override func tableView(_: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // The initial row is reserved for adding new items so it can't be moved.
        if indexPath.row == 0 {
            return false
        }
        
        return true
    }
    
    override func tableView(_: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
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
    
    override func tableView(_: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let item = list[fromIndexPath.row - 1]
        list.moveItem(item, toIndex: toIndexPath.row - 1)
        
        // Notify the document of a change.
        document.updateChangeCount(.Done)
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_: UITableView, willBeginEditingRowAtIndexPath: NSIndexPath) {
        // When the user swipes to show the delete confirmation, don't enter editing mode.
        // UITableViewController enters editing mode by default so we override without calling super.
    }
    
    override func tableView(_: UITableView, didEndEditingRowAtIndexPath: NSIndexPath) {
        // When the user swipes to hide the delete confirmation, no need to exit edit mode because we didn't enter it.
        // UITableViewController enters editing mode by default so we override without calling super.
    }
    
    override func tableView(_: UITableView, targetIndexPathForMoveFromRowAtIndexPath fromIndexPath: NSIndexPath, toProposedIndexPath proposedIndexPath: NSIndexPath) -> NSIndexPath {
        let item = list[fromIndexPath.row - 1]
        
        if proposedIndexPath.row == 0 {
            let row = item.isComplete ? list.indexOfFirstCompletedItem + 1 : 1
            
            return NSIndexPath(forRow: row, inSection: 0)
        }
        else if list.canMoveItem(item, toIndex: proposedIndexPath.row - 1, inclusive: false) {
            return proposedIndexPath
        }
        else if item.isComplete {
            return NSIndexPath(forRow: list.indexOfFirstCompletedItem + 1, inSection: 0)
        }
        else {
            return NSIndexPath(forRow: list.indexOfFirstCompletedItem, inSection: 0)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        let indexPath = indexPathForView(textField)
        
        if indexPath.row > 0 {
            // Edit the item in place.
            let item = list[indexPath.row - 1]
            
            // If the contents of the text field at the end of editing is the same as it started, don't trigger an update.
            if item.text != textField.text {
                item.text = textField.text
                
                triggerNewDataForWidget()
                
                // Notify the document of a change.
                document.updateChangeCount(.Done)
            }
        }
        else if !textField.text.isEmpty {
            // Adds the item to the top of the list.
            let item = ListItem(text: textField.text)
            let insertedIndex = list.insertItem(item)
            
            // Update the edit row to show the check box.
            let itemCell = tableView.cellForRowAtIndexPath(indexPath) as ListItemCell
            itemCell.checkBox.hidden = false
            
            // Insert a new add item row into the table view.
            tableView.beginUpdates()
            
            let targetIndexPath = NSIndexPath(forRow: insertedIndex, inSection: 0)
            tableView.insertRowsAtIndexPaths([targetIndexPath], withRowAnimation: .Automatic)
            
            tableView.endUpdates()
            
            triggerNewDataForWidget()
            
            // Notify the document of a change.
            document.updateChangeCount(.Done)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let indexPath = indexPathForView(textField)

        // An item must have text to dismiss the keyboard.
        if !textField.text.isEmpty || indexPath.row == 0 {
            textField.resignFirstResponder()
            return true
        }
        
        return false
    }
    
    // MARK: ListColorCellDelegate
    
    func listColorCellDidChangeSelectedColor(listColorCell: ListColorCell) {
        list.color = listColorCell.selectedColor

        textAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: list.color.colorValue
        ]

        let indexPaths = tableView.indexPathsForVisibleRows()
        tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
    }

    // MARK: IBActions
    
    func deleteList(UIBarButtonItem) {
        delegate?.listViewControllerDidDeleteList(self)

        if splitViewController?.collapsed {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    @IBAction func checkBoxTapped(sender: CheckBox) {
        let indexPath = indexPathForView(sender)
        
        // This ~= operator ensures that indexPath.row is found in the range on the right.
        if 1...list.count ~= indexPath.row {
            let item = list[indexPath.row - 1]
            
            let (fromIndex, toIndex) = list.toggleItem(item)
            
            if fromIndex == toIndex {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
            else {
                // Animate the row up or down depending on whether it was complete/incomplete.
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
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Convenience
    
    func triggerNewDataForWidget() {
        if document.localizedName == AppConfiguration.localizedTodayDocumentName {
            NCWidgetController.widgetController().setHasContent(true, forWidgetWithBundleIdentifier: AppConfiguration.Extensions.widgetBundleIdentifier)
        }
    }
    
    func updateInterfaceWithTextAttributes() {
        navigationController.navigationBar.titleTextAttributes = textAttributes
        navigationController.navigationBar.tintColor = textAttributes[NSForegroundColorAttributeName] as UIColor
        navigationController.toolbar.tintColor = textAttributes[NSForegroundColorAttributeName] as UIColor
        tableView.tintColor = textAttributes[NSForegroundColorAttributeName] as UIColor
    }

    func resolveConflicts() {
        // Any automatic merging logic or presentation of conflict resolution UI should go here.
        // For Lister we'll pick the current version and mark the conflict versions as resolved.
        NSFileVersion.removeOtherVersionsOfItemAtURL(self.documentURL, error: nil)
        
        let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItemAtURL(documentURL) as NSFileVersion[]
        
        for fileVersion in conflictVersions {
            fileVersion.resolved = true
        }
    }
    
    func indexPathForView(view: UIView) -> NSIndexPath {
        let viewOrigin = view.bounds.origin
        
        let viewLocation = tableView.convertPoint(viewOrigin, fromView: view)
        
        return tableView.indexPathForRowAtPoint(viewLocation)
    }
}

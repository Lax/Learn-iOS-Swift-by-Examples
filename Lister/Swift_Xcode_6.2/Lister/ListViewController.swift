/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListViewController` class displays the contents of a list document. It also allows the user to create, update, and delete items, change the color of the list, or delete the list.
*/

import UIKit
import NotificationCenter
import ListerKit

class ListViewController: UITableViewController, UITextFieldDelegate, ListColorCellDelegate, ListDocumentDelegate, ListPresenterDelegate {
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
    
    var listsController: ListsController!
    
    /// Set in `textFieldDidBeginEditing(_:)`. `nil` otherwise.
    weak var activeTextField: UITextField?
    
    /// Set in `configureWithListInfo(_:)`. `nil` otherwise.
    var listInfo: ListInfo?
    
    var document: ListDocument! {
        didSet {
            if document == nil { return }
            
            document.delegate = self
            
            listPresenter.undoManager = document.undoManager

            listPresenter.delegate = self
        }
    }
    
    // Provide the document's undoManager property as the default NSUndoManager for this UIViewController.
    override var undoManager: NSUndoManager? {
        return document?.undoManager
    }
    
    var listPresenter: AllListItemsPresenter! {
        return document.listPresenter as? AllListItemsPresenter
    }
    
    var documentURL: NSURL {
        return document.fileURL
    }
    
    // Return the toolbar items since they are used in edit mode.
    var listToolbarItems: [UIBarButtonItem] {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let title = NSLocalizedString("Delete List", comment: "The title of the button to delete the current list.")
        let deleteList = UIBarButtonItem(title: title, style: .Plain, target: self, action: "deleteList:")
        deleteList.tintColor = UIColor.redColor()
        
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

    // Return `true` to indicate that we want to handle undo events through the responder chain.
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 44.0
        
        updateInterfaceWithTextAttributes()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.rightBarButtonItem = editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        document.openWithCompletionHandler { success in
            if !success {
                // In your app, handle this gracefully.
                println("Couldn't open document: \(self.documentURL).")

                abort()
            }

            self.textAttributes = [
                NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
                NSForegroundColorAttributeName: self.listPresenter.color.colorValue
            ]
            
            /*
                When the document is opened, make sure that the document stores its extra metadata in the `userInfo`
                dictionary. See `ListDocument`'s `updateUserActivityState(_:)` method for more information.
            */
            if let userActivity = self.document.userActivity {
                self.document.updateUserActivityState(userActivity)
            }

            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleDocumentStateChangedNotification:", name: UIDocumentStateChangedNotification, object: document)
    }
    
    // Become first responder after the view appears so that we can respond to undo events.
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        // Resign as first responder after its view disappears to stop handling undo events.
        resignFirstResponder()

        document.delegate = nil
        document.closeWithCompletionHandler(nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDocumentStateChangedNotification, object: document)
        
        // Hide the toolbar so the list can't be edited.
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    // MARK: Setup

    func configureWithListInfo(aListInfo: ListInfo) {
        listInfo = aListInfo

        let listPresenter = AllListItemsPresenter()
        document = ListDocument(fileURL: aListInfo.URL, listPresenter: listPresenter)

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

        // In order to update the UI, dispatch back to the main queue as there are no promises about the queue this will be called on.
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
            // If the list info doesn't already exist (but it should), then create a new one.
            listInfo = listInfo ?? ListInfo(URL: documentURL)

            listInfo!.color = listPresenter.color
            
            listsController!.setListInfoHasNewContents(listInfo!)

            triggerNewDataForWidget()
        }
        
        navigationController?.setToolbarHidden(!editing, animated: animated)
        navigationController?.toolbar?.setItems(listToolbarItems, animated: animated)
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Don't show anything if the document hasn't been loaded.
        if document == nil {
            return 0
        }

        // Show the items in a list, plus a separate row that lets users enter a new item.
        return listPresenter.count + 1
    }
    
    override func tableView(_: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var identifier: String

        // Show the "color selection" cell if in edit mode.
        if editing && indexPath.row == 0 {
            identifier = MainStoryboard.TableViewCellIdentifiers.listColorCell
        }
        else {
            identifier = MainStoryboard.TableViewCellIdentifiers.listItemCell
        }
        
        return tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as UITableViewCell
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
        
        let listItem = listPresenter.presentedListItems[indexPath.row - 1]

        listPresenter.removeListItem(listItem)
    }
    
    override func tableView(_: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let listItem = listPresenter.presentedListItems[fromIndexPath.row - 1]

        // `toIndexPath.row` will never be `0` since we don't allow moving to the zeroth row (it's the color selection row).
        listPresenter.moveListItem(listItem, toIndex: toIndexPath.row - 1)
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        switch cell {
            case let colorCell as ListColorCell:
                colorCell.configure()
                colorCell.selectedColor = listPresenter.color
                colorCell.delegate = self

            case let itemCell as ListItemCell:
                configureListItemCell(itemCell, forRow: indexPath.row)

            default:
                fatalError("Attempting to configure an unknown or unsupported cell type in `ListViewController`.")
        }
    }
    
    override func tableView(_: UITableView, willBeginEditingRowAtIndexPath: NSIndexPath) {
        /* 
            When the user swipes to show the delete confirmation, don't enter editing mode.
            `UITableViewController` enters editing mode by default so we override without calling super.
        */
    }
    
    override func tableView(_: UITableView, didEndEditingRowAtIndexPath: NSIndexPath) {
        /*
            When the user swipes to hide the delete confirmation, no need to exit edit mode because we didn't
            enter it. `UITableViewController` enters editing mode by default so we override without calling
            super.
        */
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(_: UITableView, targetIndexPathForMoveFromRowAtIndexPath fromIndexPath: NSIndexPath, toProposedIndexPath proposedIndexPath: NSIndexPath) -> NSIndexPath {
        let listItem = listPresenter.presentedListItems[fromIndexPath.row - 1]

        if proposedIndexPath.row == 0 {
            return fromIndexPath
        }
        else if listPresenter.canMoveListItem(listItem, toIndex: proposedIndexPath.row - 1) {
            return proposedIndexPath
        }
        
        return fromIndexPath
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let indexPath = indexPathForView(textField)
        
        if indexPath != nil && indexPath!.row > 0 {
            let listItem = listPresenter.presentedListItems[indexPath!.row - 1]

            listPresenter.updateListItem(listItem, withText: textField.text)
        }
        else if !textField.text.isEmpty {
            let listItem = ListItem(text: textField.text)

            listPresenter.insertListItem(listItem)
        }
        
        activeTextField = nil
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let indexPath = indexPathForView(textField)!

        // An item must have text to dismiss the keyboard.
        if !textField.text.isEmpty || indexPath.row == 0 {
            textField.resignFirstResponder()

            return true
        }
        
        return false
    }
    
    // MARK: ListColorCellDelegate
    
    func listColorCellDidChangeSelectedColor(listColorCell: ListColorCell) {
        listPresenter.color = listColorCell.selectedColor
    }

    // MARK: IBActions

    @IBAction func deleteList(_: UIBarButtonItem) {
        listsController.removeListInfo(listInfo!)

        hideViewControllerAfterListWasDeleted()
    }
    
    @IBAction func checkBoxTapped(sender: CheckBox) {
        let indexPath = indexPathForView(sender)!

        // Check to see if the tapped row is within the list item rows.
        if 1...listPresenter.count ~= indexPath.row {
            let listItem = listPresenter.presentedListItems[indexPath.row - 1]

            listPresenter.toggleListItem(listItem)
        }
    }
    
    // MARK: ListDocumentDelegate
    
    func listDocumentWasDeleted(listDocument: ListDocument) {
        hideViewControllerAfterListWasDeleted()
    }
    
    // MARK: ListPresenterDelegate
    
    func listPresenterDidRefreshCompleteLayout(listPresenter: ListPresenterType) {
        // Updating `textAttributes` will updated the color for the items in the interface.
        textAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: listPresenter.color.colorValue
        ]
        
        tableView.reloadData()
    }

    func listPresenterWillChangeListLayout(_: ListPresenterType, isInitialLayout: Bool) {
        tableView.beginUpdates()
    }

    func listPresenter(_: ListPresenterType, didInsertListItem listItem: ListItem, atIndex index: Int) {
        let indexPathsForInsertion = [NSIndexPath(forRow: index + 1, inSection: 0)]
        
        tableView.insertRowsAtIndexPaths(indexPathsForInsertion, withRowAnimation: .Fade)
        
        // Reload the ListItemCell to be configured for the row to create a new list item.
        if index == 0 {
            let indexPathsForReloading = [NSIndexPath(forRow: 0, inSection: 0)]
            
            tableView.reloadRowsAtIndexPaths(indexPathsForReloading, withRowAnimation: .Automatic)
        }
    }
    
    func listPresenter(_: ListPresenterType, didRemoveListItem listItem: ListItem, atIndex index: Int) {
        let indexPaths = [NSIndexPath(forRow: index + 1, inSection: 0)]
        
        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }

    func listPresenter(_: ListPresenterType, didUpdateListItem listItem: ListItem, atIndex index: Int) {
        tableView.endUpdates()
        
        tableView.beginUpdates()

        let indexPath = NSIndexPath(forRow: index + 1, inSection: 0)
 
        if let listItemCell = tableView.cellForRowAtIndexPath(indexPath) as? ListItemCell {
            configureListItemCell(listItemCell, forRow: index + 1)
        }
    }
    
    func listPresenter(_: ListPresenterType, didMoveListItem listItem: ListItem, fromIndex: Int, toIndex: Int) {
        let fromIndexPath = NSIndexPath(forRow: fromIndex + 1, inSection: 0)

        let toIndexPath = NSIndexPath(forRow: toIndex + 1, inSection: 0)

        tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
    }

    func listPresenter(_: ListPresenterType, didUpdateListColorWithColor color: List.Color) {
        // Updating `textAttributes` will updated the color for the items in the interface.
        textAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: color.colorValue
        ]
        
        // The document infrastructure needs to be updated to capture the list's color when it changes.
        if let userActivity = self.document.userActivity {
            self.document.updateUserActivityState(userActivity)
        }
    }

    func listPresenterDidChangeListLayout(_: ListPresenterType, isInitialLayout: Bool) {
        tableView.endUpdates()
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
    
    func configureListItemCell(listItemCell: ListItemCell, forRow row: Int) {
        listItemCell.checkBox.isChecked = false
        listItemCell.checkBox.hidden = false

        listItemCell.textField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        listItemCell.textField.delegate = self
        listItemCell.textField.textColor = UIColor.darkTextColor()
        listItemCell.textField.enabled = true
        
        if row == 0 {
            // Configure an "Add Item" list item cell.
            listItemCell.textField.placeholder = NSLocalizedString("Add Item", comment: "")
            listItemCell.textField.text = ""
            listItemCell.checkBox.hidden = true
        }
        else {
            let listItem = listPresenter.presentedListItems[row - 1]

            listItemCell.isComplete = listItem.isComplete
            listItemCell.textField.text = listItem.text
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

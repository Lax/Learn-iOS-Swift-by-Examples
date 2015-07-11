
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TodayViewController` class displays the Today view containing the contents of the Today list.
*/

import UIKit
import NotificationCenter
import ListerKit

class TodayViewController: UITableViewController, NCWidgetProviding, ListsControllerDelegate, ListPresenterDelegate  {
    // MARK: Types
    
    struct TableViewConstants {
        static let baseRowCount = 5
        static let todayRowHeight = 44.0
        
        struct CellIdentifiers {
            static let content = "todayViewCell"
            static let message = "messageCell"
        }
    }
    
    // MARK: Properties
    
    var document: ListDocument? {
        didSet {
            document?.listPresenter?.delegate = self
        }
    }

    var listPresenter: IncompleteListItemsPresenter? {
        return document?.listPresenter as? IncompleteListItemsPresenter
    }
    
    var showingAll = false {
        didSet {
            resetContentSize()
        }
    }
    
    var isTodayAvailable: Bool {
        return document != nil && listPresenter != nil
    }

    var preferredViewHeight: CGFloat {
        // Determine the total number of items available for presentation.
        let itemCount = isTodayAvailable && !listPresenter!.isEmpty ? listPresenter!.count : 1
        
        /*
            On first launch only display up to `TableViewConstants.baseRowCount + 1` rows. An additional row
            is used to display the "Show All" row.
        */
        let rowCount = showingAll ? itemCount : min(itemCount, TableViewConstants.baseRowCount + 1)

        return CGFloat(Double(rowCount) * TableViewConstants.todayRowHeight)
    }
    
    var listsController: ListsController!
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = UIColor.clearColor()

        listsController = AppConfiguration.sharedConfiguration.listsControllerForCurrentConfigurationWithLastPathComponent(AppConfiguration.localizedTodayDocumentNameAndExtension)
        
        listsController.delegate = self
        listsController.startSearching()
        
        resetContentSize()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        document?.closeWithCompletionHandler(nil)
    }
    
    // MARK: NCWidgetProviding
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top, left: 27.0, bottom: defaultMarginInsets.bottom, right: defaultMarginInsets.right)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: (NCUpdateResult -> Void)) {
        completionHandler(.NewData)
    }
    
    // MARK: ListsControllerDelegate
    
    func listsController(_: ListsController, didInsertListInfo listInfo: ListInfo, atIndex index: Int) {
        // Once we've found the Today list, we'll hand off ownership of listening to udpates to the list presenter.
        listsController.stopSearching()
        
        listsController = nil
        
        // Update the Today widget with the Today list info.
        processListInfoAsTodayDocument(listInfo)
    }

    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isTodayAvailable {
            // Make sure to allow for a row to note that the widget is unavailable.
            return 1
        }
        
        guard let listPresenter = listPresenter else { return 1 }
        
        if (listPresenter.isEmpty) {
            // Make sure to allow for a row to note that no incomplete items remain.
            return 1
        }
        
        return showingAll ? listPresenter.count : min(listPresenter.count, TableViewConstants.baseRowCount + 1)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let listPresenter = listPresenter {
            if listPresenter.isEmpty {
                let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath)
                
                cell.textLabel!.text = NSLocalizedString("No incomplete items in today's list.", comment: "")
                
                return cell
            }
            else {
                let itemCount = listPresenter.count
                
                /**
                    Check to determine what to show at the row at index `TableViewConstants.baseRowCount`. If not
                    showing all rows (explicitly) and the item count is less than `TableViewConstants.baseRowCount` + 1
                    diplay a message cell allowing the user to disclose all rows.
                */
                if (!showingAll && indexPath.row == TableViewConstants.baseRowCount && itemCount != TableViewConstants.baseRowCount + 1) {
                    let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath)
                    
                    cell.textLabel!.text = NSLocalizedString("Show All...", comment: "")
                    
                    return cell
                }
                else {
                    let checkBoxCell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) as! CheckBoxCell
                    
                    configureCheckBoxCell(checkBoxCell, forListItem: listPresenter.presentedListItems[indexPath.row])
                    
                    return checkBoxCell
                }
            }
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath)
            
            cell.textLabel!.text = NSLocalizedString("Lister's Today widget is currently unavailable.", comment: "")
            
            return cell
        }
    }
    
    func configureCheckBoxCell(checkBoxCell: CheckBoxCell, forListItem listItem: ListItem) {
        guard let listPresenter = listPresenter else { return }
        
        checkBoxCell.checkBox.tintColor = listPresenter.color.notificationCenterColorValue
        checkBoxCell.checkBox.isChecked = listItem.isComplete
        checkBoxCell.checkBox.hidden = false

        checkBoxCell.label.text = listItem.text

        checkBoxCell.label.textColor = listItem.isComplete ? UIColor.lightGrayColor() : UIColor.whiteColor()
    }
    
    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let listPresenter = listPresenter else { return }
        
        // Show all of the cells if the user taps the "Show All..." row.
        if isTodayAvailable && !showingAll && indexPath.row == TableViewConstants.baseRowCount {
            showingAll = true
            
            tableView.beginUpdates()
            
            let indexPathForRemoval = NSIndexPath(forRow: TableViewConstants.baseRowCount, inSection: 0)
            tableView.deleteRowsAtIndexPaths([indexPathForRemoval], withRowAnimation: .Fade)
            
            let insertedIndexPathRange = TableViewConstants.baseRowCount..<listPresenter.count
            let insertedIndexPaths = insertedIndexPathRange.map { NSIndexPath(forRow: $0, inSection: 0) }
            
            tableView.insertRowsAtIndexPaths(insertedIndexPaths, withRowAnimation: .Fade)
            
            tableView.endUpdates()
            
            return
        }
        
        // Construct a URL with the lister scheme and the file path of the document.
        let urlComponents = NSURLComponents()
        urlComponents.scheme = AppConfiguration.ListerScheme.name
        urlComponents.path = document!.fileURL.path
        
        // Add a query item to encode the color associated with the list.
        let colorQueryValue = "\(listPresenter.color.rawValue)"
        let colorQueryItem = NSURLQueryItem(name: AppConfiguration.ListerScheme.colorQueryKey, value: colorQueryValue)
        urlComponents.queryItems = [colorQueryItem]

        extensionContext?.openURL(urlComponents.URL!, completionHandler: nil)
    }

    // MARK: IBActions
    
    @IBAction func checkBoxTapped(sender: CheckBox) {
        guard let listPresenter = listPresenter else { return }
        
        let indexPath = indexPathForView(sender)
        
        let item = listPresenter.presentedListItems[indexPath.row]
        listPresenter.toggleListItem(item)
    }
    
    // MARK: ListPresenterDelegate
    
    func listPresenterDidRefreshCompleteLayout(listPresenter: ListPresenterType) {
        /**
            Note when we reload the data, the color of the list will automatically
            change because the list's color is only shown in each list item in the
            iOS Today widget.
        */
        tableView.reloadData()
    }

    func listPresenterWillChangeListLayout(_: ListPresenterType, isInitialLayout: Bool) {
        tableView.beginUpdates()
    }

    func listPresenter(_: ListPresenterType, didInsertListItem listItem: ListItem, atIndex index: Int) {
        guard let listPresenter = listPresenter else { return }
        
        let indexPaths = [NSIndexPath(forRow: index, inSection: 0)]
        
        // Hide the "No items in list" row.
        if index == 0 && listPresenter.count == 1 {
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }

        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }
    
    func listPresenter(_: ListPresenterType, didRemoveListItem listItem: ListItem, atIndex index: Int) {
        guard let listPresenter = listPresenter else { return }
        
        let indexPaths = [NSIndexPath(forRow: index, inSection: 0)]
        
        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        
        // Show the "No items in list" row.
        if index == 0 && listPresenter.isEmpty {
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
    }
    
    func listPresenter(_: ListPresenterType, didUpdateListItem listItem: ListItem, atIndex index: Int) {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        
        if let checkBoxCell = tableView.cellForRowAtIndexPath(indexPath) as? CheckBoxCell {
            configureCheckBoxCell(checkBoxCell, forListItem: listPresenter!.presentedListItems[indexPath.row])
        }
    }
    
    func listPresenter(_: ListPresenterType, didMoveListItem listItem: ListItem, fromIndex: Int, toIndex: Int) {
        let fromIndexPath = NSIndexPath(forRow: fromIndex, inSection: 0)
        
        let toIndexPath = NSIndexPath(forRow: toIndex, inSection: 0)
        
        tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
    }
    
    func listPresenter(_: ListPresenterType, didUpdateListColorWithColor color: List.Color) {
        guard let listPresenter = listPresenter else { return }
        
        for (idx, _) in listPresenter.presentedListItems.enumerate() {
            let indexPath = NSIndexPath(forRow: idx, inSection: 0)

            if let checkBoxCell = tableView.cellForRowAtIndexPath(indexPath) as? CheckBoxCell {
                checkBoxCell.checkBox.tintColor = color.notificationCenterColorValue
            }
        }
    }
    
    func listPresenterDidChangeListLayout(listPresenter: ListPresenterType, isInitialLayout: Bool) {
        resetContentSize()
        
        tableView.endUpdates()

        if !isInitialLayout {
            document!.updateChangeCount(.Done)
        }
    }
    
    // MARK: Convenience
    
    func processListInfoAsTodayDocument(listInfo: ListInfo) {
        // Ignore any updates if we already have the Today document.
        if document != nil { return }
        
        document = ListDocument(fileURL: listInfo.URL, listPresenter: IncompleteListItemsPresenter())
        
        document!.openWithCompletionHandler { success in
            if !success {
                print("Couldn't open document: \(self.document?.fileURL).")
                
                return
            }
            
            self.resetContentSize()
        }
    }
    
    func indexPathForView(view: UIView) -> NSIndexPath {
        let viewOrigin = view.bounds.origin
        
        let viewLocation = tableView.convertPoint(viewOrigin, fromView: view)
        
        return tableView.indexPathForRowAtPoint(viewLocation)!
    }
    
    func resetContentSize() {
        preferredContentSize.height = preferredViewHeight
    }
}

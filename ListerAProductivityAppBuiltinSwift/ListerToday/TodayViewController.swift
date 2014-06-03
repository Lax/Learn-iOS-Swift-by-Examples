/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Handles display of the Today view. It leverages iCloud for seamless interaction between devices.
            
*/

import UIKit
import NotificationCenter
import ListerKit

class TodayViewController: UITableViewController, NCWidgetProviding  {
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
    
    var document: ListDocument?

    var list: List? {
        return document?.list
    }

    var showingAll: Bool = false {
        didSet {
            resetContentSize()
        }
    }

    var isCloudAvailable: Bool {
        return AppConfiguration.sharedConfiguration.isCloudAvailable
    }

    var isTodayAvailable: Bool {
        return isCloudAvailable && document && list
    }

    var documentMetadataQuery: NSMetadataQuery?

    var preferredViewHeight: CGFloat {
        let itemCount = isTodayAvailable && list!.count > 0 ? list!.count : 1

        let rowCount = showingAll ? itemCount : min(itemCount, TableViewConstants.baseRowCount + 1)

        return CGFloat(Double(rowCount) * TableViewConstants.todayRowHeight)
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = UIColor.clearColor()
        
        if isCloudAvailable {
            startQuery()
        }

        resetContentSize()
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isTodayAvailable {
            document!.closeWithCompletionHandler(nil)
        }
    }
    
    // MARK: NCWidgetProviding
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top, left: 27.0, bottom: defaultMarginInsets.bottom, right: defaultMarginInsets.right)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)?) {
        completionHandler?(.NewData)
    }
    
    // MARK: Query Management
    
    func startQuery() {
        if !documentMetadataQuery {
            let metadataQuery = NSMetadataQuery()
            documentMetadataQuery = metadataQuery
            documentMetadataQuery!.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            documentMetadataQuery!.predicate = NSPredicate(format: "(%K = %@)", argumentArray: [NSMetadataItemFSNameKey, AppConfiguration.localizedTodayDocumentNameAndExtension])
            
            // observe the query
            let notificationCenter = NSNotificationCenter.defaultCenter()
            
            notificationCenter.addObserver(self, selector: "handleMetadataQueryUpdates:", name: NSMetadataQueryDidFinishGatheringNotification, object: metadataQuery)
            notificationCenter.addObserver(self, selector: "handleMetadataQueryUpdates:", name: NSMetadataQueryDidUpdateNotification, object: metadataQuery)
        }
        
        documentMetadataQuery!.startQuery()
    }
    
    func handleMetadataQueryUpdates(NSNotification) {
        documentMetadataQuery!.disableUpdates()
        
        processMetadataItems()
        
        documentMetadataQuery!.enableUpdates()
    }
    
    func processMetadataItems() {
        let metadataItems = documentMetadataQuery!.results as NSMetadataItem[]
        
        // We only expect a single result to be returned by our NSMetadataQuery since we query for a specific file.
        if metadataItems.count == 1 {
            let url = metadataItems[0].valueForAttribute(NSMetadataItemURLKey) as NSURL

            document = ListDocument(fileURL: url)

            document!.openWithCompletionHandler { success in
                if !success {
                    NSLog("Couldn't open document: \(self.document!.fileURL.absoluteString)")
                    return
                }
                
                var preferredSize = self.preferredContentSize
                preferredSize.height = self.preferredViewHeight
                self.preferredContentSize = preferredSize
                
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isTodayAvailable {
            return 1
        }
        
        return showingAll ? list!.count : min(list!.count, TableViewConstants.baseRowCount + 1)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if !isCloudAvailable {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath) as UITableViewCell
            cell.textLabel.text = NSLocalizedString("Today requires iCloud", comment: "")
            
            return cell
        }
        
        if list!.count > 0 {
            if !showingAll && indexPath.row == TableViewConstants.baseRowCount &&  list!.count != TableViewConstants.baseRowCount + 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath) as UITableViewCell

                cell.textLabel.text = NSLocalizedString("Show All...", comment: "")

                return cell
            }
            else {
                let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.content, forIndexPath: indexPath) as CheckBoxCell

                configureListItemCell(cell, usingColor: list!.color, item: list![indexPath.row])

                return cell
            }
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.CellIdentifiers.message, forIndexPath: indexPath) as UITableViewCell

            if isTodayAvailable {
                cell.textLabel.text = NSLocalizedString("No items in today's list", comment: "")
            }
            else {
                cell.textLabel.text = ""
            }

            return cell
        }
    }
    
    override func tableView(_: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.backgroundColor = UIColor.clearColor().CGColor
    }

    func configureListItemCell(itemCell: CheckBoxCell, usingColor color: List.Color, item: ListItem) {
        itemCell.checkBox.tintColor = color.colorValue
        itemCell.checkBox.isChecked = item.isComplete
        itemCell.label.text = item.text

        itemCell.label.textColor = UIColor.whiteColor()
        
        // Configure a completed list item cell.
        if item.isComplete {
            itemCell.label.textColor = UIColor.lightGrayColor()
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Show all of the cells if the user taps the "Show All..." row.
        if isTodayAvailable && !showingAll && indexPath.row == TableViewConstants.baseRowCount {
            showingAll = true

            tableView.beginUpdates()
            
            let indexPathForRemoval = NSIndexPath(forRow: TableViewConstants.baseRowCount, inSection: 0)
            tableView.deleteRowsAtIndexPaths([indexPathForRemoval], withRowAnimation: .Fade)

            var insertedIndexPaths = NSIndexPath[]()

            for idx in TableViewConstants.baseRowCount..list!.count {
                insertedIndexPaths += NSIndexPath(forRow: idx, inSection: 0)
            }

            tableView.insertRowsAtIndexPaths(insertedIndexPaths, withRowAnimation: .Fade)

            tableView.endUpdates()
            
            return
        }
        
        // Open the main app if an item is tapped.
        let url = NSURL.URLWithString("lister://today")
        extensionContext.openURL(url, completionHandler: nil)
    }
    
    // MARK: IBActions
    
    @IBAction func checkBoxTapped(sender: CheckBox) {
        let indexPath = indexPathForView(sender)
        
        let item = list![indexPath.row]
        let (fromIndex, toIndex) = list!.toggleItem(item)
        
        if fromIndex == toIndex {
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        else {
            if !showingAll && list!.count != TableViewConstants.baseRowCount && toIndex > TableViewConstants.baseRowCount - 1 {
                // Completing has moved an item off the bottom of the short list.
                // Delete the completed row and insert a new row above "Show All...".
                let targetIndexPath = NSIndexPath(forRow: TableViewConstants.baseRowCount - 1, inSection: 0)
                
                tableView.beginUpdates()
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                tableView.insertRowsAtIndexPaths([targetIndexPath], withRowAnimation: .Automatic)
                tableView.endUpdates()
            }
            else {
                // Need to animate the row up or down depending on its completion state.
                let targetIndexPath = NSIndexPath(forRow: toIndex, inSection: 0)
                
                tableView.beginUpdates()
                tableView.moveRowAtIndexPath(indexPath, toIndexPath: targetIndexPath)
                tableView.endUpdates()
                tableView.reloadRowsAtIndexPaths([targetIndexPath], withRowAnimation: .Automatic)
            }
        }

        // Notify the document of a change.
        document!.updateChangeCount(.Done)
    }
    
    // MARK: Convenience
    
    func indexPathForView(view: UIView) -> NSIndexPath {
        let viewOrigin = view.bounds.origin
        
        let viewLocation = tableView.convertPoint(viewOrigin, fromView: view)
        
        return tableView.indexPathForRowAtPoint(viewLocation)
    }
    
    func resetContentSize() {
        var preferredSize = preferredContentSize

        preferredSize.height = preferredViewHeight

        preferredContentSize = preferredSize
    }
}

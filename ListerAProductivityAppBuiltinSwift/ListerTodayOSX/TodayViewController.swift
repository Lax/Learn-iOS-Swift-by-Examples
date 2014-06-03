/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Handles display of the Today view. It leverages iCloud for seamless interaction between devices.
            
*/

import Cocoa
import NotificationCenter
import ListerKitOSX

@objc(TodayViewController) class TodayViewController: NSViewController, NCWidgetProviding, NCWidgetListViewDelegate, ListRowViewControllerDelegate, ListDocumentDelegate {
    // MARK: Types
    
    struct TableViewConstants {
        static let openListRow = 0
    }
    
    // MARK: Properties

    @IBOutlet var listViewController: NCWidgetListViewController
    
    var document: ListDocument!
    
    var list: List {
        return document.list
    }
    
    // MARK: View Life Cycle

    override func viewDidLoad()  {
        super.viewDidLoad()
        
        updateWidgetContents()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        listViewController.delegate = self
        listViewController.hasDividerLines = false
        listViewController.showsAddButtonWhenEditing = false
        listViewController.contents = []

        updateWidgetContents()
    }
    
    // MARK: NCWidgetProviding

    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        updateWidgetContents(completionHandler)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInset: NSEdgeInsets) -> NSEdgeInsets {
        return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func widgetAllowsEditing() -> Bool {
        return true
    }
    
    func widgetDidBeginEditing() {
        listViewController.editing = true
    }
    
    func widgetDidEndEditing() {
        listViewController.editing = false
    }
    
    // MARK: NCWidgetListViewDelegate

    func widgetList(_: NCWidgetListViewController, viewControllerForRow row: Int) -> NSViewController {
        if row == TableViewConstants.openListRow {
            return OpenListerRowViewController()
        }
        else if list.isEmpty {
            return NoItemsRowViewController()
        }
        
        let listRowViewController = ListRowViewController()
        
        listRowViewController.representedObject = listViewController.contents[row]

        listRowViewController.delegate = self
        
        return listRowViewController
    }
    
    func widgetList(_: NCWidgetListViewController, shouldRemoveRow row: Int) -> Bool {
        return row != TableViewConstants.openListRow
    }
    
    func widgetList(_: NCWidgetListViewController, didRemoveRow row: Int) {
        let item = list[row - 1]
        
        list.removeItems([item])
        
        document.updateChangeCount(.ChangeDone)
    }
    
    // MARK: ListRowViewControllerDelegate

    func listRowViewControllerDidChangeRepresentedObjectState(listRowViewController: ListRowViewController) {
        let indexOfListRowViewController = listViewController.rowForViewController(listRowViewController)
        
        let item = list[indexOfListRowViewController - 1]
        list.toggleItem(item)
        
        document.updateChangeCount(.ChangeDone)
        
        // Make sure the rows are reordered appropriately.
        listViewController.contents = listRowRepresentedObjectsForList(list)
    }
    
    // MARK: ListDocumentDelegate

    func listDocumentDidChangeContents(document: ListDocument) {
        listViewController.contents = listRowRepresentedObjectsForList(list)
    }
    
    // MARK: Convenience

    func listRowRepresentedObjectsForList(aList: List) -> AnyObject[] {
        var representedObjects = AnyObject[]()

        let listColor = list.color.colorValue
        
        // The "Open in Lister" has a representedObject as an NSColor, representing the text color.
        representedObjects += listColor
        
        for item in aList.items {
            representedObjects += ListRowRepresentedObject(item: item, color: listColor)
        }
        
        // Add a sentinel NSNull value to represent the "No Items" represented object.
        if (list.isEmpty) {
            // No items in the list.
            representedObjects += NSNull()
        }
        
        return representedObjects
    }
    
    func updateWidgetContents(completionHandler: ((NCUpdateResult) -> Void)? = nil) {
        TodayListManager.fetchTodayDocumentURLWithCompletionHandler { todayDocumentURL in
            if !todayDocumentURL {
                completionHandler?(.Failed)
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                var error: NSError?
                let newDocument = ListDocument(contentsOfURL: todayDocumentURL!, makesCustomWindowControllers: false, error: &error)
                
                if error {
                    completionHandler?(.Failed)
                }
                else {
                    if self.document?.list == newDocument.list {
                        completionHandler?(.NoData)
                    }
                    else {
                        self.document = newDocument
                        self.document.delegate = self
                        self.listViewController.contents = self.listRowRepresentedObjectsForList(newDocument.list)
                        
                        completionHandler?(.NewData)
                    }
                }
            }
        }
    }
}

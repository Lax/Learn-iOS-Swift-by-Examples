/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `TodayViewController` class handles display of the Today view. It leverages iCloud for seamless interaction between devices.
            
*/

import Cocoa
import NotificationCenter
import ListerKitOSX

class TodayViewController: NSViewController, NCWidgetProviding, NCWidgetListViewDelegate, ListRowViewControllerDelegate, ListDocumentDelegate {
    // MARK: Properties

    @IBOutlet var listViewController: NCWidgetListViewController!

    var document: ListDocument!
    
    var list: List {
        return document.list
    }
    
    // Override the nib name to make sure that the view controller opens the correct nib.
    override var nibName: String {
        return "TodayViewController"
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
        listViewController.contents = []

        updateWidgetContents()
    }
    
    // MARK: NCWidgetProviding

    func widgetPerformUpdateWithCompletionHandler(completionHandler: NCUpdateResult -> Void) {
        updateWidgetContents(completionHandler)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInset: NSEdgeInsets) -> NSEdgeInsets {
        return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func widgetAllowsEditing() -> Bool {
        return false
    }
    
    // MARK: NCWidgetListViewDelegate

    func widgetList(_: NCWidgetListViewController, viewControllerForRow row: Int) -> NSViewController {
        let representedObjectForRow: AnyObject = listViewController.contents[row]

        // First check to see if it's a straightforward row to return a view controller for.
        if let todayWidgetRowPurpose = representedObjectForRow as? TodayWidgetRowPurposeBox {
            switch todayWidgetRowPurpose.purpose {
                case .OpenLister: return OpenListerRowViewController()
                case .NoItemsInList: return NoItemsRowViewController()
                case .RequiresCloud: return TodayWidgetRequiresCloudViewController()
            }
        }

        let listRowViewController = ListRowViewController()
        
        listRowViewController.representedObject = representedObjectForRow

        listRowViewController.delegate = self
        
        return listRowViewController
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

    func listRowRepresentedObjectsForList(aList: List) -> [AnyObject] {
        var representedObjects = [AnyObject]()

        let listColor = list.color.colorValue
        
        // The "Open in Lister" has a representedObject as an NSColor, representing the text color.
        representedObjects += [TodayWidgetRowPurposeBox(purpose: .OpenLister, userInfo: listColor)]

        for item in aList.items {
            representedObjects += [ListRowRepresentedObject(item: item, color: listColor)]
        }
        
        // Add a sentinel NSNull value to represent the "No Items" represented object.
        if list.isEmpty {
            // No items in the list.
            representedObjects += [TodayWidgetRowPurposeBox(purpose: .NoItemsInList)]
        }
        
        return representedObjects
    }

    func updateWidgetContents(completionHandler: (NCUpdateResult -> Void)? = nil) {
        TodayListManager.fetchTodayDocumentURLWithCompletionHandler { todayDocumentURL in
            dispatch_async(dispatch_get_main_queue()) {
                if todayDocumentURL == nil {
                    self.listViewController.contents = [TodayWidgetRowPurposeBox(purpose: .RequiresCloud)]
                    
                    completionHandler?(.Failed)
                    
                    return
                }

                var error: NSError?

                let newDocument = ListDocument(contentsOfURL: todayDocumentURL!, makesCustomWindowControllers: false, error: &error)

                if newDocument == nil {
                    completionHandler?(.Failed)
                }
                else {
                    if self.document != nil && self.list == newDocument!.list {
                        completionHandler?(.NoData)
                    }
                    else {
                        self.document = newDocument
                        self.document.delegate = self
                        self.listViewController.contents = self.listRowRepresentedObjectsForList(newDocument!.list)

                        completionHandler?(.NewData)
                    }
                }
            }
        }
    }
}

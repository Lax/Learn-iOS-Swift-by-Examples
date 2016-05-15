/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `TodayViewController` class displays the Today view containing the contents of the Today list.
*/

import Cocoa
import NotificationCenter
import ListerKit

class TodayViewController: NSViewController, NCWidgetProviding, NCWidgetListViewDelegate, ListRowViewControllerDelegate, ListPresenterDelegate {
    // MARK: Properties

    @IBOutlet var widgetListViewController: NCWidgetListViewController!

    var document: ListDocument?

    var listPresenter: IncompleteListItemsPresenter? {
        return document?.listPresenter as? IncompleteListItemsPresenter
    }
    
    // Override the nib name to make sure that the view controller opens the correct nib.
    override var nibName: String? {
        return "TodayViewController"
    }
    
    var widgetAllowsEditing: Bool {
        return false
    }
    
    // MARK: NCWidgetProviding

    func widgetPerformUpdateWithCompletionHandler(completionHandler: NCUpdateResult -> Void) {
        TodayListManager.fetchTodayDocumentURLWithCompletionHandler { todayDocumentURL in
            dispatch_async(dispatch_get_main_queue()) {
                if todayDocumentURL == nil {
                    self.widgetListViewController.contents = [TodayWidgetRowPurposeBox(purpose: .RequiresCloud)]
                    
                    completionHandler(.Failed)
                    
                    return
                }
                
                do {
                    let newDocument = try ListDocument(contentsOfURL: todayDocumentURL!, makesCustomWindowControllers: false)
                    let existingDocumentIsUpToDate = self.document != nil && self.document?.listPresenter?.archiveableList == newDocument.listPresenter?.archiveableList
                    
                    if existingDocumentIsUpToDate {
                        completionHandler(.NoData)
                    }
                    else {
                        self.document = newDocument
                        
                        let listPresenter = IncompleteListItemsPresenter()
                        listPresenter.delegate = self
                        
                        self.document!.listPresenter = listPresenter
                        
                        completionHandler(.NewData)
                    }
                }
                catch {
                    completionHandler(.Failed)
                }
            }
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInset: NSEdgeInsets) -> NSEdgeInsets {
        return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    // MARK: NCWidgetListViewDelegate

    func widgetList(_: NCWidgetListViewController, viewControllerForRow row: Int) -> NSViewController {
        let representedObjectForRow: AnyObject = widgetListViewController.contents[row]

        // First check to see if it's a straightforward row to return a view controller for.
        if let todayWidgetRowPurpose = representedObjectForRow as? TodayWidgetRowPurposeBox {
            switch todayWidgetRowPurpose.purpose {
                case .OpenLister:    return OpenListerRowViewController()
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
        let indexOfListRowViewController = widgetListViewController.rowForViewController(listRowViewController)
        
        let item = listPresenter!.presentedListItems[indexOfListRowViewController - 1]
        listPresenter!.toggleListItem(item)
    }
    
    // MARK: ListPresenterDelegate
    
    func listPresenterDidRefreshCompleteLayout(_: ListPresenterType) {
        // Refresh the display for all of the rows.
        setListRowRepresentedObjects()
    }
    
    /**
        The following methods are not necessary to implement for the `TodayViewController` because the rows for
        `widgetListViewController` are set in both `listPresenterDidRefreshCompleteLayout(_:)` and in the
        `listPresenterDidChangeListLayout(_:isInitialLayout:)` method.
    */
    func listPresenterWillChangeListLayout(_: ListPresenterType, isInitialLayout: Bool) {}
    func listPresenter(_: ListPresenterType, didInsertListItem listItem: ListItem, atIndex index: Int) {}
    func listPresenter(_: ListPresenterType, didRemoveListItem listItem: ListItem, atIndex index: Int) {}
    func listPresenter(_: ListPresenterType, didUpdateListItem listItem: ListItem, atIndex index: Int) {}
    func listPresenter(_: ListPresenterType, didMoveListItem listItem: ListItem, fromIndex: Int, toIndex: Int) {}
    func listPresenter(_: ListPresenterType, didUpdateListColorWithColor color: List.Color) {}

    func listPresenterDidChangeListLayout(_: ListPresenterType, isInitialLayout: Bool) {
        if isInitialLayout {
            setListRowRepresentedObjects()
        }
        else {
            document?.updateChangeCount(.ChangeDone)
            
            document?.saveDocumentWithDelegate(nil, didSaveSelector: nil, contextInfo: nil)
            
            NCWidgetController.widgetController().setHasContent(true, forWidgetWithBundleIdentifier: AppConfiguration.Extensions.widgetBundleIdentifier)
        }
    }
    
    // MARK: Convenience

    func setListRowRepresentedObjects() {
        var representedObjects = [AnyObject]()

        let listColor = listPresenter!.color.notificationCenterColorValue
        
        // The "Open in Lister" has a `representedObject` as an `NSColor`, representing the text color.
        representedObjects += [TodayWidgetRowPurposeBox(purpose: .OpenLister, userInfo: listColor)]

        for listItem in listPresenter!.presentedListItems {
            representedObjects += [ListRowRepresentedObject(listItem: listItem, color: listColor)]
        }
        
        // Add a `.NoItemsInList` box to represent the "No Items" represented object.
        if listPresenter!.isEmpty {
            representedObjects += [TodayWidgetRowPurposeBox(purpose: .NoItemsInList)]
        }

        widgetListViewController.contents = representedObjects
    }
}

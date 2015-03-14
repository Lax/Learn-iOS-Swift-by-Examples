/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListDocumentsViewController` displays a list of available documents for users to open.
*/

import UIKit
import ListerKit

class ListDocumentsViewController: UITableViewController, ListsControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate {
    // MARK: Types

    struct MainStoryboard {
        struct ViewControllerIdentifiers {
            static let listViewController = "listViewController"
            static let listViewNavigationController = "listViewNavigationController"
        }
        
        struct TableViewCellIdentifiers {
            static let listDocumentCell = "listDocumentCell"
        }
        
        struct SegueIdentifiers {
            static let newListDocument = "newListDocument"
            static let showListDocument = "showListDocument"
            static let showListDocumentFromUserActivity = "showListDocumentFromUserActivity"
        }
    }
    
    // MARK: Properties

    var listsController: ListsController! {
        didSet {
            listsController.delegate = self
        }
    }
    
    private var pendingLaunchContext: AppLaunchContext?

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 44.0
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: List.Color.Gray.colorValue
        ]
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleContentSizeCategoryDidChangeNotification:", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: List.Color.Gray.colorValue
        ]
        
        let grayListColor = List.Color.Gray.colorValue
        navigationController?.navigationBar.tintColor = grayListColor
        navigationController?.toolbar?.tintColor = grayListColor
        tableView.tintColor = grayListColor
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let launchContext = pendingLaunchContext {
            configureViewControllerWithLaunchContext(launchContext)
        }
        
        pendingLaunchContext = nil
    }
    
    // MARK: Lifetime
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    // MARK: UIResponder
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        // Obtain an app launch context from the provided activity and configure the view controller with it.
        let launchContext = AppLaunchContext(userActivity: activity)
        
        configureViewControllerWithLaunchContext(launchContext)
    }
    
    // MARK: IBActions

    /**
        Note that the document picker requires that code signing, entitlements, and provisioning for
        the project have been configured before you run Lister. If you run the app without configuring
        entitlements correctly, an exception when this method is invoked (i.e. when the "+" button is
        clicked).
    */
    @IBAction func pickDocument(barButtonItem: UIBarButtonItem) {
        let documentMenu = UIDocumentMenuViewController(documentTypes: [AppConfiguration.listerUTI], inMode: .Open)
        documentMenu.delegate = self

        let newDocumentTitle = NSLocalizedString("New List", comment: "")
        documentMenu.addOptionWithTitle(newDocumentTitle, image: nil, order: .First) {
            // Show the NewListDocumentController.
            self.performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.newListDocument, sender: self)
        }
        
        documentMenu.modalPresentationStyle = .Popover
        documentMenu.popoverPresentationController?.barButtonItem = barButtonItem
        
        presentViewController(documentMenu, animated: true, completion: nil)
    }
    
    // MARK: UIDocumentMenuDelegate
    
    func documentMenu(documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self

        presentViewController(documentPicker, animated: true, completion: nil)
    }
    
    func documentMenuWasCancelled(documentMenu: UIDocumentMenuViewController) {
        /**
            The user cancelled interacting with the document menu. In your own app, you may want to
            handle this with other logic.
        */
    }
    
    // MARK: UIPickerViewDelegate
    
    func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
        // The user selected the document and it should be picked up by the `ListsController`.
    }

    func documentPickerWasCancelled(controller: UIDocumentPickerViewController) {
        /**
            The user cancelled interacting with the document picker. In your own app, you may want to
            handle this with other logic.
        */
    }
    
    // MARK: ListsControllerDelegate
    
    func listsControllerWillChangeContent(listsController: ListsController) {
        tableView.beginUpdates()
    }
    
    func listsController(listsController: ListsController, didInsertListInfo listInfo: ListInfo, atIndex index: Int) {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    func listsController(listsController: ListsController, didRemoveListInfo listInfo: ListInfo, atIndex index: Int) {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    func listsController(listsController: ListsController, didUpdateListInfo listInfo: ListInfo, atIndex index: Int) {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as ListCell
        cell.label.text = listInfo.name
        
        listInfo.fetchInfoWithCompletionHandler {
            /* 
                The fetchInfoWithCompletionHandler(_:) method calls its completion handler on a background
                queue, dispatch back to the main queue to make UI updates.
            */
            dispatch_async(dispatch_get_main_queue()) {
                // Make sure that the list info is still visible once the color has been fetched.
                let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() as [NSIndexPath]

                if find(indexPathsForVisibleRows, indexPath) != nil {
                    cell.listColorView.backgroundColor = listInfo.color!.colorValue
                }
            }
        }
    }
    
    func listsControllerDidChangeContent(listsController: ListsController) {
        tableView.endUpdates()
    }
    
    func listsController(listsController: ListsController, didFailCreatingListInfo listInfo: ListInfo, withError error: NSError) {
        let title = NSLocalizedString("Failed to Create List", comment: "")
        let message = error.localizedDescription
        let okActionTitle = NSLocalizedString("OK", comment: "")
        
        let errorOutController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let action = UIAlertAction(title: okActionTitle, style: .Cancel, handler: nil)
        errorOutController.addAction(action)
        
        presentViewController(errorOutController, animated: true, completion: nil)
    }
    
    func listsController(listsController: ListsController, didFailRemovingListInfo listInfo: ListInfo, withError error: NSError) {
        let title = NSLocalizedString("Failed to Delete List", comment: "")
        let message = error.localizedFailureReason
        let okActionTitle = NSLocalizedString("OK", comment: "")
        
        let errorOutController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let action = UIAlertAction(title: okActionTitle, style: .Cancel, handler: nil)
        errorOutController.addAction(action)
        
        presentViewController(errorOutController, animated: true, completion: nil)
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If the controller is nil, return no rows. Otherwise return the number of total rows.
        return listsController?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.listDocumentCell, forIndexPath: indexPath) as ListCell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        switch cell {
            case let listCell as ListCell:
                let listInfo = listsController[indexPath.row]
                
                listCell.label.text = listInfo.name
                listCell.label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
                listCell.listColorView.backgroundColor = UIColor.clearColor()
                
                // Once the list info has been loaded, update the associated cell's properties.
                listInfo.fetchInfoWithCompletionHandler {
                    /*
                        The fetchInfoWithCompletionHandler(_:) method calls its completion handler on a background
                        queue, dispatch back to the main queue to make UI updates.
                    */
                    dispatch_async(dispatch_get_main_queue()) {
                        // Make sure that the list info is still visible once the color has been fetched.
                        let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() as [NSIndexPath]
                        
                        if find(indexPathsForVisibleRows, indexPath) != nil {
                            listCell.listColorView.backgroundColor = listInfo.color!.colorValue
                        }
                    }
                }
            default:
                fatalError("Attempting to configure an unknown or unsupported cell type in ListDocumentViewController.")
        }
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // MARK: UIStoryboardSegue Handling

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == MainStoryboard.SegueIdentifiers.newListDocument {
            let newListDocumentController = segue.destinationViewController as NewListDocumentController

            newListDocumentController.listsController = listsController
        }
        else if segue.identifier == MainStoryboard.SegueIdentifiers.showListDocument || segue.identifier == MainStoryboard.SegueIdentifiers.showListDocumentFromUserActivity {
            let listNavigationController = segue.destinationViewController as UINavigationController
            let listViewController = listNavigationController.topViewController as ListViewController
            listViewController.listsController = listsController
            
            listViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
            listViewController.navigationItem.leftItemsSupplementBackButton = true
            
            if segue.identifier == MainStoryboard.SegueIdentifiers.showListDocument {
                let indexPath = tableView.indexPathForSelectedRow()!
                listViewController.configureWithListInfo(listsController[indexPath.row])
            }
            else if segue.identifier == MainStoryboard.SegueIdentifiers.showListDocumentFromUserActivity {
                let userActivityListInfo = sender as ListInfo
                listViewController.configureWithListInfo(userActivityListInfo)
            }
        }
    }

    // MARK: Notifications
    
    func handleContentSizeCategoryDidChangeNotification(_: NSNotification) {
        tableView.setNeedsLayout()
    }
    
    // MARK: Convenience
    
    func configureViewControllerWithLaunchContext(launchContext: AppLaunchContext) {
        /**
            If there is a list currently displayed; pop to the root view controller (this controller) and
            continue configuration from there. Otherwise, configure the view controller directly.
        */
        if navigationController?.topViewController is UINavigationController {
            navigationController?.popToRootViewControllerAnimated(false)
            pendingLaunchContext = launchContext
            return
        }
        
        let listInfo = ListInfo(URL: launchContext.listURL)
        listInfo.color = launchContext.listColor
        
        performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.showListDocumentFromUserActivity, sender: listInfo)
    }
    
    
}

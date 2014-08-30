/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `ListDocumentsViewController` displays a list of available documents for users to open.
            
*/

import UIKit
import ListerKit

class ListDocumentsViewController: UITableViewController, ListControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate {
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
        }
    }
    
    // MARK: Properties

    var listController: ListController! {
        didSet {
            listController.delegate = self
        }
    }

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setNeedsStatusBarAppearanceUpdate()
        
        navigationController.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: List.Color.Gray.colorValue
        ]
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleContentSizeCategoryDidChangeNotification:", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: List.Color.Gray.colorValue
        ]
        
        let grayListColor = List.Color.Gray.colorValue
        navigationController.navigationBar.tintColor = grayListColor
        navigationController.toolbar.tintColor = grayListColor
        tableView.tintColor = grayListColor
    }
    
    // MARK: Lifetime
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    // MARK: Setup
    
    func selectListWithListInfo(listInfo: ListInfo) {
        if splitViewController == nil {
            return
        }
        
        // A nested configuration function to re-use for list selection.
        func configureListViewController(listViewController: ListViewController) {
            listViewController.listController = listController
            listViewController.configureWithListInfo(listInfo)
        }
        
        if splitViewController.collapsed {
            let listViewController = storyboard.instantiateViewControllerWithIdentifier(MainStoryboard.ViewControllerIdentifiers.listViewController) as ListViewController
            
            configureListViewController(listViewController)

            showDetailViewController(listViewController, sender: self)
        }
        else {
            let navigationController = storyboard.instantiateViewControllerWithIdentifier(MainStoryboard.ViewControllerIdentifiers.listViewNavigationController) as UINavigationController

            let listViewController = navigationController.topViewController as ListViewController
            
            configureListViewController(listViewController)
            
            splitViewController.viewControllers = [splitViewController.viewControllers.first!, UIViewController()]

            showDetailViewController(navigationController, sender: self)
        }
    }
    
    // MARK: IBActions

    /**
        Note that the document picker requires that code signing, entitlements, and provisioning for
        the project have been configured before you run Lister. If you run the app without configuring
        entitlements correctly, an exception when this method is invoked (i.e. when the "+" button is
        clicked).
    */
    @IBAction func pickDocument() {
        let documentMenu = UIDocumentMenuViewController(documentTypes: [AppConfiguration.listerUTI], inMode: .Open)
        documentMenu.delegate = self

        let newDocumentTitle = NSLocalizedString("New List", comment: "")
        documentMenu.addOptionWithTitle(newDocumentTitle, image: nil, order: .First) {
            // Show the NewListDocumentController.
            self.performSegueWithIdentifier(MainStoryboard.SegueIdentifiers.newListDocument, sender: self)
        }
        
        documentMenu.modalPresentationStyle = .Popover
        
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
        // The user selected the document and it should be picked up by the `ListController`.
    }

    func documentPickerWasCancelled(controller: UIDocumentPickerViewController) {
        /**
            The user cancelled interacting with the document picker. In your own app, you may want to
            handle this with other logic.
        */
    }
    
    // MARK: ListControllerDelegate
    
    func listControllerWillChangeContent(listController: ListController) {
        dispatch_async(dispatch_get_main_queue(), tableView.beginUpdates)
    }
    
    func listController(listController: ListController, didInsertListInfo listInfo: ListInfo, atIndex index: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func listController(listController: ListController, didRemoveListInfo listInfo: ListInfo, atIndex index: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func listController(listController: ListController, didUpdateListInfo listInfo: ListInfo, atIndex index: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as ListCell
            cell.label.text = listInfo.name
            
            listInfo.fetchInfoWithCompletionHandler {
                dispatch_async(dispatch_get_main_queue()) {
                    // Make sure that the list info is still visible once the color has been fetched.
                    let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() as [NSIndexPath]

                    if find(indexPathsForVisibleRows, indexPath) != nil {
                        cell.listColorView.backgroundColor = listInfo.color!.colorValue
                    }
                }
            }
        }
    }
    
    func listControllerDidChangeContent(listController: ListController) {
        dispatch_async(dispatch_get_main_queue(), tableView.endUpdates)
    }
    
    func listController(listController: ListController, didFailCreatingListInfo listInfo: ListInfo, withError error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            let title = NSLocalizedString("Failed to Create List", comment: "")
            let message = error.localizedDescription
            let okActionTitle = NSLocalizedString("OK", comment: "")
            
            let errorOutController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            
            let action = UIAlertAction(title: okActionTitle, style: .Cancel, handler: nil)
            errorOutController.addAction(action)
            
            self.presentViewController(errorOutController, animated: true, completion: nil)
        }
    }
    
    func listController(listController: ListController, didFailRemovingListInfo listInfo: ListInfo, withError error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            let title = NSLocalizedString("Failed to Delete List", comment: "")
            let message = error.localizedFailureReason
            let okActionTitle = NSLocalizedString("OK", comment: "")
            
            let errorOutController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            
            let action = UIAlertAction(title: okActionTitle, style: .Cancel, handler: nil)
            errorOutController.addAction(action)
            
            self.presentViewController(errorOutController, animated: true, completion: nil)
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If the controller is nil, return no rows. Otherwise return the number of total rows.
        return listController?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.listDocumentCell, forIndexPath: indexPath) as ListCell

        let listInfo = listController[indexPath.row]
        
        cell.label.text = listInfo.name
        cell.label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        cell.listColorView.backgroundColor = UIColor.clearColor()
        
        // Once the list info has been loaded, update the associated cell's properties.
        listInfo.fetchInfoWithCompletionHandler {
            dispatch_async(dispatch_get_main_queue()) {
                // Make sure that the list info is still visible once the color has been fetched.
                let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() as [NSIndexPath]
                
                if find(indexPathsForVisibleRows, indexPath) != nil {
                    cell.listColorView.backgroundColor = listInfo.color!.colorValue
                }
            }
        }

        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let listInfo = listController[indexPath.row]
        
        selectListWithListInfo(listInfo)
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // MARK: UIStoryboardSegue Handling
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject) {
        if segue.identifier == MainStoryboard.SegueIdentifiers.newListDocument {
            let newListController = segue.destinationViewController as NewListDocumentController

            newListController.listController = self.listController
        }
    }

    // MARK: Notifications
    
    func handleContentSizeCategoryDidChangeNotification(_: NSNotification) {
        tableView.setNeedsLayout()
    }
}

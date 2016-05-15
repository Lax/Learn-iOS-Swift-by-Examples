/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListDocumentsViewController` displays a list of available documents for users to open.
*/

import UIKit
import WatchConnectivity
import ListerKit

class ListDocumentsViewController: UITableViewController, ListsControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate, WCSessionDelegate, SegueHandlerType {
    // MARK: Types

    struct MainStoryboard {
        struct ViewControllerIdentifiers {
            static let listViewController = "listViewController"
            static let listViewNavigationController = "listViewNavigationController"
        }
        
        struct TableViewCellIdentifiers {
            static let listDocumentCell = "listDocumentCell"
        }
    }
    
    // MARK: SegueHandlerType
    
    enum SegueIdentifier: String {
        case ShowNewListDocument
        case ShowListDocument
        case ShowListDocumentFromUserActivity
    }
    
    // MARK: Properties

    var listsController: ListsController! {
        didSet {
            listsController.delegate = self
        }
    }
    
    private var pendingLaunchContext: AppLaunchContext?
    
    private var watchAppInstalledAtLastStateChange = false
    
    // MARK: Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if WCSession.isSupported() {
            WCSession.defaultSession().delegate = self
            WCSession.defaultSession().activateSession()
        }
    }

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 44.0
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: List.Color.Gray.colorValue
        ]
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListDocumentsViewController.handleContentSizeCategoryDidChangeNotification(_:)), name: UIContentSizeCategoryDidChangeNotification, object: nil)
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
        guard let launchContext = AppLaunchContext(userActivity: activity, listsController: listsController) else { return }
        
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
            // Show the `NewListDocumentController`.
            self.performSegueWithIdentifier(.ShowNewListDocument, sender: self)
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
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    func listsControllerDidChangeContent(listsController: ListsController) {
        tableView.endUpdates()
        
        // This method will handle interactions with the watch connectivity session on behalf of the app.
        updateWatchConnectivitySessionApplicationContext()
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
        return tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.listDocumentCell, forIndexPath: indexPath) as! ListCell
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
                        guard let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows else { return }
                        
                        if indexPathsForVisibleRows.contains(indexPath) {
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
    
    // MARK: WCSessionDelegate
    
    func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
        if let error = error {
            print("session activation failed with error: \(error.localizedDescription)")
            return
        }
        
        // Return early if `session` is not currently `.Activated`.
        guard activationState == .Activated else { return }
        
        updateWatchConnectivitySessionApplicationContext()
    }
    
    func sessionDidBecomeInactive(session: WCSession) {
        /*
             The `sessionDidBecomeInactive(_:)` callback indicates sending has been disabled. If your iOS app
             sends content to its Watch extension it will need to stop trying at this point. This sample
             checks the session state before transmitting so no further action is required.
         */
    }
    
    func sessionDidDeactivate(session: WCSession) {
        /*
             The `sessionDidDeactivate(_:)` callback indicates `WCSession` is finished delivering content to
             the iOS app. iOS apps that process content delivered from their Watch Extension should finish
             processing that content and call `activateSession()`. This sample immediately calls
             `activateSession()` as the data provided by the Watch Extension is handled immediately.
         */
        WCSession.defaultSession().activateSession()
    }
    
    func sessionWatchStateDidChange(session: WCSession) {
        // Return early if `session` is not currently `.Activated`.
        guard session.activationState == .Activated else { return }
        
        if !watchAppInstalledAtLastStateChange && session.watchAppInstalled {
            watchAppInstalledAtLastStateChange = session.watchAppInstalled
            updateWatchConnectivitySessionApplicationContext()
        }
    }
    
    func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        if let error = error {
            print("\(#function), file: \(fileTransfer.file.fileURL), error: \(error.localizedDescription)")
        }
    }
    
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        guard let lastPathComponent = file.fileURL.lastPathComponent else { return }
        listsController.copyListFromURL(file.fileURL, toListWithName:(lastPathComponent as NSString).stringByDeletingPathExtension)
    }
    
    // MARK: UIStoryboardSegue Handling

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            case .ShowNewListDocument:
                let newListDocumentController = segue.destinationViewController as! NewListDocumentController
                
                newListDocumentController.listsController = listsController

            case .ShowListDocument, .ShowListDocumentFromUserActivity:
                let listNavigationController = segue.destinationViewController as! UINavigationController
                let listViewController = listNavigationController.topViewController as! ListViewController
                listViewController.listsController = listsController
                
                listViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
                listViewController.navigationItem.leftItemsSupplementBackButton = true
            
                if segueIdentifier == .ShowListDocument {
                    let indexPath = tableView.indexPathForSelectedRow!
                    listViewController.configureWithListInfo(listsController[indexPath.row])
                }
                else {
                    let userActivityListInfo = sender as! ListInfo
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
            dispatch_async(dispatch_get_main_queue()) {
                // Ensure that any UI updates occur on the main queue.
                self.navigationController?.popToRootViewControllerAnimated(false)
                self.pendingLaunchContext = launchContext
            }
            return
        }
        
        let listInfo = ListInfo(URL: launchContext.listURL)
        listInfo.color = launchContext.listColor
        
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier(.ShowListDocumentFromUserActivity, sender: listInfo)
        }
    }
    
    func updateWatchConnectivitySessionApplicationContext() {
        // Return if `WCSession` is not supported on this iOS device or the `listsController` is unavailable.
        guard let listsController = listsController where WCSession.isSupported() else { return }
        
        let session = WCSession.defaultSession()
        
        // Do not proceed if `session` is not currently `.Activated`.
        guard session.activationState == .Activated else { return }
        
        // Do not proceed if the watch app is not installed on the paired watch.
        guard session.watchAppInstalled else { return }
        
        // This array will be used to collect the data about the lists for the application context.
        var lists = [[String: AnyObject]]()
        // A background queue to execute operations on to fetch the information about the lists.
        let queue = NSOperationQueue()
        
        // This operation will execute last and will actually update the application context.
        let updateApplicationContextOperation = NSBlockOperation {
            do {
                // Do not proceed if `session` is not currently `.Activated`.
                guard session.activationState == .Activated else { return }
                
                try session.updateApplicationContext([AppConfiguration.ApplicationActivityContext.currentListsKey: lists])
            }
            catch let error as NSError {
                print("Error updating watch application context: \(error.localizedDescription)")
            }
            // Requiring an additional catch to satisfy exhaustivity is a known issue.
            catch {}
        }
        
        // Loop through the available lists in order to accumulate contextual information about them.
        for idx in 0..<listsController.count {
            // Obtain the list info object from the controller.
            let info = listsController[idx]
            
            // This operation will fetch the information for an individual list.
            let listInfoOperation = NSBlockOperation {
                // The `fetchInfoWithCompletionHandler(_:)` method executes asynchronously. Use a semaphore to wait.
                let semaphore = dispatch_semaphore_create(0)
                info.fetchInfoWithCompletionHandler {
                    // Now that the `info` object is fully populated. Add an entry to the `lists` dictionary.
                    lists.append([
                        AppConfiguration.ApplicationActivityContext.listNameKey: info.name,
                        AppConfiguration.ApplicationActivityContext.listColorKey: info.color!.rawValue
                    ])
                
                    // Signal the semaphore indicating that it can stop waiting.
                    dispatch_semaphore_signal(semaphore)
                }
            
                // Wait on the semaphore to ensure the operation doesn't return until the fetch is complete.
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }
            
            // Depending on `listInfoOperation` ensures it completes before `updateApplicationContextOperation` executes.
            updateApplicationContextOperation.addDependency(listInfoOperation)
            queue.addOperation(listInfoOperation)
            
            // Use file coordination to obtain exclusive access to read the file in order to initiate a transfer.
            let fileCoordinator = NSFileCoordinator()
            let readingIntent = NSFileAccessIntent.readingIntentWithURL(info.URL, options: [])
            fileCoordinator.coordinateAccessWithIntents([readingIntent], queue: NSOperationQueue()) { accessError in
                if accessError != nil {
                    return
                }
                
                // Do not proceed if `session` is not currently `.Activated`.
                guard session.activationState == .Activated else { return }
                
                // Iterate through outstanding transfers; and cancel any for the same URL as they are obsolete.
                for transfer in session.outstandingFileTransfers {
                    if transfer.file.fileURL == readingIntent.URL {
                        transfer.cancel()
                        break
                    }
                }
                
                // Initiate the new transfer.
                session.transferFile(readingIntent.URL, metadata: nil)
            }
        }
        
        queue.addOperation(updateApplicationContextOperation)
    }
}

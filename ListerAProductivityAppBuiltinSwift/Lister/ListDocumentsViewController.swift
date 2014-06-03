/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Handles displaying a list of available documents for users to open.
            
*/

import UIKit
import ListerKit

class ListDocumentsViewController: UITableViewController, ListViewControllerDelegate, NewListDocumentControllerDelegate {
    // MARK: Types

    struct MainStoryboard {
        struct ViewControllerIdentifiers {
            static let listViewController = "listViewController"
            static let listViewNavigationController = "listViewNavigationController"
            static let emptyViewController = "emptyViewController"
        }
        
        struct TableViewCellIdentifiers {
            static let listDocumentCell = "listDocumentCell"
        }
        
        struct SegueIdentifiers {
            static let newListDocument = "newListDocument"
        }
    }
    
    var listInfos = ListInfo[]()
    
    var documentMetadataQuery: NSMetadataQuery?
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        
        navigationController.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: List.Color.Gray.colorValue
        ]
        
        ListCoordinator.sharedListCoordinator.updateDocumentStorageContainerURL()
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleListColorDidChangeNotification:", name: ListViewController.Notifications.ListColorDidChange.name, object: nil)
        notificationCenter.addObserver(self, selector: "handleContentSizeCategoryDidChangeNotification:", name: UIContentSizeCategoryDidChangeNotification, object: nil)
        
        // When the desired storage changes, start the query.
        notificationCenter.addObserver(self, selector: "startQuery", name: ListCoordinator.Notifications.StorageDidChange.name, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline),
            NSForegroundColorAttributeName: List.Color.Gray.colorValue
        ]
        
        navigationController.navigationBar.tintColor = List.Color.Gray.colorValue
        navigationController.toolbar.tintColor = List.Color.Gray.colorValue
        tableView.tintColor = List.Color.Gray.colorValue
    }
    
    override func viewDidAppear(animated: Bool)  {
        super.viewDidAppear(animated)
        
        setupUserStoragePreferences()
    }
    
    // MARK: Lifetime
    
    deinit {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        // Lister notifications.
        notificationCenter.removeObserver(self, name: ListViewController.Notifications.ListColorDidChange.name, object: nil)
        notificationCenter.removeObserver(self, name: ListCoordinator.Notifications.StorageDidChange.name, object: nil)
        
        // System notifications.
        notificationCenter.removeObserver(self, name: UIContentSizeCategoryDidChangeNotification, object: nil)
        notificationCenter.removeObserver(self, name: NSMetadataQueryDidFinishGatheringNotification, object: nil)
        notificationCenter.removeObserver(self, name: NSMetadataQueryDidUpdateNotification, object: nil)
    }
    
    // MARK: Setup
    
    func selectListWithListInfo(listInfo: ListInfo) {
        if !splitViewController { return }
        
        // A shared configuration function for list selection.
        func configureListViewController(listViewController: ListViewController) {
            if listInfo.isLoaded {
                listViewController.configureWithListInfo(listInfo)
            }
            else {
                listInfo.fetchInfoWithCompletionHandler {
                    listViewController.configureWithListInfo(listInfo)
                }
            }

            listViewController.delegate = self
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
            
            splitViewController.viewControllers = [splitViewController.viewControllers[0], UIViewController()]
            showDetailViewController(navigationController, sender: self)
        }
    }
    
    func setupUserStoragePreferences() {
        let (storageOption, accountDidChange, cloudAvailable) = AppConfiguration.sharedConfiguration.storageState
        
        if accountDidChange {
            notifyUserOfAccountChange()
        }
        
        if cloudAvailable {
            if storageOption == .NotSet {
                promptUserForStorageOption()
            }
            else {
                startQuery()
            }
        }
        else {
            AppConfiguration.sharedConfiguration.storageOption = .NotSet
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listInfos.count
    }
    
    override func tableView(_: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.TableViewCellIdentifiers.listDocumentCell, forIndexPath: indexPath) as ListCell

        let listInfo = listInfos[indexPath.row]
        
        cell.label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        
        cell.listColor.backgroundColor = UIColor.clearColor()
        
        // Show an empty string as the text since it may need to load.
        cell.text = ""
        
        // Once the list info has been loaded, update the associated cell's properties.
        func infoHandler() {
            cell.label.text = listInfo.name
            cell.listColor.backgroundColor = listInfo.color!.colorValue
        }
        
        if listInfo.isLoaded {
            infoHandler()
        }
        else {
            listInfo.fetchInfoWithCompletionHandler(infoHandler)
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let listInfo = listInfos[indexPath.row]

        if listInfo.isLoaded {
            selectListWithListInfo(listInfo)
        }
        else {
            listInfo.fetchInfoWithCompletionHandler {
                self.selectListWithListInfo(listInfo)
            }
        }
    }

    override func tableView(_: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(_: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // MARK: ListViewControllerDelegate
    
    func listViewControllerDidDeleteList(listViewController: ListViewController) {
        if !splitViewController.collapsed {
            let emptyViewController = storyboard.instantiateViewControllerWithIdentifier(MainStoryboard.ViewControllerIdentifiers.emptyViewController) as UIViewController
            splitViewController.showDetailViewController(emptyViewController, sender: nil)
        }
        
        // Make sure to deselect the row for the list document that was open, since we are in the process of deleting it.
        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow(), animated: false)
        
        deleteListAtURL(listViewController.documentURL)
    }
    
    // MARK: NewListDocumentControllerDelegate
    
    func newListDocumentController(_: NewListDocumentController, didCreateDocumentWithListInfo listInfo: ListInfo) {
        if AppConfiguration.sharedConfiguration.storageOption != .Cloud {
            
            insertListInfo(listInfo) { index in
                let indexPathForInsertedRow = NSIndexPath(forRow: index, inSection: 0)
                self.tableView.insertRowsAtIndexPaths([indexPathForInsertedRow], withRowAnimation: .Automatic)
            }
        }
    }
    
    // MARK: UIStoryboardSegue Handling
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject) {
        if segue.identifier == MainStoryboard.SegueIdentifiers.newListDocument {
            let newListController = segue.destinationViewController as NewListDocumentController
            newListController.delegate = self
        }
    }
    
    // MARK: Convenience
    
    func deleteListAtURL(url: NSURL) {
        // Delete the requested document asynchronously.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            ListCoordinator.sharedListCoordinator.deleteFileAtURL(url)
        }
        
        // Update the document list and remove the row from the table view.
        removeListInfoWithProvider(url) { index in
            let indexPathForRemoval = NSIndexPath(forRow: index, inSection: 0)
            self.tableView.deleteRowsAtIndexPaths([indexPathForRemoval], withRowAnimation: .Automatic)
        }
    }
    
    // MARK: List Management
    
    func startQuery() {
        documentMetadataQuery?.stopQuery()
        
        if AppConfiguration.sharedConfiguration.storageOption == .Cloud {
            startMetadataQuery()
        }
        else {
            startLocalQuery()
        }
    }
    
    func startLocalQuery() {
        let documentsDirectory = ListCoordinator.sharedListCoordinator.documentsDirectory
        
        let defaultManager = NSFileManager.defaultManager()
        
        // Fetch the list documents from container documents directory.
        let localDocumentURLs = defaultManager.contentsOfDirectoryAtURL(documentsDirectory, includingPropertiesForKeys: nil, options: .SkipsPackageDescendants, error: nil) as NSURL[]
        
        processURLs(localDocumentURLs)
    }
    
    func processURLs(urls: NSURL[]) {
        let previousListInfos = listInfos
        
        // Processing metadata items doesn't involve much change in the size of the array, so we want to keep the
        // same capacity.
        listInfos.removeAll(keepCapacity: true)
        
        sort(urls) { $0.lastPathComponent < $1.lastPathComponent }
        
        for url in urls {
            if url.pathExtension == AppConfiguration.listerFileExtension {
                insertListInfoWithProvider(url)
            }
        }
        
        processListInfoDifferences(previousListInfos)
    }
    
    func processMetadataItems() {
        let previousListInfos = listInfos
        
        // Processing metadata items doesn't involve much change in the size of the array, so we want to keep the
        // same capacity.
        listInfos.removeAll(keepCapacity: true)
        
        let metadataItems = documentMetadataQuery!.results as NSMetadataItem[]
        
        sort(metadataItems) { lhs, rhs in
            return (lhs.valueForAttribute(NSMetadataItemFSNameKey) as String) < (rhs.valueForAttribute(NSMetadataItemFSNameKey) as String)
        }
        
        for metadataItem in metadataItems {
            insertListInfoWithProvider(metadataItem)
        }
        
        processListInfoDifferences(previousListInfos)
    }
    
    func startMetadataQuery() {
        if !documentMetadataQuery {
            let metadataQuery = NSMetadataQuery()
            documentMetadataQuery = metadataQuery
            documentMetadataQuery!.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            
            documentMetadataQuery!.predicate = NSPredicate(format: "(%K.pathExtension = %@)", argumentArray: [NSMetadataItemFSNameKey, AppConfiguration.listerFileExtension])
            
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
    
    func processListInfoDifferences(previousListInfo: ListInfo[]) {
        var insertionRows = NSIndexPath[]()
        var deletionRows = NSIndexPath[]()
        
        for (idx, listInfo) in enumerate(listInfos) {
            if let found = find(previousListInfo, listInfo) {
                listInfos[idx].color = previousListInfo[found].color
                listInfos[idx].name = previousListInfo[found].name
            } else {
                let indexPath = NSIndexPath(forRow: idx, inSection: 0)
                insertionRows.append(indexPath)
            }
        }
        
        for (idx, listInfo) in enumerate(previousListInfo) {
            if let found = find(listInfos, listInfo) {
                listInfos[found].color = listInfo.color
                listInfos[found].name = listInfo.name
            } else {
                let indexPath = NSIndexPath(forRow: idx, inSection: 0)
                deletionRows.append(indexPath)
            }
        }
        
        self.tableView.beginUpdates()
        
        self.tableView.deleteRowsAtIndexPaths(deletionRows, withRowAnimation: .Automatic)
        self.tableView.insertRowsAtIndexPaths(insertionRows, withRowAnimation: .Automatic)
        
        self.tableView.endUpdates()
    }
    
    func insertListInfo(listInfo: ListInfo, completionHandler: (Int -> Void)? = nil) {
        listInfos.append(listInfo)
        
        sort(listInfos) { $0.name < $1.name }
        
        let indexOfInsertedInfo = find(listInfos, listInfo)!
        completionHandler?(indexOfInsertedInfo)
    }
    
    func removeListInfo(listInfo: ListInfo, completionHandler: (Int -> Void)? = nil) {
        if let index = find(listInfos, listInfo) {
            listInfos.removeAtIndex(index)
            completionHandler?(index)
        }
    }
    
    // ListInfoProvider objects are used to allow us to interact naturally with ListInfo objects that may originate from
    // local URLs or NSMetadataItems representing document in the cloud.
    func insertListInfoWithProvider(provider: ListInfoProvider, completionHandler: (Int -> Void)? = nil) {
        let listInfo = ListInfo(provider: provider)
        insertListInfo(listInfo, completionHandler: completionHandler)
    }
    
    func removeListInfoWithProvider(provider: ListInfoProvider, completionHandler: (Int -> Void)? = nil) {
        let listInfo = ListInfo(provider: provider)
        removeListInfo(listInfo, completionHandler: completionHandler)
    }
    
    // MARK: Notifications

    // The color of the list was changed in the ListViewController, so we need to update the color in our list of documents.
    func handleListColorDidChangeNotification(notification: NSNotification) {
        let userInfo = notification.userInfo
        let rawColor = userInfo[ListViewController.Notifications.ListColorDidChange.colorUserInfoKey] as Int
        let url = userInfo[ListViewController.Notifications.ListColorDidChange.URLUserInfoKey] as NSURL
        
        let color = List.Color.fromRaw(rawColor)!
        let listInfo = ListInfo(provider: url)
        
        if let index = find(listInfos, listInfo) {
            listInfos[index].color = color
            
            let indexPathForRow = NSIndexPath(forRow: index, inSection: 0)
            
            let cell = tableView.cellForRowAtIndexPath(indexPathForRow) as ListCell
            
            cell.listColor.backgroundColor = color.colorValue
        }
    }
    
    func handleContentSizeCategoryDidChangeNotification(_: NSNotification) {
        tableView.setNeedsLayout()
    }

    // MARK: User Storage Preference Related Alerts

    func notifyUserOfAccountChange() {
        let title = NSLocalizedString("iCloud Sign Out", comment: "")
        let message = NSLocalizedString("You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents.", comment: "")
        let okActionTitle = NSLocalizedString("OK", comment: "")
        
        let signedOutController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let action = UIAlertAction(title: okActionTitle, style: .Cancel, handler: nil)
        signedOutController.addAction(action)
        
        self.presentViewController(signedOutController, animated: true, completion: nil)
    }
    
    func promptUserForStorageOption() {
        let title = NSLocalizedString("Choose Storage Option", comment: "")
        let message = NSLocalizedString("Do you want to store documents in iCloud or only on this device?", comment: "")
        let localOnlyActionTitle = NSLocalizedString("Local Only", comment: "")
        let cloudActionTitle = NSLocalizedString("iCloud", comment: "")

        let storageController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let localOption = UIAlertAction(title: localOnlyActionTitle, style: .Default) { localAction in
            AppConfiguration.sharedConfiguration.storageOption = .Local
        }
        storageController.addAction(localOption)
        
        let cloudOption = UIAlertAction(title: cloudActionTitle, style: .Default) { cloudAction in
            AppConfiguration.sharedConfiguration.storageOption = .Cloud
        }
        storageController.addAction(cloudOption)
        
        presentViewController(storageController, animated: true, completion: nil)
    }
}

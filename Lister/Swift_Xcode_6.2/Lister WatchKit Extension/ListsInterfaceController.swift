/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListInterfaceController` that presents a single list managed by a `ListPresenterType` instance.
*/

import WatchKit
import ListerKit

class ListsInterfaceController: WKInterfaceController, ListsControllerDelegate {
    // MARK: Types
    
    struct Storyboard {
        struct RowTypes {
            static let list = "ListsInterfaceControllerListRowType"
            static let noLists = "ListsInterfaceControllerNoListsRowType"
        }
        
        struct Segues {
            static let listSelection = "ListsInterfaceControllerListSelectionSegue"
        }
    }
    
    // MARK: Properties
    
    @IBOutlet weak var interfaceTable: WKInterfaceTable!
    
    var listsController: ListsController!

    // MARK: Initializers
    
    override init() {
        super.init()

        listsController = AppConfiguration.sharedConfiguration.listsControllerForCurrentConfigurationWithPathExtension(AppConfiguration.listerFileExtension)

        let noListsIndexSet = NSIndexSet(index: 0)
        interfaceTable.insertRowsAtIndexes(noListsIndexSet, withRowType: Storyboard.RowTypes.noLists)
        
        if AppConfiguration.sharedConfiguration.isFirstLaunch {
            println("Lister does not currently support configuring a storage option before the iOS app is launched. Please launch the iOS app first. See the Release Notes section in README.md for more information.")
        }
    }
    
    // MARK: ListsControllerDelegate

    func listsController(listsController: ListsController, didInsertListInfo listInfo: ListInfo, atIndex index: Int) {
        let indexSet = NSIndexSet(index: index)
        
        // The lists controller was previously empty. Remove the "no lists" row.
        if index == 0 && listsController.count == 1 {
            interfaceTable.removeRowsAtIndexes(indexSet)
        }
        
        interfaceTable.insertRowsAtIndexes(indexSet, withRowType: Storyboard.RowTypes.list)

        configureRowControllerAtIndex(index)
    }
    
    func listsController(listsController: ListsController, didRemoveListInfo listInfo: ListInfo, atIndex index: Int) {
        let indexSet = NSIndexSet(index: index)
        
        // The lists controller is now empty. Add the "no lists" row.
        if index == 0 && listsController.count == 0 {
            interfaceTable.insertRowsAtIndexes(indexSet, withRowType: Storyboard.RowTypes.noLists)
        }
        
        interfaceTable.removeRowsAtIndexes(indexSet)
    }
    
    func listsController(listsController: ListsController, didUpdateListInfo listInfo: ListInfo, atIndex index: Int) {
        configureRowControllerAtIndex(index)
    }

    // MARK: Segues
    
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        if segueIdentifier == Storyboard.Segues.listSelection {
            let listInfo = listsController[rowIndex]

            return listInfo
        }
        
        return nil
    }
    
    // MARK: Convenience
    
    func configureRowControllerAtIndex(index: Int) {
        let ListRowController = interfaceTable.rowControllerAtIndex(index) as ColoredTextRowController
        
        let listInfo = listsController[index]
        
        ListRowController.setText(listInfo.name)
        
        listInfo.fetchInfoWithCompletionHandler() {
            /*
                The fetchInfoWithCompletionHandler(_:) method calls its completion handler on a background
                queue, dispatch back to the main queue to make UI updates.
            */
            dispatch_async(dispatch_get_main_queue()) {
                let ListRowController = self.interfaceTable.rowControllerAtIndex(index) as ColoredTextRowController

                ListRowController.setColor(listInfo.color!.colorValue)
            }
        }
    }
    
    // MARK: Interface Life Cycle

    override func willActivate() {
        // If the `ListsController` is activating, we should invalidate any pending user activities.
        invalidateUserActivity()
        
        listsController.delegate = self

        listsController.startSearching()
    }

    override func didDeactivate() {
        listsController.stopSearching()
        
        listsController.delegate = nil
    }
    
    override func handleUserActivity(userInfo: [NSObject: AnyObject]?) {
        /*
            The Lister watch app only supports continuing activities where
            `AppConfiguration.UserActivity.listURLPathUserInfoKey` is provided.
        */
        let listInfoFilePath = userInfo?[AppConfiguration.UserActivity.listURLPathUserInfoKey] as? String
        
        // If no `listInfoFilePath` is found, there is no activity of interest to handle.
        if listInfoFilePath == nil {
            return
        }
        
        if let listInfoURL = NSURL(fileURLWithPath: listInfoFilePath!, isDirectory: false) {
            // Create a `ListInfo` that represents the list at `listInfoURL`.
            let listInfo = ListInfo(URL: listInfoURL)
            
            // Present a `ListInterfaceController`.
            pushControllerWithName(ListInterfaceController.Storyboard.interfaceControllerName, context: listInfo)
        }
    }
}

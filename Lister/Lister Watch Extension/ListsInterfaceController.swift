/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ListInterfaceController` that presents a single list managed by a `ListPresenterType` instance.
*/

import WatchKit
import ListerWatchKit

class ListsInterfaceController: WKInterfaceController, ConnectivityListsControllerDelegate {
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
    
    let listsController = ConnectivityListsController()

    // MARK: Initializers
    
    override init() {
        super.init()

        let noListsIndexSet = NSIndexSet(index: 0)
        interfaceTable.insertRowsAtIndexes(noListsIndexSet, withRowType: Storyboard.RowTypes.noLists)
    }
    
    // MARK: ConnectivityListsControllerDelegate

    func listsController(listsController: ConnectivityListsController, didInsertListInfo listInfo: ListInfo, atIndex index: Int) {
        let indexSet = NSIndexSet(index: index)
        
        // The lists controller was previously empty. Remove the "no lists" row.
        if index == 0 && listsController.count == 1 {
            interfaceTable.removeRowsAtIndexes(indexSet)
        }
        
        interfaceTable.insertRowsAtIndexes(indexSet, withRowType: Storyboard.RowTypes.list)

        configureRowControllerAtIndex(index)
    }
    
    func listsController(listsController: ConnectivityListsController, didRemoveListInfo listInfo: ListInfo, atIndex index: Int) {
        let indexSet = NSIndexSet(index: index)
        
        // The lists controller is now empty. Add the "no lists" row.
        if index == 0 && listsController.count == 0 {
            interfaceTable.insertRowsAtIndexes(indexSet, withRowType: Storyboard.RowTypes.noLists)
        }
        
        interfaceTable.removeRowsAtIndexes(indexSet)
    }
    
    func listsController(listsController: ConnectivityListsController, didUpdateListInfo listInfo: ListInfo, atIndex index: Int) {
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
        let listRowController = interfaceTable.rowControllerAtIndex(index) as! ColoredTextRowController
        
        let listInfo = listsController[index]
        
        listRowController.setColor(listInfo.color.colorValue)
        listRowController.setText(listInfo.name)
    }
    
    // MARK: Interface Life Cycle

    override func willActivate() {
        let extensionDelegate = WKExtension.sharedExtension().delegate as? ExtensionDelegate
        
        extensionDelegate?.mainInterfaceController = self
        
        // If the `ListsController` is activating, we should invalidate any pending user activities.
        invalidateUserActivity()
        
        listsController.delegate = self

        listsController.startSearching()
    }

    override func didDeactivate() {
        listsController.stopSearching()
    }
    
    override func handleUserActivity(userInfo: [NSObject: AnyObject]?) {
        //The Lister watch app only supports continuing activities where `AppConfiguration.UserActivity.listURLPathUserInfoKey` is provided.
        guard let listInfoFilePath = userInfo?[AppConfiguration.UserActivity.listURLPathUserInfoKey] as? String,
              let rawColor = userInfo?[AppConfiguration.UserActivity.listColorUserInfoKey] as? Int,
              let color = List.Color(rawValue: rawColor) else { return }
        
        // Create a `ListInfo` that represents the list at `listInfoURL`.
        let lastPathComponent = (listInfoFilePath as NSString).lastPathComponent
        let name = (lastPathComponent as NSString).stringByDeletingPathExtension
        let listInfo = ListInfo(name: name, color: color)
        
        // Present a `ListInterfaceController`.
        pushControllerWithName(ListInterfaceController.Storyboard.interfaceControllerName, context: listInfo)
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ControlsViewController` lists services in the selected home.
*/

import UIKit
import HomeKit

/// A view controller which displays a list of `HMServices`, separated by Service Type.
class ControlsViewController: HMCatalogViewController, HMAccessoryDelegate {
    // MARK: Types
    
    struct Identifiers {
        static let showServiceSegue = "Show Service"
    }
    
    // MARK: Properties
    
    var tableViewDataSource: ControlsTableViewDataSource!
    var cellController = AccessoryUpdateController()
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    // MARK: View Methods
    
    /// Sends the selected service into the destination view controller.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == Identifiers.showServiceSegue {
            if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
                let characteristicsViewController = segue.intendedDestinationViewController as! CharacteristicsViewController

                if let selectedService = tableViewDataSource.serviceForIndexPath(indexPath) {
                    characteristicsViewController.service = selectedService
                }
                
                characteristicsViewController.cellDelegate = cellController
            }
        }
    }
    
    /// Initializes the table view data source.
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewDataSource = ControlsTableViewDataSource(tableView: tableView)
    }
    
    /// Reloads the view.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = home.name
        reloadData()
    }
    
    // MARK: Helper Methods
    
    private func reloadData() {
        tableViewDataSource.reloadTable()
        let sections = tableViewDataSource.numberOfSectionsInTableView(tableView)

        if sections == 0 {
            setBackgroundMessage(tableViewDataSource.emptyMessage())
        }
        else {
            setBackgroundMessage(nil)
        }
    }
    
    // MARK: Delegate Registration
    
    /// Registers as the delegate for the current home and all accessories in the home.
    override func registerAsDelegate() {
        super.registerAsDelegate()
        for accessory in home.accessories {
            accessory.delegate = self
        }
    }
    
    /*
        Any delegate methods which could change data will reload the
        table view data source.
    */
    
    // MARK: HMHomeDelegate Methods
    
    func home(home: HMHome, didAddAccessory accessory: HMAccessory)  {
        accessory.delegate = self
        reloadData()
    }
    
    func home(home: HMHome, didRemoveAccessory accessory: HMAccessory)  {
        reloadData()
    }

    // MARK: HMAccessoryDelegate Methods
    
    func accessoryDidUpdateReachability(accessory: HMAccessory) {
        reloadData()
    }
    
    func accessory(accessory: HMAccessory, didUpdateNameForService service: HMService)  {
        reloadData()
    }
    
    func accessory(accessory: HMAccessory, didUpdateAssociatedServiceTypeForService service: HMService)  {
        reloadData()
    }
    
    func accessoryDidUpdateServices(accessory: HMAccessory) {
        reloadData()
    }
    
    func accessoryDidUpdateName(accessory: HMAccessory) {
        reloadData()
    }
}
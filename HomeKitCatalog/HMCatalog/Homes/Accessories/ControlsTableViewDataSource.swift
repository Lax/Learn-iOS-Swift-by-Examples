/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `ControlsTableViewDataSource` provides data for the `ControlsViewController`.
*/

import UIKit
import HomeKit

/// A `UITableViewDataSource` that populates the table in `ControlsViewController`.
class ControlsTableViewDataSource: NSObject, UITableViewDataSource {
    // MARK: Types
    
    struct Identifiers {
        static let serviceCell = "ServiceCell"
        static let unreachableServiceCell = "UnreachableServiceCell"
    }
    
    // MARK: Properties
    
    var serviceTable: [String: [HMService]]?
    var sortedKeys: [String]?
    
    let tableView: UITableView
    var home: HMHome? {
        return HomeStore.sharedStore.home
    }
    
    /// Initializes the table view and data source.
    required init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        self.tableView.dataSource = self
    }
    
    /**
        Reloads the table, sets the table's dataSource to self,
        regenerated the service table, creates a sorted list of keys,
        sets the home's delegate, and reloads the table.
    */
    func reloadTable() {
        if let home = home {
            serviceTable = home.serviceTable
            sortedKeys = serviceTable!.keys.sort()
            tableView.reloadData()
        }
        else {
            serviceTable = nil
            sortedKeys = nil
        }

        tableView.reloadData()
    }
    
    /// - returns:  The localized description of the service type for that section.
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedKeys?[section]
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sortedKeys?.count ?? 0
    }
    
    /**
        - returns:  A message that corresponds to the current most important reason
                    that there are no services in the table. Either "No Accessories"
                    or "No Services".
    */
    func emptyMessage() -> String {
        if home?.accessories.count == 0 {
            return NSLocalizedString("No Accessories", comment: "No Accessories")
        }
        else {
            return NSLocalizedString("No Services", comment: "No Services")
        }
    }
    
    /// - returns:  The number of services matching the service type in that section.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serviceTable![sortedKeys![section]]!.count
    }
    
    /// - returns: A `ServiceCell` set for the service at the provided index path.
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let service = serviceForIndexPath(indexPath)!

        let reuseIdentifier = service.accessory!.reachable ? Identifiers.serviceCell : Identifiers.unreachableServiceCell
        
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ServiceCell
        
        cell.service = service
        
        return cell
    }
    
    /// - returns:  The service represented at the index path in the table.
    func serviceForIndexPath(indexPath: NSIndexPath) -> HMService? {
        if let sortedKeys = sortedKeys,
               serviceTable = serviceTable,
                services = serviceTable[sortedKeys[indexPath.section]] {
            return services[indexPath.row]
        }

        return nil
    }
    
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HomeListViewController` is a superclass that lists the user's homes.
*/

import UIKit
import HomeKit


/// A generic view controller for displaying a list of homes in a home manager.
class HomeListViewController: HMCatalogViewController, HMHomeManagerDelegate {
    // MARK: Types
    
    struct Identifiers {
        static let homeCell = "HomeCell"
        static let showHomeSegue = "Show Home"
    }
    
    // MARK: Properties
    
    var homes = [HMHome]()

    var homeManager: HMHomeManager {
        return homeStore.homeManager
    }
    
    // MARK: View Methods
    
    /// Configures the table view.
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.estimatedRowHeight = 44.0
        
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    /// Resets the list of homes (which will update the view).
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        resetHomesList()
    }
    
    // MARK: Delegate Registration
    
    /**
        Registers as the delegate for the home manager and all homes in the internal
        homes list.
    */
    override func registerAsDelegate() {
        homeManager.delegate = self

        for home in homes {
            home.delegate = self
        }
    }
    
    /// Sets the home store's current home based on which cell was selected.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if segue.identifier == Identifiers.showHomeSegue {
            if sender === self {
                // Don't update the selected home if we sent ourselves here.
                return
            }

            if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
                homeStore.home = homes[indexPath.row]
            }
        }
    }
    
    // MARK: Table View Methods
    
    /**
        Provides the number of sections based on the home array count.
        Updates the background message for the table view.
        
        - returns:  The number of homes in the internal array.
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = homes.count

        if rows == 0 {
            let message = NSLocalizedString("No Homes", comment: "No Homes")
            setBackgroundMessage(message)
        }
        else {
            setBackgroundMessage(nil)
        }
        
        return rows
    }
    
    /**
        Generates a basic cell for a home.
        Subtext is provided to tell the user if the home is shared or owned by the user.
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.homeCell, forIndexPath: indexPath)
        let home = homes[indexPath.row]
        
        cell.textLabel?.text = home.name
        cell.detailTextLabel?.text = sharedTextForHome(home)
        
        return cell
    }
    
    // MARK: Helper Methods
    
    /**
        Provides an ordering for homes.
        
        Homes are first ordered by their 'shared' status, then by name.
        
        - parameter home1: The first `HMHome`.
        - parameter home2: The second `HMHome`.
        
        - returns:  `true` if `home1` is ordered before `home2`; `false` otherwise.
    */
    private func orderHomes(home1: HMHome, home2: HMHome) -> Bool {
        if home1.isAdmin == home2.isAdmin {
            /*
                We are comparing two shared homes or two of our homes, just compare
                names.
            */
            return home1.name.localizedCompare(home2.name) == .OrderedAscending
        }
        else {
            /*
                We are comparing a shared home and one of our homes, if home1 is
                ours, put it first.
            */
            return home1.isAdmin
        }
    }
    
    /**
        Regenerates the list of homes using list provided by the home manager.
        The list is then sorted and the view is reloaded.
    */
    private func resetHomesList() {
        homes = homeManager.homes.sort(orderHomes)
        tableView.reloadData()
    }
    
    /// Sorts the list of homes (without reloading from the home manager).
    func sortHomes() {
        homes.sortInPlace(orderHomes)
    }
    
    /**
        Adds a new home into the internal homes array and inserts the new
        row into the table view.
        
        - parameter home: The new `HMHome` that's been added.
    */
    func didAddHome(home: HMHome) {
        homes.append(home)

        sortHomes()
        
        if let newHomeIndex = homes.indexOf(home) {
            let indexPathOfNewHome = NSIndexPath(forRow: newHomeIndex, inSection: 0)
           
            tableView.insertRowsAtIndexPaths([indexPathOfNewHome], withRowAnimation: .Automatic)
        }
    }
    
    /**
        Removes a home from the internal homes array (if it exists) and
        deletes corresponding row from the table view.
        
        - parameter home: The `HMHome` to remove.
    */
    func didRemoveHome(home: HMHome) {
        guard let removedHomeIndex = homes.indexOf(home) else { return }
        
        homes.removeAtIndex(removedHomeIndex)
        let indexPath = NSIndexPath(forRow: removedHomeIndex, inSection: 0)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    /**
        - returns:  A localized description of who owns the provided home.
        
        - parameter home: The `HMHome` to describe.
    */
    func sharedTextForHome(home: HMHome) -> String {
        if !home.isAdmin {
            return NSLocalizedString("Shared with Me", comment: "Shared with Me")
        }
        else {
            return NSLocalizedString("My Home", comment: "My Home")
        }
    }
    
    // MARK: HMHomeDelegate Methods
    
    /// Finds the cell with corresponds to the provided home and reloads it.
    func homeDidUpdateName(home: HMHome) {
        if let homeIndex = homes.indexOf(home) {
            let indexPath = NSIndexPath(forRow: homeIndex, inSection: 0)
          
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    // MARK: HMHomeManagerDelegate Methods
    
    /**
        Reloads data and view.
        
        This view controller, in most cases, will remain the home manager delegate.
        For this reason, this method will close all modal views and pop all detail views
        if the home store's current home is no longer in the home manager's list of homes.
    */
    func homeManagerDidUpdateHomes(manager: HMHomeManager) {
        registerAsDelegate()
        resetHomesList()
        
        if let home = homeStore.home where !manager.homes.contains(home) {
            // Close all modal and detail views.
            dismissViewControllerAnimated(true, completion: nil)
            navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    /// Registers for the delegate of the new home and updates the view.
    func homeManager(manager: HMHomeManager, didAddHome home: HMHome) {
        home.delegate = self

        didAddHome(home)
    }
    
    /**
        Removes the home from the current list of homes and updates the view.
        
        If the removed home was the current home, this view controller will dismiss
        all modals views and pop all detail views.
    */
    func homeManager(manager: HMHomeManager, didRemoveHome home: HMHome) {
        didRemoveHome(home)
        
        guard let selectedHome = homeStore.home where home == selectedHome else { return }

        homeStore.home = nil
        
        // Close all modal and detail views.
        dismissViewControllerAnimated(true, completion: nil)
        navigationController?.popToRootViewControllerAnimated(true)
    }
}

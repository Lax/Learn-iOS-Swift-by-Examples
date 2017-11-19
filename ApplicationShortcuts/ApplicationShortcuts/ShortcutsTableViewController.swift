/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The primary view controller listing the mutable shortcuts registered for this sample.
*/

import UIKit

class ShortcutsTableViewController: UITableViewController {
    // MARK: - Properties
    
    /// Pre-defined shortcuts; retrieved from the Info.plist, lazily.
    lazy var staticShortcuts: [UIApplicationShortcutItem] = {
        // Obtain the `UIApplicationShortcutItems` array from the Info.plist. If unavailable, there are no static shortcuts.
        guard let shortcuts = NSBundle.mainBundle().infoDictionary?["UIApplicationShortcutItems"] as? [[String: NSObject]] else { return [] }
        
        // Use `flatMap(_:)` to process each dictionary into a `UIApplicationShortcutItem`, if possible.
        let shortcutItems = shortcuts.flatMap { shortcut -> [UIApplicationShortcutItem] in
            // The `UIApplicationShortcutItemType` and `UIApplicationShortcutItemTitle` keys are required to successfully create a `UIApplicationShortcutItem`.            
            guard let shortcutType = shortcut["UIApplicationShortcutItemType"] as? String,
                let shortcutTitle = shortcut["UIApplicationShortcutItemTitle"] as? String else { return [] }

            // Get the localized title.
            var localizedShortcutTitle = shortcutTitle
            if let localizedTitle = NSBundle.mainBundle().localizedInfoDictionary?[shortcutTitle] as? String {
                localizedShortcutTitle = localizedTitle
            }

            /*
                The `UIApplicationShortcutItemSubtitle` key is optional. If it
                exists, get the localized version.
            */
            var localizedShortcutSubtitle: String?
            if let shortcutSubtitle = shortcut["UIApplicationShortcutItemSubtitle"] as? String {
                localizedShortcutSubtitle = NSBundle.mainBundle().localizedInfoDictionary?[shortcutSubtitle] as? String
            }

            return [
                UIApplicationShortcutItem(type: shortcutType, localizedTitle: localizedShortcutTitle, localizedSubtitle: localizedShortcutSubtitle, icon: nil, userInfo: nil)
            ]
        }
        
        return shortcutItems
    }()
    
    /// Shortcuts defined by the application and modifiable based on application state.
    lazy var dynamicShortcuts = UIApplication.sharedApplication().shortcutItems ?? []
    
    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Static", "Dynamic"][section]
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? staticShortcuts.count : dynamicShortcuts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CellID", forIndexPath: indexPath)
        
        let shortcut: UIApplicationShortcutItem

        if indexPath.section == 0 {
            // Static shortcuts (cannot be edited).
            shortcut = staticShortcuts[indexPath.row]
            cell.accessoryType = .None
            cell.selectionStyle = .None
        }
        else {
            // Dynamic shortcuts.
            shortcut = dynamicShortcuts[indexPath.row]
        }
        
        cell.textLabel?.text = shortcut.localizedTitle
        cell.detailTextLabel?.text = shortcut.localizedSubtitle
        
        return cell
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Supply the `shortcutItem` matching the selected row from the data source.
        if segue.identifier == "ShowShortcutDetail" {
            guard let indexPath = tableView.indexPathForSelectedRow,
                  let controller = segue.destinationViewController as? ShortcutDetailViewController else { return }

            controller.shortcutItem = dynamicShortcuts[indexPath.row]
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // Block navigating to detail view controller for static shortcuts (which are not editable).
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return false }
        
        return selectedIndexPath.section > 0
    }
    
    // MARK: - Actions
    
    // Unwind segue action called when the user taps 'Done' after navigating to the detail controller.
    @IBAction func done(sender: UIStoryboardSegue) {
        // Obtain the edited shortcut from our source view controller.
        guard let sourceViewController = sender.sourceViewController as? ShortcutDetailViewController,
              let selected = tableView.indexPathForSelectedRow,
              let updatedShortcutItem = sourceViewController.shortcutItem else { return }
        
        // Update our data source.
        dynamicShortcuts[selected.row] = updatedShortcutItem
        
        // Update the application's `shortcutItems`.
        UIApplication.sharedApplication().shortcutItems = dynamicShortcuts
        
        tableView.reloadRowsAtIndexPaths([selected], withRowAnimation: .Automatic)
    }
    
    // Unwind segue action called when the user taps 'Cancel' after navigating to the detail controller.
    @IBAction func cancel(sender: UIStoryboardSegue) {}
}

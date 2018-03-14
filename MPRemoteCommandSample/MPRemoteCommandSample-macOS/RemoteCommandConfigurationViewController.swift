/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`RemoteCommandConfigurationViewController` is an `NSViewController` subclass that lists all the supported `MPRemoteCommand`s that are available to enable/disable.
 */

import Cocoa

class RemoteCommandConfigurationViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, RemoteCommandViewDelegate {
    
    // MARK: Types
    
    /// The reuse identifier to use for retrieving a view that represents a section header.
    static let sectionCellViewIdentifier = "SectionCellViewIdentifier"

    // MARK: Properties
    
    @IBOutlet weak var tableView: NSTableView!
    
    /// The instance of `RemoteCommandDataSource` to use for responding to `NSTableViewDataSource` delegate callbacks.
    var remoteCommandDataSource: RemoteCommandDataSource! {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: NSTableViewDataSource Protocol Methods
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard remoteCommandDataSource != nil else {
            return 0
        }
        
        let sectionNumber = remoteCommandDataSource.numberOfRemoteCommandSections()
        var numberOfRows = sectionNumber
        
        for i in 0..<sectionNumber {
            numberOfRows += remoteCommandDataSource.numberOfItemsInSection(i)
        }
        
        return numberOfRows
    }
    
    // MARK: NSTableViewDelegate Protocol Methods
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row == 0 || row == 3 || row == 6 {
            guard let tableCellView = tableView.make(withIdentifier: RemoteCommandConfigurationViewController.sectionCellViewIdentifier, owner: self) as? NSTableCellView else { return nil }
            
            tableCellView.textField?.stringValue = remoteCommandDataSource.titleForSection(sectionNumberForRow(row: row))
            
            return tableCellView
        }
        else {
            let sectionNumber = sectionNumberForRow(row: row)
            let rowRelativeToSection = rowRelativeToSectionForRow(row: row)
            
            guard let remoteCommandView = tableView.make(withIdentifier: RemoteCommandView.reuseIdentifier, owner: self) as? RemoteCommandView else { return nil }
            
            remoteCommandView.button.title = remoteCommandDataSource.titleStringForCommand(at: sectionNumber, row: rowRelativeToSection)
            remoteCommandView.delegate = self
            
            return remoteCommandView
        }
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if row == 0 || row == 3 || row == 6 {
            return true
        }
        
        return false
    }
    
    // MARK: RemoteCommandViewDelegate Protocol Method
    
    func remoteCommandView(_ cell: RemoteCommandView, didToggleTo enabled: Bool) {
        let tableViewRow = tableView.row(for: cell)
        let section = sectionNumberForRow(row: tableViewRow)
        let row = rowRelativeToSectionForRow(row: tableViewRow)
        
        remoteCommandDataSource.toggleCommandHandler(with: section, row: row, enable: enabled)
    }
    
    // MARK: Utility Methods
    
    /// This method takes a `NSTableView` based row and returns what the expected `UITableView` section number would be for use with the Data Source Like methods of `RemoteCommandManager`.
    private func sectionNumberForRow(row: Int) -> Int {
        if row >= 6 {
            return 2
        }
        else if row >= 3 {
            return 1
        }
        else {
            return 0
        }
    }
    
    /// This method takes a `NSTableView` based row and returns what the expected `UITableView` row number would be relative to its section for use with the Data Source Like methods of `RemoteCommandManager`.
    private func rowRelativeToSectionForRow(row: Int) -> Int {
        let section = sectionNumberForRow(row: row)
        var delta = row
        
        for i in 0..<section {
            delta -= remoteCommandDataSource.numberOfItemsInSection(i)
        }
        
        return delta - (section + 1)
    }
}

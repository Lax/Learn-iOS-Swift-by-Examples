/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating an accessible search field.
*/

import Cocoa

class CustomSearchFieldViewController: NSViewController, SharedFocusSearchFieldDelegate {

    @IBOutlet var searchField: CustomSearchField!
    
    var completing = false
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the search field's accessibility delegate to access the search results.
        searchField.sharedFocusDelegate = self

        let searchMenu = NSMenu(title: NSLocalizedString("Search Menu", comment: "title of the search menu"))
     
        searchMenu.autoenablesItems = true
        
        let recentsTitleItem =
            NSMenuItem(title: NSLocalizedString("Recent Searches",
                                                comment: "title of the recent searches"), action: nil, keyEquivalent: "")
        recentsTitleItem.tag = Int(NSSearchField.recentsTitleMenuItemTag)
        searchMenu.insertItem(recentsTitleItem, at: 0)
        
        let norecentsTitleItem =
            NSMenuItem(title: NSLocalizedString("No Recent Searches",
                                                comment: "title of the recent searches"), action: nil, keyEquivalent: "")
        norecentsTitleItem.tag = Int(NSSearchField.noRecentsMenuItemTag)
        searchMenu.insertItem(norecentsTitleItem, at: 1)
        
        let recentsItem =
            NSMenuItem(title: NSLocalizedString("Recents",
                                                comment: "title of the recent searches menu button"), action: nil, keyEquivalent: "")
        recentsItem.tag = Int(NSSearchField.recentsMenuItemTag)
        searchMenu.insertItem(recentsItem, at: 2)
        
        let separatorItem = NSMenuItem.separator()
        separatorItem.tag = Int(NSSearchField.recentsTitleMenuItemTag)
        searchMenu.insertItem(separatorItem, at: 3)

        let clearItem =
            NSMenuItem(title: NSLocalizedString("Clear",
                                                comment: "title of the clear menu button"), action: nil, keyEquivalent: "")
        clearItem.tag = Int(NSSearchField.clearRecentsMenuItemTag)
        searchMenu.insertItem(clearItem, at: 4)

        if let searchFieldCell = searchField.cell as? NSSearchFieldCell {
            searchFieldCell.maximumRecents = 20
            searchFieldCell.searchMenuTemplate = searchMenu
        }
    }
    
    // MARK: - Keyword Search
    
    override func controlTextDidChange(_ obj: Notification) {
        if let textView = obj.userInfo?["NSFieldEditor"] as? NSTextView {
            // Prevent calling "complete" too often.
            if !completing {
                completing = true
                textView.complete(nil)
                completing = false
            }
        }
    }
    
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        completing = true
        
        if commandSelector == #selector(moveLeft) {
            textView.moveLeft(nil)
        } else if commandSelector == #selector(moveRight) {
            textView.moveRight(nil)
        } else if commandSelector == #selector(moveToLeftEndOfLine) {
            textView.moveToLeftEndOfLine(nil)
        } else if commandSelector == #selector(moveToRightEndOfLine) {
            textView.moveToRightEndOfLine(nil)
        } else if commandSelector == #selector(moveLeftAndModifySelection) {
            textView.moveLeftAndModifySelection(nil)
        } else if commandSelector == #selector(moveRightAndModifySelection) {
            textView.moveRightAndModifySelection(nil)
        } else if commandSelector == #selector(moveToLeftEndOfLineAndModifySelection) {
            textView.moveToLeftEndOfLineAndModifySelection(nil)
        } else if commandSelector == #selector(deleteBackward) {
            textView.deleteBackward(nil)
        } else if commandSelector == #selector(deleteForward) {
            textView.deleteForward(nil)
        } else if commandSelector == #selector(insertNewline) {
            textView.insertNewline(nil)
        }
        
        completing = false

        return true
    }
    
    // MARK: - SharedFocusSearchFieldDelegate
    
    func accessibilitySharedFocusElementsForSearchFieldCell() -> [Any] {
        var sharedFocusElements = [Any]()
        
        // Return the NSTableView element that has the list of search results.
        let completionsWindow = NSApp.windows.last
        if (completionsWindow?.isVisible)! {
            var child = completionsWindow as Any
            while !(child is NSTableView) {
                child = (child as AnyObject).accessibilityChildren()?.first! as Any
            }
            if child is NSTableView {
                sharedFocusElements = [child]
            }
        }

        return sharedFocusElements
    }

}


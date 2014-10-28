/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `ListViewController` class displays the contents of a list document.
            
*/

import Cocoa
import NotificationCenter
import ListerKitOSX

class ListViewController: NSViewController, ColorPaletteViewDelegate, ListItemViewDelegate, ListDocumentDelegate, AddItemViewControllerDelegate {
    // MARK: Types
    
    // String constants scope to ListViewController.
    struct TableViewConstants {
        struct ViewIdentifiers {
            static let listItemViewIdentifier = "ListItemViewIdentifier"
            static let noListItemViewIdentifier = "NoListItemViewIdentifier"
        }
        
        static let pasteboardType = "public.item.lister"
        static let dragType = "listerDragType"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var colorPaletteView: ColorPaletteView!
    
    weak var document: ListDocument! {
        didSet {
            if document == nil { return }

            document.delegate = self

            reloadListUI()
        }
    }

    var list: List! {
        return document?.list
    }
    
    override var undoManager: NSUndoManager! {
        return document.undoManager
    }
    
    // MARK: View Life Cycle
    
    override func viewDidAppear() {
        super.viewDidAppear()

        // Enable dragging for the list items of our specific type.
        tableView.registerForDraggedTypes([TableViewConstants.dragType, NSPasteboardTypeString])
        tableView.setDraggingSourceOperationMask(.Move, forLocal: true)
    }

    // MARK: NSTableViewDelegate

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if list == nil { return 0 }

        return list.isEmpty ? 1 : list.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn, row: Int) -> NSView {
        if list.isEmpty {
            return tableView.makeViewWithIdentifier(TableViewConstants.ViewIdentifiers.noListItemViewIdentifier, owner: nil) as NSView
        }
        
        var listItemView = tableView.makeViewWithIdentifier(TableViewConstants.ViewIdentifiers.listItemViewIdentifier, owner: nil) as ListItemView
        
        let item = list[row]
        
        listItemView.isComplete = item.isComplete
        
        listItemView.tintColor = list.color.colorValue
        
        listItemView.stringValue = item.text
        
        listItemView.delegate = self
        
        return listItemView
    }
    
    // Only allow rows to be selectable if there are items in the list.
    func tableView(tableView: NSTableView, shouldSelectRow: Int) -> Bool {
        return !list.isEmpty
    }
    
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        // Don't allow moving/copying the empty list item.
        let pasteboard = info.draggingPasteboard()
        
        var result = NSDragOperation.None
        
        // Only allow drops above.
        if dropOperation == .Above {
            // If drag source is self, it's a move.
            if info.draggingSource() === tableView {
                if let listItems = listItemsWithListerPasteboardType(pasteboard) {
                    
                    // Only allow a move if there's a single item being moved, and the list allows it.
                    if listItems.count == 1 && list.canMoveItem(listItems.first!, toIndex: row, inclusive: true) {
                        result = .Move
                    }
                }
            }
            else {
                // Test pasteboard to make sure it contains something that can be copied.
                // If it does, copy it.
                if let listItems = listItemsWithStringPasteboardType(pasteboard) {
                    if list.canInsertIncompleteItems(listItems, atIndex: row) {
                        result = .Copy
                    }
                }
            }
        }
        
        return result
    }
    
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard()
        
        if info.draggingSource() === tableView {
            let listItems = listItemsWithListerPasteboardType(pasteboard)

            assert(listItems!.count == 1, "There must be exactly one moved item.")

            moveItem(listItems!.first!, toIndex: row)
        }
        else {
            let listItems = listItemsWithStringPasteboardType(pasteboard)
            
            assert(listItems != nil, "'items' must not be nil")

            let range = NSRange(location: row, length: listItems!.count)
            let indexes = NSIndexSet(indexesInRange: range)

            insertItems(listItems!, withPreferredIndexes: indexes)
        }
        
        return true
    }
    
    func tableView(tableView: NSTableView, writeRowsWithIndexes indexes: NSIndexSet, toPasteboard pasteboard: NSPasteboard) -> Bool {
        if list.isEmpty {
            return false
        }
        
        let items = list[indexes: indexes]

        writeItems(items, toPasteboard: pasteboard)
        
        return true
    }
    
    // MARK: NSPasteboard Convenience
    
    func listItemsWithListerPasteboardType(pasteboard: NSPasteboard, refreshesItemIdentities: Bool = false) -> [ListItem]? {
        if pasteboard.canReadItemWithDataConformingToTypes([TableViewConstants.pasteboardType]) {
            for pasteboardItem in pasteboard.pasteboardItems as [NSPasteboardItem] {

                if let itemsData = pasteboardItem.dataForType(TableViewConstants.pasteboardType) {
                    var allItems = [ListItem]()

                    let pasteboardListItems = NSKeyedUnarchiver.unarchiveObjectWithData(itemsData) as [ListItem]
                    
                    for item in pasteboardListItems {
                        if refreshesItemIdentities {
                            item.refreshIdentity()
                        }
                        
                        allItems += [item]
                    }
                    
                    return allItems
                }

            }
        }
        
        return nil
    }
    
    func listItemsWithStringPasteboardType(pasteboard: NSPasteboard) -> [ListItem]? {
        if pasteboard.canReadItemWithDataConformingToTypes([NSPasteboardTypeString]) {
            var allItems = [ListItem]()

            for pasteboardItem in pasteboard.pasteboardItems as [NSPasteboardItem] {
                if let targetType = pasteboardItem.availableTypeFromArray([NSPasteboardTypeString]) {
                    if let pasteboardString = pasteboardItem.stringForType(targetType) {
                        allItems += ListFormatting.listItemsFromString(pasteboardString)
                    }
                }
            }
            
            return allItems
        }
        
        return nil
    }
    
    func writeItems(items: [ListItem], toPasteboard pasteboard: NSPasteboard) {
        pasteboard.declareTypes([TableViewConstants.dragType, NSPasteboardTypeString], owner: self)

        // Save `items` as data.
        let data = NSKeyedArchiver.archivedDataWithRootObject(items)
        pasteboard.setData(data, forType: TableViewConstants.pasteboardType)

        // Save `items` as a string.
        let itemsString = ListFormatting.stringFromListItems(items)
        pasteboard.setString(itemsString, forType: NSPasteboardTypeString)
    }
    
    // MARK: Item Rearrangement

    func moveItem(item: ListItem, toIndex: Int) {
        let indexes = list.moveItem(item, toIndex: toIndex)
        
        tableView.moveRowAtIndex(indexes.fromIndex, toIndex: indexes.toIndex)

        undoManager.prepareWithInvocationTarget(self).undoMoveItem(item, toPriorIndex: indexes.fromIndex)
        
        updateWidget()
    }
    
    /// This method is used for undo purposes to undo a moveItem(_:toIndex:) call.
    /// If an item is moved from the top to bottom, then the reverse target index must be normalized.
    func undoMoveItem(item: ListItem, toPriorIndex priorIndex: Int) {
        let currentItemIndex = list.indexOfItem(item)
        
        var normalizedItemIndex = priorIndex
        if currentItemIndex < priorIndex {
            normalizedItemIndex++
        }
        
        moveItem(item, toIndex: normalizedItemIndex)
    }
    
    func deleteRowsAtIndexes(indexes: NSIndexSet) {
        // Ignore empty index sets.
        if indexes.count <= 0 {
            return
        }
        
        let items = list[indexes: indexes]
        
        list.removeItems(items)
        
        tableView.beginUpdates()
        
        tableView.removeRowsAtIndexes(indexes, withAnimation: .SlideUp)
        
        if list.isEmpty {
            // Show the empty row.
            let indexSet = NSIndexSet(index: 0)
            tableView.insertRowsAtIndexes(indexSet, withAnimation: .SlideDown)
        }
        
        tableView.endUpdates()
        
        undoManager.prepareWithInvocationTarget(self).insertItems(items, withPreferredIndexes: indexes)
        
        updateWidget()
    }
    
    func insertItems(items: [ListItem], withPreferredIndexes preferredIndexes: NSIndexSet? = nil) {
        // Ignore the insertion if `items` is empty.
        if items.isEmpty {
            return
        }
        
        let listEmptyBeforeInsert = list.isEmpty
        
        var insertedIndexes: NSIndexSet
        
        if let indexes = preferredIndexes {
            var itemsIndex = 0
            indexes.enumerateIndexesUsingBlock { (idx, _) in
                let item = items[itemsIndex]
                
                self.list.insertItem(item, atIndex: idx)
                
                itemsIndex++
            }
            
            insertedIndexes = indexes
        }
        else {
            insertedIndexes = list.insertItems(items)
        }
        
        tableView.beginUpdates()
        
        if listEmptyBeforeInsert {
            let indexSet = NSIndexSet(index: 0)
            tableView.removeRowsAtIndexes(indexSet, withAnimation: .SlideUp)
        }
        tableView.insertRowsAtIndexes(insertedIndexes, withAnimation: .SlideDown)
        tableView.endUpdates()
        
        undoManager.prepareWithInvocationTarget(self).deleteRowsAtIndexes(insertedIndexes)
        
        updateWidget()
    }
    
    /// Toggle the completion state of an item, and move it's associated row.
    func toggleItem(item: ListItem, withPreferredDestinationIndex preferredDestinationIndex: Int? = nil) {
        tableView.beginUpdates()
        
        let itemIndex = list.indexOfItem(item)

        let listItemView = tableView.viewAtColumn(0, row: itemIndex!, makeIfNecessary: true) as ListItemView
        
        let (fromIndex, toIndex) = list.toggleItem(item, preferredTargetIndex: preferredDestinationIndex)
        
        tableView.moveRowAtIndex(fromIndex, toIndex: toIndex)
        
        listItemView.isComplete = item.isComplete
        
        tableView.endUpdates()
        
        undoManager.prepareWithInvocationTarget(self).toggleItem(item, withPreferredDestinationIndexForUndo: fromIndex)
        
        updateWidget()
    }

    /// To use NSUndoManager, only types representable in ObjC can be used as parameters.
    @objc func toggleItem(item: ListItem, withPreferredDestinationIndexForUndo preferredDestinationIndex: Int) {
        toggleItem(item, withPreferredDestinationIndex: preferredDestinationIndex == NSNotFound ? nil : preferredDestinationIndex)
    }
    
    func resetToList(aList: List) {
        undoManager.prepareWithInvocationTarget(self).resetToList(list.copy() as List)
        
        document.list = aList
        
        colorPaletteView.selectedColor = list.color
        tableView.reloadData()
        
        updateWidget()
    }

    func updateAllItemsToCompletionState(completionState: Bool) {
        undoManager.prepareWithInvocationTarget(self).resetToList(list.copy() as List)

        list.updateAllItemsToCompletionState(completionState)
        tableView.reloadData()
    }
    
    func updateItem(item: ListItem, withText text: String) {
        let oldText = item.text
        
        item.text = text
        
        let indexOfItem = list.indexOfItem(item)
        
        tableView.beginUpdates()
        let listItemView = tableView.viewAtColumn(0, row: indexOfItem!, makeIfNecessary: true) as ListItemView
        listItemView.stringValue = text
        tableView.endUpdates()

        undoManager.prepareWithInvocationTarget(self).updateItem(item, withText: oldText)
    }
    
    // MARK: Reloading Convenience

    func reloadListUI() {
        colorPaletteView.selectedColor = list.color
        
        tableView.reloadData()
    }
    
    // MARK: Cut / Copy / Paste / Delete
    
    func cut(sender: AnyObject) {
        let selectedRowIndexes = tableView.selectedRowIndexes
        
        if selectedRowIndexes.count > 0 {
            let items = list[indexes: selectedRowIndexes]
            
            writeItems(items, toPasteboard: NSPasteboard.generalPasteboard())
            
            deleteRowsAtIndexes(selectedRowIndexes)
        }
    }
    
    func copy(sender: AnyObject) {
        let selectedRowIndexes = tableView.selectedRowIndexes
        
        if selectedRowIndexes.count > 0 {
            let items = list[indexes: selectedRowIndexes]

            writeItems(items, toPasteboard: NSPasteboard.generalPasteboard())
        }
    }
    
    func paste(sender: AnyObject) {
        var listItems = listItemsWithListerPasteboardType(NSPasteboard.generalPasteboard(), refreshesItemIdentities: true)
        
        // If there were no pasted items that are of the Lister pasteboard type, see if there are any String contents on the pasteboard.
        if listItems == nil {
            listItems = listItemsWithStringPasteboardType(NSPasteboard.generalPasteboard())
        }

        // Only copy/paste if items were inserted.
        if listItems != nil && listItems!.count > 0 {
            insertItems(listItems!)
        }
    }
    
    override func keyDown(event: NSEvent) {
        // Only handle delete keyboard event.
        if event.charactersIgnoringModifiers == String(Character(UnicodeScalar(NSDeleteCharacter))) {
            deleteRowsAtIndexes(tableView.selectedRowIndexes)
        }
    }
    
    // MARK: IBActions
    
    @IBAction func completeAllItems(sender: NSButton) {
        updateAllItemsToCompletionState(true)
    }
    
    @IBAction func incompleteAllItems(sender: NSButton) {
        updateAllItemsToCompletionState(false)
    }
    
    // MARK:  ListItemViewDelegate

    func listItemViewDidToggleCompletionState(listItemView: ListItemView) {
        let row = tableView.rowForView(listItemView)

        toggleItem(list[row])
    }
    
    func listItemViewTextDidEndEditing(listItemView: ListItemView) {
        let row = tableView.rowForView(listItemView)
        
        if row == -1 {
            return
        }
        
        let cleansedString = listItemView.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        // If a list item's text is empty after editing, delete it.
        if cleansedString.isEmpty {
            let indexSetToDelete = NSIndexSet(index: row)

            deleteRowsAtIndexes(indexSetToDelete)
        }
        else {
            let item = list[row]
            
            let oldText = item.text
            
            item.text = listItemView.stringValue
            
            undoManager.prepareWithInvocationTarget(self).updateItem(item, withText: oldText)
            
            updateWidget()
        }
    }
    
    // MARK: AddItemViewControllerDelegate

    func addItemViewController(addItemViewController: AddItemViewController, didCreateNewItemWithText text: String) {
        let newItem = ListItem(text: text)
        
        insertItems([newItem])
    }
    
    // MARK: ColorPaletteViewDelegate

    func colorPaletteViewDidChangeSelectedColor(colorPaletteView: ColorPaletteView) {
        setColorPaletteViewColor(colorPaletteView.selectedColor.rawValue)
    }

    // To use NSUndoManager, only types representable in ObjC can be used as parameters.
    @objc func setColorPaletteViewColor(rawColor: Int) {
        undoManager.prepareWithInvocationTarget(self).setColorPaletteViewColor(list.color.rawValue)

        list.color = List.Color(rawValue: rawColor)!
        colorPaletteView.selectedColor = list.color

        // Update the list item views with the newly selected color.
        // Only update the ListItemView subclasses since they only have a tint color.
        tableView.beginUpdates()
        tableView.enumerateAvailableRowViewsUsingBlock { (rowView, _) in
            if let listItemView = rowView.viewAtColumn(0) as? ListItemView {
                listItemView.tintColor = self.list.color.colorValue
            }
        }
        tableView.endUpdates()
        
        updateWidget()
    }
    
    // MARK: ListDocumentDelegate
    
    func listDocumentDidChangeContents(listDocument: ListDocument) {
        reloadListUI()
    }
    
    // MARK: NCWidget Support

    func updateWidget() {
        TodayListManager.fetchTodayDocumentURLWithCompletionHandler { url in
            let currentDocumentURL = self.document.fileURL

            if url == currentDocumentURL {
                NCWidgetController.widgetController().setHasContent(true, forWidgetWithBundleIdentifier: AppConfiguration.Extensions.widgetBundleIdentifier)
            }
        }
    }
}

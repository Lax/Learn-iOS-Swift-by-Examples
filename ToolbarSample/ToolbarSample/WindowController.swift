/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The primary window controller for this sample.
 */

import Cocoa

fileprivate extension NSTouchBarCustomizationIdentifier {
    
    static let touchBar = NSTouchBarCustomizationIdentifier("com.ToolbarSample.touchBar")
}

fileprivate extension NSTouchBarItemIdentifier {
    
    static let popover = NSTouchBarItemIdentifier("com.ToolbarSample.TouchBarItem.popover")
    static let fontStyle = NSTouchBarItemIdentifier("com.ToolbarSample.TouchBarItem.fontStyle")
    static let popoverSlider = NSTouchBarItemIdentifier("com.ToolbarSample.popoverBar.slider")
}

class WindowController: NSWindowController, NSToolbarDelegate {

    let FontSizeToolbarItemID   = "FontSize"
    let FontStyleToolbarItemID  = "FontStyle"
    let DefaultFontSize : Int   = 18
    
    @IBOutlet weak var toolbar: NSToolbar!
    
    // Font style toolbar item.
    @IBOutlet var styleSegmentView: NSView!  // The font style changing view (ends up in an NSToolbarItem).

    // Font size toolbar item.
    @IBOutlet var fontSizeView: NSView!    // The font size changing view (ends up in an NSToolbarItem).
    @IBOutlet var fontSizeStepper: NSStepper!
    @IBOutlet var fontSizeField: NSTextField!
    
    var currentFontSize: Int = 0
    
    // MARK: - Window Controller Life Cycle
    
    override func windowDidLoad() {
        
        super.windowDidLoad()

        self.currentFontSize = DefaultFontSize
        
        // Configure our toolbar (note: this can also be done in Interface Builder).
        
        /*  If you pass NO here, you turn off the customization palette.  The palette is normally handled
            automatically for you by NSWindow's -runToolbarCustomizationPalette: function; you'll notice
            that the "Customize Toolbar" menu item is hooked up to that method in Interface Builder.
        */
        self.toolbar.allowsUserCustomization = true
        
        /*  Tell the toolbar that it should save any configuration changes to user defaults, i.e. mode
            changes, or reordering will persist.  Specifically they will be written in the app domain using
            the toolbar identifier as the key.
        */
        self.toolbar.autosavesConfiguration = true
        
        // Tell the toolbar to show icons only by default.
        self.toolbar.displayMode = .iconOnly
        
        // Initialize our font size control here to 18-point font, and set our view controller's NSTextView to that size.
        self.fontSizeStepper.integerValue = Int(DefaultFontSize)
        self.fontSizeField.stringValue = String(DefaultFontSize)
        let font = NSFont(name: "Helvetica", size: CGFloat(DefaultFontSize))
        self.contentTextView().font = font
        
        if #available(OSX 10.12.1, *) {
            if ((NSClassFromString("NSTouchBar")) != nil) {
                let fontSizeTouchBarItem = self.touchBar!.item(forIdentifier: .popover) as! NSPopoverTouchBarItem
                let sliderTouchBar = fontSizeTouchBarItem.popoverTouchBar
                let sliderTouchBarItem = sliderTouchBar.item(forIdentifier: .popoverSlider) as! NSSliderTouchBarItem
                let slider = sliderTouchBarItem.slider
                
                // Make the font size slider a bit narrowed, about 250 pixels.
                let views = ["slider" : slider]
                let theConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[slider(250)]", options: NSLayoutFormatOptions(), metrics: nil, views:views)
                NSLayoutConstraint.activate(theConstraints)
                
                // Set the font size for the slider item to the same value as the stepper.
                slider.integerValue = DefaultFontSize
            }
        }
    }
    
    // Convenince accessor to our NSTextView found in our content view controller.
    func contentTextView() -> NSTextView {
        return (self.contentViewController as! ViewController).textView
    }
    
    // MARK: - Font and Size setters
    
    func setTextViewFontSize(fontSize: Float) {
        
        fontSizeField.floatValue = round(fontSize)
        
        let attrs = self.contentTextView().typingAttributes
        var theFont : NSFont = attrs["NSFont"] as! NSFont
        
        theFont = NSFontManager.shared().convert(theFont, toSize: CGFloat(fontSize))
        
        if (self.contentTextView().selectedRange().length > 0) {
            // We have a selection, change the selected text
            self.contentTextView().setFont(theFont, range: self.contentTextView().selectedRange())
        }
        else {
            // No selection, so just change the font size at insertion.
            let attributesDict = [ NSFontAttributeName: theFont ]
            self.contentTextView().typingAttributes = attributesDict
        }
    }
    
    /**
     This action is called to change the font style.
     It is called through it's popup toolbar item and segmented control item.
     */
    func setTextViewFont(index: Int) {
        
        let attrs = self.contentTextView().typingAttributes
        var theFont : NSFont = attrs["NSFont"] as! NSFont
        
        // Set the font properties depending upon what was selected.
        switch (index) {
            case 0: // plain
                theFont = NSFontManager.shared().convert(theFont, toNotHaveTrait:.italicFontMask)
                theFont = NSFontManager.shared().convert(theFont, toNotHaveTrait:.boldFontMask)
                theFont = NSFontManager.shared().convert(theFont, toNotHaveTrait:.boldFontMask)
            
                // No underline attribute.
                let selectedRange = self.contentTextView().selectedRange()
                let textStorage = self.contentTextView().textStorage
                textStorage?.removeAttribute(NSForegroundColorAttributeName, range: selectedRange)
                textStorage?.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber.init(value: 0), range: selectedRange)
                
            case 1: // bold
                theFont = NSFontManager.shared().convert(theFont, toNotHaveTrait:.italicFontMask)
                theFont = NSFontManager.shared().convert(theFont, toHaveTrait:.boldFontMask)
                
            case 2: // italic
                theFont = NSFontManager.shared().convert(theFont, toNotHaveTrait:.boldFontMask)
                theFont = NSFontManager.shared().convert(theFont, toHaveTrait:.italicFontMask)
                
            default:
                print("invalid selection")
        }
        
        if (self.contentTextView().selectedRange().length > 0) {
            // We have a selection, change the selected text
            self.contentTextView().setFont(theFont, range: self.contentTextView().selectedRange())
        }
        else {
            // No selection, so just change the font style at insertion.
            let attributesDict = [ NSFontAttributeName: theFont ]
            self.contentTextView().typingAttributes = attributesDict
        }
    }
    
    // MARK: - Action Functions
    
    /**
     This action is called to change the font size.
     It is called by the NSStepper in the toolbar item's custom view and the slider item.
     */
    @IBAction func changeFontSize(_ sender: NSStepper) {
        
        self.setTextViewFontSize(fontSize: sender.floatValue)
    }
    
    /// This action is called to change the font size from the slider item found in the NSTouchBar instance.
    @IBAction func changeFontSizeBySlider(_ sender: NSSlider) {
        
        self.setTextViewFontSize(fontSize: sender.floatValue)
    }
    
    /// This action is called from the change font style toolbar item, from the segmented control in the custom view.
    @IBAction func changeFontStyleBySegment(_ sender: NSSegmentedControl) {
        
        let style = sender.selectedSegment
        self.setTextViewFont(index: style)
    }
    
    /// This is called by the appropriate toolbar item to toggle blue text on/off.
    @IBAction func blueText(_ sender: AnyObject) {

        if (self.contentTextView().selectedRange().length > 0) {
            // We have a selection, change the selected text
            let textStorage = self.contentTextView().textStorage
            textStorage?.removeAttribute(NSForegroundColorAttributeName, range: self.contentTextView().selectedRange())
            textStorage?.addAttribute(NSForegroundColorAttributeName, value: NSColor.blue, range: self.contentTextView().selectedRange())
        }
        else {
            // No selection, so just change the font size at insertion.
            var attrs = self.contentTextView().typingAttributes
            attrs["NSColor"] = NSColor.blue
            self.contentTextView().typingAttributes = attrs
        }
    }

    /**
        The NSToolbarPrintItem NSToolbarItem will send the -printDocument: message to its target.
        Since we wired its target to be ourselves in -toolbarWillAddItem:, we get called here when
        the user tries to print by clicking the toolbar item.
    */
    func printDocument(_ sender: AnyObject) {
    
        let printOperation = NSPrintOperation(view: self.contentTextView())
        printOperation.runModal(for: self.window!, delegate: nil, didRun: nil, contextInfo: nil)
    }
    
    // Called when the user chooses a font style from the segmented control inside the NSTouchBar instance.
    @IBAction func touchBarFontStyleAction(_ sender: NSSegmentedControl) {
        
        self.setTextViewFont(index: sender.selectedSegment)
    }
    
    // MARK: - NSToolbarDelegate
    
    /**
        Factory method to create NSToolbarItems.

        All NSToolbarItems have a unique identifer associated with them, used to tell your delegate/controller
        what toolbar items to initialize and return at various points.  Typically, for a given identifier,
        you need to generate a copy of your "master" toolbar item, and return.  The function
        creates an NSToolbarItem with a bunch of NSToolbarItem paramenters.

        It's easy to call this function repeatedly to generate lots of NSToolbarItems for your toolbar.
 
        The label, palettelabel, toolTip, action, and menu can all be nil, depending upon what you want
        the item to do.
    */
    func customToolbarItem(itemForItemIdentifier itemIdentifier: String, label: String, paletteLabel: String, toolTip: String, target: AnyObject, itemContent: AnyObject, action: Selector?, menu: NSMenu?) -> NSToolbarItem? {
        
        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        
        toolbarItem.label = label
        toolbarItem.paletteLabel = paletteLabel
        toolbarItem.toolTip = toolTip
        toolbarItem.target = target
        toolbarItem.action = action
        
        // Set the right attribute, depending on if we were given an image or a view.
        if (itemContent is NSImage) {
            let image: NSImage = itemContent as! NSImage
            toolbarItem.image = image
        }
        else if (itemContent is NSView) {
            let view: NSView = itemContent as! NSView
            toolbarItem.view = view
        }
        else {
            assertionFailure("Invalid itemContent: object")
        }
        
        /* If this NSToolbarItem is supposed to have a menu "form representation" associated with it
            (for text-only mode), we set it up here.  Actually, you have to hand an NSMenuItem
            (not a complete NSMenu) to the toolbar item, so we create a dummy NSMenuItem that has our real
            menu as a submenu.
        */
        // We actually need an NSMenuItem here, so we construct one.
        let menuItem: NSMenuItem = NSMenuItem()
        menuItem.submenu = menu
        menuItem.title = label
        toolbarItem.menuFormRepresentation = menuItem
        
        return toolbarItem
    }
    
    /**
        This is an optional delegate function, called when a new item is about to be added to the toolbar.
        This is a good spot to set up initial state information for toolbar items, particularly items
        that you don't directly control yourself (like with NSToolbarPrintItemIdentifier here).
        The notification's object is the toolbar, and the "item" key in the userInfo is the toolbar item
        being added.
    */
    func toolbarWillAddItem(_ notification: Notification) {
        
        let userInfo = notification.userInfo!
        let addedItem = userInfo["item"] as! NSToolbarItem
        
        let itemIdentifier = addedItem.itemIdentifier
        
        if itemIdentifier == "NSToolbarPrintItem" {
            addedItem.toolTip = "Print your document"
            addedItem.target = self
        }
    }
    
    /**
        NSToolbar delegates require this function.
        It takes an identifier, and returns the matching NSToolbarItem. It also takes a parameter telling
        whether this toolbar item is going into an actual toolbar, or whether it's going to be displayed
        in a customization palette.
    */
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: String, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        var toolbarItem: NSToolbarItem = NSToolbarItem()
        
        /* We create a new NSToolbarItem, and then go through the process of setting up its
            attributes from the master toolbar item matching that identifier in our dictionary of items.
        */
        if (itemIdentifier == FontStyleToolbarItemID) {
            // 1) Font style toolbar item.
            toolbarItem = customToolbarItem(itemForItemIdentifier: FontStyleToolbarItemID, label: "Font Style", paletteLabel:"Font Style", toolTip: "Change your font style", target: self, itemContent: self.styleSegmentView, action: nil, menu: nil)!
        }
        else if (itemIdentifier == FontSizeToolbarItemID) {
            // 2) Font size toolbar item.
            toolbarItem = customToolbarItem(itemForItemIdentifier: FontSizeToolbarItemID, label: "Font Size", paletteLabel: "Font Size", toolTip: "Grow or shrink the size of your font", target: self, itemContent: self.fontSizeView, action: nil, menu: nil)!
        }

        return toolbarItem
    }

    /**
        NSToolbar delegates require this function.  It returns an array holding identifiers for the default
        set of toolbar items.  It can also be called by the customization palette to display the default toolbar.
    */
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
        
        return [FontStyleToolbarItemID, FontSizeToolbarItemID]
        /*  Note:
            That since our toolbar is defined from Interface Builder, an additional separator and customize
            toolbar items will be automatically added to the "default" list of items.
        */
    }

    /**
        NSToolbar delegates require this function.  It returns an array holding identifiers for all allowed
        toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
    */
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [String] {
        
        return [ FontStyleToolbarItemID,
                 FontSizeToolbarItemID,
                 NSToolbarSpaceItemIdentifier,
                 NSToolbarFlexibleSpaceItemIdentifier,
                 NSToolbarPrintItemIdentifier ]
    }
    
    // MARK: - NSTouchBar
    
    @available(OSX 10.12.1, *)
    override func makeTouchBar() -> NSTouchBar? {
        
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .touchBar
        touchBar.defaultItemIdentifiers = [.fontStyle, .popover, .otherItemsProxy]
        touchBar.customizationAllowedItemIdentifiers = [.fontStyle, .popover]

        return touchBar
    }

}

extension WindowController: NSTouchBarDelegate {
    
    @available(OSX 10.12.1, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        
        switch identifier {
            
            case NSTouchBarItemIdentifier.popover:
                
                let popoverItem = NSPopoverTouchBarItem(identifier: identifier)
                popoverItem.customizationLabel = "Font Size"
                popoverItem.collapsedRepresentationLabel = "Font Size"
                
                let secondaryTouchBar = NSTouchBar()
                secondaryTouchBar.delegate = self
                secondaryTouchBar.defaultItemIdentifiers = [.popoverSlider];
                
                // We can setup a different NSTouchBar instance for popoverTouchBar and pressAndHoldTouchBar property
                // Here we just use the same instance.
                //
                popoverItem.pressAndHoldTouchBar = secondaryTouchBar
                popoverItem.popoverTouchBar = secondaryTouchBar
            
                return popoverItem
            
            case NSTouchBarItemIdentifier.fontStyle:
                
                let fontStyleItem = NSCustomTouchBarItem(identifier: identifier)
                fontStyleItem.customizationLabel = "Font Style"
                
                let fontStyleSegment = NSSegmentedControl(labels: ["Plain", "Bold", "Italic"], trackingMode: .momentary, target: self, action: #selector(changeFontStyleBySegment))
                
                fontStyleItem.view = fontStyleSegment
                
                return fontStyleItem;
            
            case NSTouchBarItemIdentifier.popoverSlider:
                
                let sliderItem = NSSliderTouchBarItem(identifier: identifier)
                sliderItem.label = "Size"
                sliderItem.customizationLabel = "Font Size"
                
                let slider = sliderItem.slider
                slider.minValue = 6.0
                slider.maxValue = 100.0
                slider.target = self
                slider.action = #selector(changeFontSizeBySlider)

                // Set the font size for the slider item to the same value as the stepper.
                slider.integerValue = DefaultFontSize
                
                slider.bind(NSValueBinding, to: self, withKeyPath: "currentFontSize", options: nil)
    
                return sliderItem
            
            default: return nil
        }
    }
    
}


/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's master view controller listing all the Accessibility examples.
*/

import Cocoa

class MasterViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
   
    // MARK: - Properties
    
    // The array controller data source of Examples.
    @IBOutlet var examplesArrayController: NSArrayController!
    
    // The data source for "examplesArrayController".
    @objc var examplesArrayBacking = [Example]()

    // So we can inform the delegate of table selection changes (from the user or from the array controller).
    weak var delegate: MasterViewControllerDelegate?

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addButtonTests()
        addTextTests()
        addSwitchesTests()
        addImagesTests()
        addOtherTests()
        addRotorTests()
        
        // Changing the backed array alone won't update the array controller, so set the array controller content.
        let indexes = IndexSet(integersIn: 0...examplesArrayBacking.count)
        examplesArrayController.willChange(.setting, valuesAt: indexes, forKey: "content")
        examplesArrayController.content = examplesArrayBacking
        examplesArrayController.didChange(.setting, valuesAt: indexes, forKey: "content")
        
        // Listen for when the array controller changes it's selection.
        examplesArrayController.addObserver(self,
                                            forKeyPath: "selectionIndexes",
                                            options: NSKeyValueObservingOptions.new,
                                            context: nil)
    }

    // MARK: - NSTableViewDataSource
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return (examplesArrayController.arrangedObjects as AnyObject).count
    }
    
    public func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        var result = false
        if let example = (examplesArrayController.arrangedObjects as AnyObject).object(at: row) as? Example {
            // A group row has no view controller.
            result = example.viewControllerIdentifier.characters.isEmpty
        }
        return result
    }
    
    // MARK: - NSTableViewDelegate
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let example = (examplesArrayController.arrangedObjects as AnyObject).object(at: row) as? Example else { return nil }
        
        // A group row has no view controller.
        if example.viewControllerIdentifier.characters.isEmpty {
            guard let cell =
                tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupCell"),
                                   owner: self) as? NSTextField else { return nil }
            cell.stringValue = example.name
            return cell
        } else {
            guard let cell =
                tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MainCell"),
                                   owner: self) as? NSTableCellView else { return nil }
            cell.textField?.stringValue = example.name
            return cell
        }
    }
    
    // MARK: - KVO

    /**
    Used for observing for NSArrayController selection changes:
    (selection changes as a result of filtering (user search) will not send NSTableViewSelectionDidChangeNotification),
    so we handle it right here to help target our detail view controller.
    */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath! == "selectionIndexes" {
            // Obtain the selection index from our array controller.
            if let arrayController = object as? NSArrayController {
                if arrayController.selectionIndex == NSNotFound {
                    delegate!.didChangeExampleSelection(masterViewController: self, selection: nil)
                } else {
                    if delegate != nil {
                        let viewControllers = examplesArrayController.arrangedObjects as AnyObject
                        if let example =
                            viewControllers.object(at: arrayController.selectionIndex) as? Example {
                            delegate!.didChangeExampleSelection(masterViewController: self, selection: example)
                        }
                    }
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: Table Configuration
    
    fileprivate func addButtonTests() {
        examplesArrayBacking.append(Example(name: NSLocalizedString("Buttons", comment: "Buttons group name"),
                                            description: "",
                                            viewControllerIdentifier: ""))
        
        examplesArrayBacking.append(Example(name: NSLocalizedString("NSButton", comment: "NSButton example name"),
                                            description: NSLocalizedString("NSButtonDescription", comment: "NSButton example description"),
                                            viewControllerIdentifier: "ButtonViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("NSButton with image", comment: "NSButton with image"),
                    description: NSLocalizedString("NSButtonWithImageDescription", comment: "NSButton with image example description"),
                    viewControllerIdentifier: "ButtonWithImageViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("NSButton subclass", comment: "NSButton subclass"),
                    description: NSLocalizedString("NSButtonSubclassDescription", comment: "NSButton subclass example description"),
                    viewControllerIdentifier: "ButtonSubclassViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("NSView subclass", comment: "NSView subclass"),
                    description: NSLocalizedString("NSViewSubclassButtonDescription", comment: "NSView subclass button example description"),
                    viewControllerIdentifier: "ButtonViewSubclassViewController"))
    }
    
    fileprivate func addTextTests() {
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Text", comment: "Text group name"),
                    description: "",
                    viewControllerIdentifier: ""))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Protected", comment: "Protected title"),
                    description: NSLocalizedString("ProtectedDescription", comment: "Protected example description"),
                    viewControllerIdentifier: "ProtectedTextViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("CoreText", comment: "CoreText title"),
                    description: NSLocalizedString("CoreTextDescription", comment: "CoreText example description"),
                    viewControllerIdentifier: "CoreTextViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Columns", comment: "Columns title"),
                    description: NSLocalizedString("ColumnDescription", comment: "Column example description"),
                    viewControllerIdentifier: "CoreTextColumnViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Text Attributes", comment: "TextAttributes title"),
                    description: NSLocalizedString("TextAttributesDescription", comment: "Text Attributes description"),
                    viewControllerIdentifier: "TextAttributesViewController"))
    }
    
    fileprivate func addSwitchesTests() {
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Switches", comment: "Switches group name"),
                    description: "",
                    viewControllerIdentifier: ""))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("TwoPositionTitle", comment: "Two position example name"),
                    description: NSLocalizedString("TwoPositionDescription", comment: "Two position example description"),
                    viewControllerIdentifier: "TwoPositionSwitchViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("ThreePositionTitle", comment: "Three position example name"),
                    description: NSLocalizedString("ThreePositionDescription", comment:  "Three position example description"),
                    viewControllerIdentifier: "ThreePositionSwitchViewController"))
    }
    
    fileprivate func addImagesTests() {
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Images", comment: "Images group name"),
                    description: "",
                    viewControllerIdentifier: ""))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("NSImageView subclass", comment: "NSImageView subclass example name"),
                    description: NSLocalizedString("NSImageViewSubclassDescription", comment: "NSImageView subclass example description"),
                    viewControllerIdentifier: "ImageViewSubclassViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("NSView subclass", comment: "NSView subclass example name"),
                    description: NSLocalizedString("NSViewSubclassImageDescription", comment: "NSView subclass image example description"),
                    viewControllerIdentifier: "ViewImageSubclassViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("CALayer subclass", comment: "CALayer subclass example name"),
                    description: NSLocalizedString("CALayerSubclassImageDescription", comment: "CALayer subclass image example description"),
                    viewControllerIdentifier: "ImageViewLayerImageViewController"))
    }
    
    fileprivate func addOtherTests() {
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Other Elements", comment: "Other elements group name"),
                    description: "",
                    viewControllerIdentifier: ""))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Radio Button", comment: "Radio button example name"),
                    description: NSLocalizedString("RadioButtonDescription", comment: "Radio button example description"),
                    viewControllerIdentifier: "CustomRadioButtonsViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Checkbox", comment: "Checkbox example name"),
                    description: NSLocalizedString("CheckboxDescription", comment: "Checkbox example description"),
                    viewControllerIdentifier: "CustomCheckBoxViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Slider", comment: "Slider example name"),
                    description: NSLocalizedString("SliderDescription", comment: "Slider example description"),
                    viewControllerIdentifier: "CustomSliderViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Layout Area", comment: "Layout area example name"),
                    description: NSLocalizedString("LayoutAreaDescription", comment: "Layout area example description"),
                    viewControllerIdentifier: "CustomLayoutAreaViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Outline", comment: "Outline example name"),
                    description: NSLocalizedString("OutlineDescription", comment: "Outline example description"),
                    viewControllerIdentifier: "CustomOutlineViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Table", comment: "Table example name"),
                    description: NSLocalizedString("TableDescription", comment: "Table example description"),
                    viewControllerIdentifier: "CustomTableViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Stepper", comment: "Stepper example name"),
                    description: NSLocalizedString("StepperDescription", comment: "Stepper example description"),
                    viewControllerIdentifier: "CustomStepperViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Transient UI", comment: "Transient UI example name"),
                    description: NSLocalizedString("TransientUIDescription", comment: "Transient UI example description"),
                    viewControllerIdentifier: "TransientUIViewController"))
        
        examplesArrayBacking.append(
            Example(name: NSLocalizedString("Search Field", comment: "Search field example name"),
                    description: NSLocalizedString("SearchFieldDescription", comment: "Search field example description"),
                    viewControllerIdentifier: "CustomSearchFieldViewController"))
    }
    
    fileprivate func addRotorTests () {
        if #available(OSX 10.13, *) {
            examplesArrayBacking.append(
                Example(name: NSLocalizedString("Custom Rotors", comment: "Custom Rotors group name"),
                        description: "",
                        viewControllerIdentifier: ""))
            
            examplesArrayBacking.append(
                Example(name: NSLocalizedString("Element Rotors", comment: "Element rotors example name"),
                        description: NSLocalizedString("ElementRotorsDescription", comment: "Element rotors example description"),
                        viewControllerIdentifier: "CustomRotorsElementViewController"))

            examplesArrayBacking.append(
                Example(name: NSLocalizedString("Text Rotors", comment: "Text rotors example name"),
                        description: NSLocalizedString("TextRotorsDescription", comment: "Text rotors example description"),
                        viewControllerIdentifier: "CustomRotorsTextViewController"))

        }
    }
    
}

/// Used for informing the delegate of the array controller selection change (as a result of filtering from the search field).
protocol MasterViewControllerDelegate : class {
    func didChangeExampleSelection(masterViewController: MasterViewController, selection: Example?)
}


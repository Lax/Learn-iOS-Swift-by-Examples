/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The `ListRowViewController` class is an NSViewController subclass that displays list items in a NCWidgetListViewController. Bindings are used to link the represented object to the view controller.
            
*/

import Cocoa
import ListerKitOSX

// Protocol that enables notifying other objects of changes to the represented object.
protocol ListRowViewControllerDelegate: class {
    func listRowViewControllerDidChangeRepresentedObjectState(listRowViewController: ListRowViewController)
}

class ListRowViewController: NSViewController {
    // MARK: Properties

    @IBOutlet weak var checkBox: CheckBox!

    weak var delegate: ListRowViewControllerDelegate?
    
    override var nibName: String {
        return "ListRowViewController"
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // `representedObject` is a `ListRowRepresentedObject` instance.
        checkBox.bind("isChecked", toObject: self, withKeyPath: "self.representedObject.item.isComplete", options: nil)
        checkBox.bind("tintColor", toObject: self, withKeyPath: "self.representedObject.color", options: nil)
    }
    
    // MARK: IBActions

    @IBAction func checkBoxClicked(_: CheckBox) {
        delegate?.listRowViewControllerDidChangeRepresentedObjectState(self)
    }
}

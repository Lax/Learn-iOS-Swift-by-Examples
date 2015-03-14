/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `NewListDocumentController` class allows users to create a new list document with a name and preferred color.
*/

import UIKit
import ListerKit

class NewListDocumentController: UIViewController, UITextFieldDelegate {
    // MARK: Properties

    @IBOutlet weak var grayButton: UIButton!
    
    @IBOutlet weak var blueButton: UIButton!
    
    @IBOutlet weak var greenButton: UIButton!
    
    @IBOutlet weak var yellowButton: UIButton!
    
    @IBOutlet weak var orangeButton: UIButton!

    @IBOutlet weak var redButton: UIButton!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var nameField: UITextField!
    
    weak var selectedButton: UIButton?
    
    var selectedColor = List.Color.Gray
    var selectedTitle: String?

    var listsController: ListsController!
    
    // MARK: IBActions
    
    @IBAction func pickColor(sender: UIButton) {
        // The user is choosing a color, resign first responder on the text field, if necessary.
        if nameField.isFirstResponder() {
            nameField.resignFirstResponder()
        }
        
        // Use the button's tag to determine the color.
        selectedColor = List.Color(rawValue: sender.tag)!
        
        // If a button was previously selected, we need to clear out its previous border.
        if let oldButton = selectedButton {
            oldButton.layer.borderWidth = 0.0
        }
        
        sender.layer.borderWidth = 5.0
        sender.layer.borderColor = UIColor.lightGrayColor().CGColor
        selectedButton = sender
        titleLabel.textColor = selectedColor.colorValue
        toolbar.tintColor = selectedColor.colorValue
    }
    
    @IBAction func save(sender: AnyObject) {
        let list = List()
        list.color = selectedColor
        
        listsController.createListInfoForList(list, withName: selectedTitle!)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Touch Handling
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        let possibleTouch = touches.anyObject() as? UITouch
        
        if let touch = possibleTouch {
            // The user has tapped outside the text field, resign first responder, if necessary.
            if nameField.isFirstResponder() && touch.view != nameField {
                nameField.resignFirstResponder()
            }
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let updatedText = (textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string)
        updateForProposedListName(updatedText)
        
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        updateForProposedListName(textField.text)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
    
    // MARK: Convenience
    
    func updateForProposedListName(name: String) {
        if listsController.canCreateListInfoWithName(name) {
            saveButton.enabled = true
            selectedTitle = name
        }
        else {
            saveButton.enabled = false
        }
    }
}

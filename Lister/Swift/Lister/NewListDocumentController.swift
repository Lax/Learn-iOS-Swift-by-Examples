/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Allows users to create a new list document with a name and preferred color.
            
*/

import UIKit
import ListerKit

// Provides the ability to send a delegate a message about newly created list info objects.
@class_protocol protocol NewListDocumentControllerDelegate {
    func newListDocumentController(newListDocumentController: NewListDocumentController, didCreateDocumentWithListInfo listInfo: ListInfo)
}

class NewListDocumentController: UIViewController, UITextFieldDelegate {
    // MARK: Properties

    @IBOutlet var grayButton: UIButton
    @IBOutlet var blueButton: UIButton
    @IBOutlet var greenButton: UIButton
    @IBOutlet var yellowButton: UIButton
    @IBOutlet var orangeButton: UIButton
    @IBOutlet var redButton: UIButton
    @IBOutlet var saveButton: UIBarButtonItem
    @IBOutlet var toolbar: UIToolbar
    @IBOutlet var titleLabel: UILabel
    
    weak var selectedButton: UIButton?
    
    // Lets the delegate know about new list info objects that are created.
    var delegate: NewListDocumentControllerDelegate?
    
    var selectedColor = List.Color.Gray
    var selectedTitle: String?
    
    var fileURL: NSURL? {
        if selectedTitle {
            return ListCoordinator.sharedListCoordinator.documentURLForName(selectedTitle!)
        }
        
        return nil
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        if ListCoordinator.sharedListCoordinator.isValidDocumentName(textField.text) {
            saveButton.enabled = true
            selectedTitle = textField.text
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: IBActions
    
    @IBAction func pickColor(sender: UIButton) {
        // Use the button's tag to determine the color.
        selectedColor = List.Color.fromRaw(sender.tag)!
        
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
        let listInfo = ListInfo(provider: fileURL!)
        listInfo.color = selectedColor
        
        listInfo.createAndSaveWithCompletionHandler { success in
            if success {
                self.delegate?.newListDocumentController(self, didCreateDocumentWithListInfo: listInfo)
            }
            else {
                // In your app, you should handle this error gracefully.
                NSLog("Unable to save document to URL: \(self.fileURL!.absoluteString).")
                abort()
            }
        }
        
        dismissModalViewControllerAnimated(true)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        dismissModalViewControllerAnimated(true)
    }
}

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UIButton. The buttons are created using storyboards, but each of the system buttons can be created in code by using the UIButton.buttonWithType() initializer. See the UIButton interface for a comprehensive list of the various UIButtonType values.
*/

import UIKit

class ButtonViewController: UITableViewController {
    // MARK: - Properties

    @IBOutlet weak var systemTextButton: UIButton!
    
    @IBOutlet weak var systemContactAddButton: UIButton!
    
    @IBOutlet weak var systemDetailDisclosureButton: UIButton!
    
    @IBOutlet weak var imageButton: UIButton!
    
    @IBOutlet weak var attributedTextButton: UIButton!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // All of the buttons are created in the storyboard, but configured below.
        configureSystemTextButton()
        configureSystemContactAddButton()
        configureSystemDetailDisclosureButton()
        configureImageButton()
        configureAttributedTextSystemButton()
    }

    // MARK: - Configuration

    func configureSystemTextButton() {
        let buttonTitle = NSLocalizedString("Button", comment: "")

        systemTextButton.setTitle(buttonTitle, for: UIControlState())

        systemTextButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureSystemContactAddButton() {
        systemContactAddButton.backgroundColor = UIColor.clear

        systemContactAddButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureSystemDetailDisclosureButton() {
        systemDetailDisclosureButton.backgroundColor = UIColor.clear

        systemDetailDisclosureButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureImageButton() {
        // To create this button in code you can use UIButton.buttonWithType() with a parameter value of .Custom.

        // Remove the title text.
        imageButton.setTitle("", for: UIControlState())

        imageButton.tintColor = UIColor.applicationPurpleColor

        let imageButtonNormalImage = UIImage(named: "x_icon")
        imageButton.setImage(imageButtonNormalImage, for: UIControlState())

        // Add an accessibility label to the image.
        imageButton.accessibilityLabel = NSLocalizedString("X Button", comment: "")

        imageButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    func configureAttributedTextSystemButton() {
        let buttonTitle = NSLocalizedString("Button", comment: "")
        
        // Set the button's title for normal state.
        let normalTitleAttributes = [
            NSForegroundColorAttributeName: UIColor.applicationBlueColor,
            NSStrikethroughStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue
        ] as [String : Any]
        let normalAttributedTitle = NSAttributedString(string: buttonTitle, attributes: normalTitleAttributes)
        attributedTextButton.setAttributedTitle(normalAttributedTitle, for: UIControlState())

        // Set the button's title for highlighted state.
        let highlightedTitleAttributes = [
            NSForegroundColorAttributeName: UIColor.green,
            NSStrikethroughStyleAttributeName: NSUnderlineStyle.styleThick.rawValue
        ] as [String : Any]
        let highlightedAttributedTitle = NSAttributedString(string: buttonTitle, attributes: highlightedTitleAttributes)
        attributedTextButton.setAttributedTitle(highlightedAttributedTitle, for: .highlighted)

        attributedTextButton.addTarget(self, action: #selector(ButtonViewController.buttonClicked(_:)), for: .touchUpInside)
    }

    // MARK: - Actions

    func buttonClicked(_ sender: UIButton) {
        NSLog("A button was clicked: \(sender).")
    }
}

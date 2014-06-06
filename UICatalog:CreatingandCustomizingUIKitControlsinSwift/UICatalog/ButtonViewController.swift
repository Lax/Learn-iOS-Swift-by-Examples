/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                 A view controller that demonstrates how to use UIButton. The buttons are created using storyboards, but each of the system buttons can be created in code by using the UIButton.buttonWithType() initializer. See the UIButton interface for a comprehensive list of the various UIButtonType values.
            
*/

import UIKit

class ButtonViewController: UITableViewController {
    // MARK: Properties

    @IBOutlet var systemTextButton: UIButton
    @IBOutlet var systemContactAddButton: UIButton
    @IBOutlet var systemDetailDisclosureButton: UIButton
    @IBOutlet var imageButton: UIButton
    @IBOutlet var attributedTextButton: UIButton

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // All of the buttons are created in the storyboard, but configured below.
        configureSystemTextButton()
        configureSystemContactAddButton()
        configureSystemDetailDisclosureButton()
        configureImageButton()
        configureAttributedTextSystemButton()
    }

    // MARK: Configuration

    func configureSystemTextButton() {
        systemTextButton.setTitle(NSLocalizedString("Button", comment: ""), forState: .Normal)

        systemTextButton.addTarget(self, action: "buttonClicked:", forControlEvents: .TouchUpInside)
    }

    func configureSystemContactAddButton() {
        systemContactAddButton.backgroundColor = UIColor.clearColor()

        systemContactAddButton.addTarget(self, action: "buttonClicked:", forControlEvents: .TouchUpInside)
    }

    func configureSystemDetailDisclosureButton() {
        systemDetailDisclosureButton.backgroundColor = UIColor.clearColor()

        systemDetailDisclosureButton.addTarget(self, action: "buttonClicked:", forControlEvents: .TouchUpInside)
    }

    func configureImageButton() {
        // To create this button in code you can use UIButton.buttonWithType() with a parameter value of .Custom.

        // Remove the title text.
        imageButton.setTitle("", forState: .Normal)

        imageButton.tintColor = UIColor.applicationPurpleColor()

        imageButton.setImage(UIImage(named: "x_icon"), forState: .Normal)

        // Add an accessibility label to the image.
        imageButton.accessibilityLabel = NSLocalizedString("X Button", comment: "")

        imageButton.addTarget(self, action: "buttonClicked:", forControlEvents: .TouchUpInside)
    }

    func configureAttributedTextSystemButton() {
        let titleAttributes = [NSForegroundColorAttributeName: UIColor.applicationBlueColor(), NSStrikethroughStyleAttributeName: NSUnderlineStyle.StyleSingle.toRaw()]
        let attributedTitle = NSAttributedString(string: NSLocalizedString("Button", comment: ""), attributes: titleAttributes)
        attributedTextButton.setAttributedTitle(attributedTitle, forState: .Normal)

        let highlightedTitleAttributes = [NSForegroundColorAttributeName: UIColor.greenColor(), NSStrikethroughStyleAttributeName: NSUnderlineStyle.StyleThick.toRaw()]
        let highlightedAttributedTitle = NSAttributedString(string: NSLocalizedString("Button", comment: ""), attributes: highlightedTitleAttributes)
        attributedTextButton.setAttributedTitle(highlightedAttributedTitle, forState: .Highlighted)

        attributedTextButton.addTarget(self, action: "buttonClicked:", forControlEvents: .TouchUpInside)
    }

    // MARK: Actions

    func buttonClicked(sender: UIButton) {
        NSLog("A button was clicked: \(sender).")
    }
}

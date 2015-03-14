/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UITextView.
*/

import UIKit

class TextViewController: UIViewController, UITextViewDelegate {
    // MARK: Properties
    
    @IBOutlet weak var textView: UITextView!
    
    /// Used to adjust the text view's height when the keyboard hides and shows.
    @IBOutlet weak var textViewBottomLayoutGuideConstraint: NSLayoutConstraint!

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTextView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Listen for changes to keyboard visibility so that we can adjust the text view accordingly.
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleKeyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "handleKeyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    // MARK: Keyboard Event Notifications

    func handleKeyboardWillShowNotification(notification: NSNotification) {
        keyboardWillChangeFrameWithNotification(notification, showsKeyboard: true)
    }
    
    func handleKeyboardWillHideNotification(notification: NSNotification) {
        keyboardWillChangeFrameWithNotification(notification, showsKeyboard: false)
    }
    
    // MARK: Convenience

    func keyboardWillChangeFrameWithNotification(notification: NSNotification, showsKeyboard: Bool) {
        let userInfo = notification.userInfo!

        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        // Convert the keyboard frame from screen to view coordinates.
        let keyboardScreenBeginFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        let keyboardViewBeginFrame = view.convertRect(keyboardScreenBeginFrame, fromView: view.window)
        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)
        let originDelta = keyboardViewEndFrame.origin.y - keyboardViewBeginFrame.origin.y
        
        // The text view should be adjusted, update the constant for this constraint.
        textViewBottomLayoutGuideConstraint.constant -= originDelta

        view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: .BeginFromCurrentState, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        // Scroll to the selected text once the keyboard frame changes.
        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
    }

    // MARK: Configuration

    func configureTextView() {
        let bodyFontDescriptor = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
        textView.font = UIFont(descriptor: bodyFontDescriptor, size: 0)

        textView.textColor = UIColor.blackColor()
        textView.backgroundColor = UIColor.whiteColor()
        textView.scrollEnabled = true

        // Let's modify some of the attributes of the attributed string.
        // You can modify these attributes yourself to get a better feel for what they do.
        // Note that the initial text is visible in the storyboard.
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText!)

        // Use NSString so the result of rangeOfString is an NSRange, not Range<String.Index>.
        let text = textView.text! as NSString

        // Find the range of each element to modify.
        let boldRange = text.rangeOfString(NSLocalizedString("bold", comment: ""))
        let highlightedRange = text.rangeOfString(NSLocalizedString("highlighted", comment: ""))
        let underlinedRange = text.rangeOfString(NSLocalizedString("underlined", comment: ""))
        let tintedRange = text.rangeOfString(NSLocalizedString("tinted", comment: ""))

        // Add bold. Take the current font descriptor and create a new font descriptor with an additional bold trait.
        let boldFontDescriptor = textView.font.fontDescriptor().fontDescriptorWithSymbolicTraits(.TraitBold)!
        let boldFont = UIFont(descriptor: boldFontDescriptor, size: 0)
        attributedText.addAttribute(NSFontAttributeName, value: boldFont, range: boldRange)

        // Add highlight.
        attributedText.addAttribute(NSBackgroundColorAttributeName, value: UIColor.applicationGreenColor(), range: highlightedRange)

        // Add underline.
        attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: underlinedRange)

        // Add tint.
        attributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.applicationBlueColor(), range: tintedRange)

        // Add image attachment.
        let textAttachment = NSTextAttachment()
        let image = UIImage(named: "text_view_attachment")!
        textAttachment.image = image
        textAttachment.bounds = CGRect(origin: CGPointZero, size: image.size)

        let textAttachmentString = NSAttributedString(attachment: textAttachment)
        attributedText.appendAttributedString(textAttachmentString)

        textView.attributedText = attributedText
    }

    // MARK: UITextViewDelegate

    func textViewDidBeginEditing(textView: UITextView) {
        // Provide a "Done" button for the user to select to signify completion with writing text in the text view.
        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneBarButtonItemClicked")

        navigationItem.setRightBarButtonItem(doneBarButtonItem, animated: true)
    }
    
    // MARK: Actions

    func doneBarButtonItemClicked() {
        // Dismiss the keyboard by removing it as the first responder.
        textView.resignFirstResponder()

        navigationItem.setRightBarButtonItem(nil, animated: true)
    }
}

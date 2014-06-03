/*
        File: TextViewController.swift
    Abstract: 
                A view controller that demonstrates how to use UITextView.
            
     Version: 1.0
    
    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
    Inc. ("Apple") in consideration of your agreement to the following
    terms, and your use, installation, modification or redistribution of
    this Apple software constitutes acceptance of these terms.  If you do
    not agree with these terms, please do not use, install, modify or
    redistribute this Apple software.
    
    In consideration of your agreement to abide by the following terms, and
    subject to these terms, Apple grants you a personal, non-exclusive
    license, under Apple's copyrights in this original Apple software (the
    "Apple Software"), to use, reproduce, modify and redistribute the Apple
    Software, with or without modifications, in source and/or binary forms;
    provided that if you redistribute the Apple Software in its entirety and
    without modifications, you must retain this notice and the following
    text and disclaimers in all such redistributions of the Apple Software.
    Neither the name, trademarks, service marks or logos of Apple Inc. may
    be used to endorse or promote products derived from the Apple Software
    without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or
    implied, are granted by Apple herein, including but not limited to any
    patent rights that may be infringed by your derivative works or by other
    works in which the Apple Software may be incorporated.
    
    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
    MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
    OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
    
    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
    MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
    AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
    STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
    
    Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/

import UIKit

class TextViewController: UIViewController, UITextViewDelegate {
    // MARK: Properties
    @IBOutlet var textView: UITextView
    
    // Used to adjust the text view's height when the keyboard hides and shows.
    @IBOutlet var textViewBottomLayoutGuideConstraint: NSLayoutConstraint

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
        let userInfo = notification.userInfo
        
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        
        // Convert the keyboard frame from screen to view coordinates.
        let keyboardScreenBeginFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as NSValue).CGRectValue()
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
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
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)

        // Use NSString so the result of rangeOfString is an NSRange, not Range<String.Index>.
        let text = textView.text as NSString

        // Find the range of each element to modify.
        let boldRange = text.rangeOfString(NSLocalizedString("bold", comment: ""))
        let highlightedRange = text.rangeOfString(NSLocalizedString("highlighted", comment: ""))
        let underlinedRange = text.rangeOfString(NSLocalizedString("underlined", comment: ""))
        let tintedRange = text.rangeOfString(NSLocalizedString("tinted", comment: ""))

        // Add bold. Take the current font descriptor and create a new font descriptor with an additional bold trait.
        let boldFontDescriptor = textView.font.fontDescriptor().fontDescriptorWithSymbolicTraits(.TraitBold)
        let boldFont = UIFont(descriptor: boldFontDescriptor, size: 0)
        attributedText.addAttribute(NSFontAttributeName, value: boldFont, range: boldRange)

        // Add highlight.
        attributedText.addAttribute(NSBackgroundColorAttributeName, value: UIColor.applicationGreenColor(), range: highlightedRange)

        // Add underline.
        attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.toRaw(), range: underlinedRange)

        // Add tint.
        attributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.applicationBlueColor(), range: tintedRange)

        // Add image attachment.
        let textAttachment = NSTextAttachment()
        let image = UIImage(named: "text_view_attachment")
        textAttachment.image = image

        textAttachment.bounds = CGRect(origin: CGPointZero, size: image.size)
        let textAttachmentString = NSAttributedString(attachment: textAttachment)
        attributedText.appendAttributedString(textAttachmentString)

        textView.attributedText = attributedText
    }
    
    // MARK:  UITextView Adjustment
    func adjustTextViewSelection(textView: UITextView) {
        // Ensure that the text view is visible by making the text view frame smaller as text can be slightly cropped at the bottom.
        // Note that this is a workwaround to a bug in iOS.

        textView.layoutIfNeeded()
        
        var caretRect = textView.caretRectForPosition(textView.selectedTextRange.end)
        caretRect.size.height += textView.textContainerInset.bottom
        textView.scrollRectToVisible(caretRect, animated: false)
    }

    // MARK: UITextViewDelegate
    func textViewDidBeginEditing(textView: UITextView) {
        // Provide a "Done" button for the user to select to signify completion with writing text in the text view.
        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneBarButtonItemClicked")

        navigationItem.setRightBarButtonItem(doneBarButtonItem, animated: true)
        
        adjustTextViewSelection(textView)
    }

    func textViewDidChangeSelection(textView: UITextView) {
        adjustTextViewSelection(textView)
    }
    
    // MARK: Actions
    func doneBarButtonItemClicked() {
        // Dismiss the keyboard by removing it as the first responder.
        textView.resignFirstResponder()

        navigationItem.setRightBarButtonItem(nil, animated: true)
    }
}

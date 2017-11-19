/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The delegate that handles creating a new chat (including taking a photo from the camera).
 */

import UIKit

class NewChatDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    static func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    private weak var presentingViewController: UIViewController?
    private let recipient: Friend?
    private let completion: (UIImage?) -> Void
    
    init(presentingViewController: UIViewController, recipient: Friend?, completion: @escaping (UIImage?) -> Void) {
        self.presentingViewController = presentingViewController
        self.recipient = recipient
        self.completion = completion
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true) {
            let chatImage = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as? UIImage
            
            // Since AppChat isn't a real chat app yet, we'll just present an alert to simulate the rest.
            let alert = UIAlertController(title: self.alertTitle(for: self.recipient), message: self.alertMessage(for: self.recipient), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK string"), style: .default) { (_) -> Void in
                self.completion(chatImage)
            }
            alert.addAction(okAction)
            self.presentingViewController?.present(alert, animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { 
            self.completion(nil)
        }
    }
    
    private func alertTitle(for recipient: Friend?) -> String {
        if let friend = recipient {
            let format = NSLocalizedString("Chat Sent to %@", comment: "Format string for a chat sent to a friend")
            return String(format: format, friend.name)
        }
        else {
            return NSLocalizedString("Choose a Friend", comment: "Choose a friend as the chat recipient")
        }
    }
    
    private func alertMessage(for recipient: Friend?) -> String {
        if let friend = recipient {
            let format = NSLocalizedString("This is where we'd send the chat to your friend %@. But AppChat isn't a real chat app yet, so use your imagination!", comment: "Message when sending a new chat with a recipient, the friend name is substituted for the format specifier")
            return String(format: format, friend.name)
        }
        else {
            return NSLocalizedString("This is where you'd choose a friend, and then we'd send the chat to them. But AppChat isn't a real chat app yet, so use your imagination!", comment: "Message when sending a new chat without a recipient")
        }
    }
}

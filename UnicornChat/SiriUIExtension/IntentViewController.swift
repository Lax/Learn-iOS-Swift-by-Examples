/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view controller providing a user interface for the intent.
*/

import IntentsUI
import UnicornCore

class IntentViewController: UIViewController, INUIHostedViewControlling, INUIHostedViewSiriProviding {
    
    // MARK: INUIHostedViewControlling
    
    func configure(with interaction: INInteraction!, context: INUIHostedViewContext, completion: ((CGSize) -> Void)!) {
        var size: CGSize
        
        // Check if the interaction describes a SendMessageIntent.
        if interaction.representsSendMessageIntent {
            // If it is, let's set up a view controller.
            let chatViewController = UCChatViewController()
            chatViewController.messageContent = interaction.messageContent

            let contact = UCContact()
            contact.name = interaction.recipientName
            chatViewController.recipient = contact
            
            switch interaction.intentHandlingStatus {
                case .unspecified, .inProgress, .ready, .failure:
                    chatViewController.isSent = false
                
                case .success, .deferredToApplication:
                    chatViewController.isSent = true
            }
            
            present(chatViewController, animated: false, completion: nil)
            
            size = desiredSize
        }
        else {
            // Otherwise, we'll tell the host to draw us at zero size.
            size = CGSize.zero
        }
        
        completion(size)
    }
    
    var desiredSize: CGSize {
        return extensionContext!.hostedViewMaximumAllowedSize
    }
    
    var displaysMessage: Bool {
        return true
    }
}

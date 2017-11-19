/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller that displays a received chat. This class is responsible for providing the preview quick actions for a chat, as well as setting up the interactive presentation of the reply buttons using UIPreviewInteraction.
 */

import UIKit

class ChatDetailViewController: UIViewController, ChatReplyDelegate {
    static let identifier = "ChatDetailViewController"
    
    @IBOutlet var imageView: UIImageView!
    
    var chatItem: ChatItem! {
        didSet {
            imageView?.image = chatItem?.image
        }
    }
    
    var isReplyButtonHidden = false {
        didSet {
            replyButton.isHidden = isReplyButtonHidden
        }
    }
    
    fileprivate let replyButton = ChatReplyButton(title: "💬", pulses: true)
    fileprivate let replyViewController = ChatReplyViewController()
    fileprivate var replyPreviewInteraction: UIPreviewInteraction!
    fileprivate var replyViewControllerIsPresented: Bool {
        return presentedViewController != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(format: NSLocalizedString("Chat from %@", comment: "Format string for a chat received from a friend"), chatItem.sender.name)
        
        replyViewController.delegate = self
        
        replyPreviewInteraction = UIPreviewInteraction(view: view)
        replyPreviewInteraction.delegate = self
        
        imageView.image = chatItem.image
        
        replyButton.action = {[unowned self] _ in
            if !self.replyViewControllerIsPresented {
                let sourcePoint = self.replyButton.center
                self.replyViewController.normalizedSourcePoint = normalizedPoint(sourcePoint, in: self.view)
                self.replyViewController.presentationIsInteractive = false
                self.present(self.replyViewController, animated: true)
            }
        }
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(replyButton)
        
        let constraints = [replyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                           replyButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30)]
        NSLayoutConstraint.activate(constraints)
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        func savePreviewActionTitle(for chatItem: ChatItem) -> String {
            if chatItem.saved {
                return NSLocalizedString("Chat Saved", comment: "Un-save the chat action item")
            }
            else {
                return NSLocalizedString("Save Chat", comment: "Save the chat action item")
            }
        }
        
        func savePreviewActionStyle(for chatItem: ChatItem) -> UIPreviewActionStyle {
            if chatItem.saved {
                return .selected
            }
            else {
                return .default
            }
        }
        
        let replyActionHandler = {[unowned self] (action: UIPreviewAction, viewController: UIViewController) -> Void in
            self.send(reply: action.title)
        }
        let replyActions = [UIPreviewAction(title: "❤️", style: .default, handler: replyActionHandler),
                            UIPreviewAction(title: "😄", style: .default, handler: replyActionHandler),
                            UIPreviewAction(title: "👍", style: .default, handler: replyActionHandler),
                            UIPreviewAction(title: "😯", style: .default, handler: replyActionHandler),
                            UIPreviewAction(title: "😢", style: .default, handler: replyActionHandler),
                            UIPreviewAction(title: "😈", style: .default, handler: replyActionHandler)]
        let sendReply = UIPreviewActionGroup(title: NSLocalizedString("Send Reply…", comment: "Send reply action group title"), style: .default, actions: replyActions)
        
        let save = UIPreviewAction(title: savePreviewActionTitle(for: chatItem), style: savePreviewActionStyle(for: chatItem)) {[unowned self] (action, viewController) in
            self.toggleSaved(chatItem: self.chatItem)
        }
        
        let block = UIPreviewAction(title: NSLocalizedString("Block", comment: "Block the user action item"), style: .destructive) {[unowned self] (action, viewController) in
            self.block(user: self.chatItem.sender)
        }
        
        return [sendReply, save, block]
    }
    
    func toggleSaved(chatItem: ChatItem) {
        ChatItemManager.sharedInstance.toggleSaved(chatItem: chatItem)
    }
    
    func send(reply: String) {
        ChatItemManager.sharedInstance.send(reply: reply, to: chatItem.sender)
    }
    
    func block(user: Friend) {
        ChatItemManager.sharedInstance.block(user: user)
    }
}

extension ChatDetailViewController: UIPreviewInteractionDelegate {
    func previewInteractionShouldBegin(_ previewInteraction: UIPreviewInteraction) -> Bool {
        return !replyViewControllerIsPresented
    }
    
    func previewInteraction(_ previewInteraction: UIPreviewInteraction, didUpdatePreviewTransition transitionProgress: CGFloat, ended: Bool) {
        if !replyViewControllerIsPresented {
            var sourcePoint = previewInteraction.location(in: view)
            if replyButton.frame.contains(sourcePoint) {
                sourcePoint = replyButton.center
            }
            replyViewController.normalizedSourcePoint = normalizedPoint(sourcePoint, in: view)
            replyViewController.presentationIsInteractive = true
            present(replyViewController, animated: true)
        }
        
        replyViewController.interactiveTransitionProgress = transitionProgress
        
        if ended {
            replyViewController.completeCurrentInteractiveTransition()
        }
    }
    
    func previewInteraction(_ previewInteraction: UIPreviewInteraction, didUpdateCommitTransition transitionProgress: CGFloat, ended: Bool) {
        replyViewController.previewTouchPosition = previewInteraction.location(in: replyViewController.view)
        replyViewController.overexpansion = transitionProgress
        
        if ended {
            replyViewController.previewTouchPosition = nil
            
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.allowUserInteraction], animations: {
                self.replyViewController.overexpansion = 0.0
            })
        }
    }
    
    func previewInteractionDidCancel(_ previewInteraction: UIPreviewInteraction) {
        replyViewController.chooseTouchedReplyButton()
        replyViewController.cancelCurrentInteractiveTransition()
        replyViewController.dismiss(animated: true)
    }
}

private func normalizedPoint(_ point: CGPoint, in view: UIView) -> CGPoint {
    guard view.bounds.width > 0.0 && view.bounds.height > 0.0 else { return CGPoint.zero }
    let x = point.x / view.bounds.width
    let y = point.y / view.bounds.height
    return CGPoint(x: x, y: y)
}

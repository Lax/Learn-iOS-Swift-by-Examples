/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The transitioning delegate used for the ChatReplyViewController presentation.
 */

import UIKit

class ChatReplyTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var presentationIsInteractive = false
    var currentTransitionProgress: CGFloat = 0.0 {
        didSet {
            currentInteractionController?.update(currentTransitionProgress)
        }
    }
    func completeCurrentInteractiveTransition() {
        currentInteractionController?.finish()
    }
    func cancelCurrentInteractiveTransition() {
        currentInteractionController?.cancel()
    }
    
    private var currentInteractionController: ChatReplyInteractionController? = nil
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatReplyPresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatReplyDismissAnimator()
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ChatReplyPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if presentationIsInteractive {
            currentInteractionController = ChatReplyInteractionController()
            return currentInteractionController
        }
        else {
            return nil
        }
    }
}

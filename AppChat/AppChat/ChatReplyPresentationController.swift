/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The presentation controller used for the ChatReplyViewController presentation.
 */

import UIKit

class ChatReplyPresentationController: UIPresentationController {
    let blurView = UIVisualEffectView()
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    override func presentationTransitionWillBegin() {
        blurView.frame = containerView!.bounds
        containerView!.insertSubview(blurView, at: 0)
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurView.effect = UIBlurEffect(style: .light)
        })
    }
    
    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurView.effect = nil
        })
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return containerView!.bounds
    }
}

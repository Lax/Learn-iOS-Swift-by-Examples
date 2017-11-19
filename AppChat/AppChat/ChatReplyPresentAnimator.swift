/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The animator used when the ChatReplyViewController is presented.
 */

import UIKit

private enum AnimationParameters {
    static let duration = 0.4
    static let damping: CGFloat = 0.7
}

class ChatReplyPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return AnimationParameters.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let replyView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
            transitionContext.containerView.addSubview(replyView)
            replyView.layoutIfNeeded()
            replyView.alpha = 1.0
        }
        
        let replyViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as! ChatReplyViewController
        
        let animations = {
            replyViewController.isExpanded = true
        }
        
        let completion = { (finished: Bool) in
            transitionContext.completeTransition(finished)
        }
        
        replyViewController.isExpanded = false
        
        if transitionContext.isAnimated {
            let duration = transitionDuration(using: transitionContext)
            let runAnimations = {
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: AnimationParameters.damping, initialSpringVelocity: 0, options: [], animations: animations, completion: completion)
            }
            if transitionContext.isInteractive {
                UIView.animate(withDuration: duration, delay: 0, options: [], animations: {}, completion: { (finished) in
                    if transitionContext.transitionWasCancelled {
                        completion(false)
                    }
                    else {
                        runAnimations()
                    }
                })
            }
            else {
                runAnimations()
            }
        }
        else {
            animations()
            completion(true)
        }
    }
}

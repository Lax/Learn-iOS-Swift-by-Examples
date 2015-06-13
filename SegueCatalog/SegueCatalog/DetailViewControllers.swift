/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view controllers used in the Detail storyboard.
*/

import UIKit

class NestedViewController: UIViewController {
    @IBAction func unwindToNested(segue: UIStoryboardSegue) {
        /* 
            Empty. Exists solely so that "unwind to nested" segues can find instances
            of this class.
        
            Notably, if an instance of this class is currently showing a Current
            Context presentation, unwinding to that instance via this action will
            only dismiss that presentation if the unwind source is contained within 
            the presentation.
        
            This is why the "Dismiss via Unwind" button in this app's storyboard
            will cause the containing presentation to be dismissed, while the "Unwind 
            to Nested" button will not.
        */
    }
}

class OuterViewController: UIViewController {
    @IBAction func unwindToOuter(segue: UIStoryboardSegue) {
        /*
            Empty. Exists solely so that "unwind to outer" segues can find 
            instances of this class.
        */
    }
}

class NonAnimatingSegue: UIStoryboardSegue {
    override func perform() {
        UIView.performWithoutAnimation {
            super.perform()
        }
    }
}

class CustomAnimationPresentationSegue: UIStoryboardSegue, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    
    override func perform() {
        /*
            Because this class is used for a Present Modally segue, UIKit will 
            maintain a strong reference to this segue object for the duration of
            the presentation. That way, this segue object will still be around to
            provide an animation controller for the eventual dismissal, as well 
            as for the initial presentation.
        */
        destinationViewController.transitioningDelegate = self

        super.perform()
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()!

        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        
        if transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) == destinationViewController {
            // Presenting.
            UIView.performWithoutAnimation {
                toView.alpha = 0
                containerView.addSubview(toView)
            }
            
            let transitionContextDuration = transitionDuration(transitionContext)
            
            UIView.animateWithDuration(transitionContextDuration, animations: {
                toView.alpha = 1
            }, completion: { success in
                transitionContext.completeTransition(success)
            })
        }
        else {
            // Dismissing.
            let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!

            UIView.performWithoutAnimation {
                containerView.insertSubview(toView, belowSubview: fromView)
            }
            
            let transitionContextDuration = transitionDuration(transitionContext)
            
            UIView.animateWithDuration(transitionContextDuration, animations: {
                fromView.alpha = 0
            }, completion: { success in
                transitionContext.completeTransition(success)
            })
        }
    }
}

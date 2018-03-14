/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	SimpleExampleViewController demonstrates how to use a view's size to determine an arrangement of its subviews. 
	 Also, it shows how to add an animation effect during app size changes.
 */

import UIKit

class SimpleExampleViewController: UIViewController {

    /// stackView is a UIStackView in our storyboard. It contains 3 views, one for each item.
    @IBOutlet var stackView : UIStackView!

    override func viewWillLayoutSubviews() {
        /*
            In viewWillLayoutSubviews, we are guaranteed that our view's size, traits, etc. are up to date.
            It's a good place to update anything that affects the layout of our subviews.
            However, be careful, because this method is called frequently!
            Do as little work as possible, and don't invalidate the layout of any superviews.
         */

        // Step 1: Find our size.
        let size = view.bounds.size

        // Step 2: Decide what design to use, based on our rules.
        let useWideDesign = size.width > size.height

        // Step 3: Apply the design to the UI.
        if useWideDesign {
            stackView.axis = .horizontal
        }
        else {
            stackView.axis = .vertical
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        /*
            We override viewWillTransition(to size: with coordinator:) in order to add special behavior
            when the app changes size, especially when the device is rotated.
            In this demo app, we add an effect to make the items "pop" towards the viewer during the rotation,
            and then go back to normal afterwards.
         */

        super.viewWillTransition(to: size, with: coordinator)

        // If self.stackView is nil, then our view has not yet been loaded, and there is nothing to do.
        guard let stackView = stackView else { return }

        // Add alongside and completion animations.
        coordinator.animate(alongsideTransition:
            { _ in
                /*
                    Scale the stackView to be larger than normal.
                    This animates along with the rest of the rotation animation.
                */
                stackView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
            },
                           completion:
            { _ in
                /*
                    The rotation animation is complete. Add an additional 0.5 second
                    animation to set the scale back to normal.
                */
                UIView.animate(withDuration: 0.5, animations: {
                    stackView.transform = CGAffineTransform.identity
                })
            }
        )
    }

}


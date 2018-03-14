/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	SmallElementViewController is contained within ExampleContainerViewController.
	 It shows a small version of the element. Tapping on it presents a LargeElementViewController which shows more details.
 */

import UIKit

class SmallElementViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
            `viewDidLoad()` is NOT the place to do everything.
            However, it is a good place to do work that does not depend on
            any other objects or views, and that will be the same no matter
            where this view controller is used.
            In this view controller, the following code qualifies:
        */

        // Add a constraint to make this view always square.
        let constraint = view.widthAnchor.constraint(equalTo: view.heightAnchor)
        constraint.isActive = true

        /*
            The SmallElementViewController is just a preview.
            Tap on our view to show the details in the LargeElementViewController.
         */
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapped))
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    func tapped(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            // Create the larger view controller:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let newElementViewController = storyboard.instantiateViewController(withIdentifier: "largeElement")

            /*
                And present it.
                We use the `.overFullScreen` presentation style so the ExampleContainerViewController
                underneath will go through the normal layout process, even while the presentation is active.
             */
            newElementViewController.modalPresentationStyle = .overFullScreen
            present(newElementViewController, animated: true, completion: nil)
        }
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        /*
            When we are removed from our parent view controller
            (which could happen when the parent changes to a different Design),
            if we presented the ElementViewController, then dismiss it.
         */
        if parent == nil && presentedViewController != nil {
            dismiss(animated: false, completion: nil)
        }
    }

}

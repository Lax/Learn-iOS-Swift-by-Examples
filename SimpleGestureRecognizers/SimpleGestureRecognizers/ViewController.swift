
/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:

View controller to manage interaction with a set of gesture recognizers.

*/


import UIKit
import Foundation

class ViewController : UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet var imageView: UIImageView
    @IBOutlet var segmentedControl: UISegmentedControl

    @IBOutlet var tapRecognizer: UITapGestureRecognizer
    @IBOutlet var swipeLeftRecognizer: UISwipeGestureRecognizer


    override func viewDidLoad() {

        super.viewDidLoad()

        if segmentedControl.selectedSegmentIndex == 0 {
            view.addGestureRecognizer(swipeLeftRecognizer)
        } else {
            view.removeGestureRecognizer(swipeLeftRecognizer)
        }

        // For illustrative purposes, set exclusive touch for the segmented control (see the ReadMe).
        segmentedControl.exclusiveTouch = true
    }


    /**
    Add or remove the left swipe recogniser to or from the view depending on the selection in the segmented control.
    */
    @IBAction func takeLeftSwipeRecognitionEnabledFrom(aSegmentedControl: UISegmentedControl) {

        if aSegmentedControl.selectedSegmentIndex == 0 {
            view.addGestureRecognizer(swipeLeftRecognizer)
        } else {
            view.removeGestureRecognizer(swipeLeftRecognizer)
        }
    }

    /**
    Disallow recognition of tap gestures in the segmented control.
    */
    func gestureRecognizer(recognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        if touch.view == segmentedControl && recognizer == tapRecognizer {
            return false
        }
        return true
    }


    /*
    Responding to gestures
    */

    /**
    In response to a tap gesture, show the image view appropriately then make it fade out in place.
    */
    @IBAction func showGestureForTapRecognizer(recognizer: UITapGestureRecognizer) {

        let location = recognizer.locationInView(view)

        drawImageForGestureRecognizer(recognizer, atPoint:location)

        UIView.animateWithDuration(0.24, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.imageView.alpha = 0.1
            },
            completion: {(finished: Bool) in
                UIView.animateWithDuration(0.06, animations: {
                    self.imageView.alpha = 0.0
                    })
            })
    }


    /**
    In response to a swipe gesture, show the image view appropriately then move the image view in the direction of the swipe as it fades out.
    */
    @IBAction func showGestureForSwipeRecognizer(recognizer: UISwipeGestureRecognizer) {

        var location = recognizer.locationInView(view)
        drawImageForGestureRecognizer(recognizer, atPoint: location)

        if recognizer.direction & .Left {
            location.x -= 220.0
        } else {
            location.x += 220.0
        }

        UIView.animateWithDuration(0.44, delay: 0, options: .CurveEaseOut, animations: {
            self.imageView.alpha = 0.1
            self.imageView.center = location
            },
            completion: {(finished: Bool) in
                UIView.animateWithDuration(0.06, animations: {
                    self.imageView.alpha = 0.0
                    })
            }
        )
    }


    /**
    In response to a rotation gesture, show the image view at the rotation given by the recognizer. At the end of the gesture, make the image fade out in place while rotating back to horizontal.
    */

    @IBAction func showGestureForRotationRecognizer(recognizer: UIRotationGestureRecognizer) {

        let location = recognizer.locationInView(view)

        imageView.transform = CGAffineTransformMakeRotation(recognizer.rotation)
        drawImageForGestureRecognizer(recognizer, atPoint: location)

        /*
        If the gesture has ended or is cancelled, begin the animation back to horizontal and fade out.
        */
        if recognizer.state == UIGestureRecognizerState.Ended || recognizer.state == UIGestureRecognizerState.Cancelled {

            UIView.animateWithDuration(0.44, delay: 0, options: .CurveEaseOut, animations: {
                self.imageView.transform = CGAffineTransformIdentity
                self.imageView.alpha = 0.1
                },
                completion: {(finished: Bool) in
                    UIView.animateWithDuration(0.06, animations: {
                        self.imageView.alpha = 0.0
                        })
                }
            )
        }
    }


    /*
    Drawing the image view
    */

    /**
    Set the appropriate image for the image view for the given gesture recognizer, move the image view to the given point, then dispay the image view by setting its alpha to 1.0.
    */
    func drawImageForGestureRecognizer(recognizer: UIGestureRecognizer, atPoint point: CGPoint) {

        var imageName: String

        switch recognizer {

        case is UITapGestureRecognizer:
            imageName = "tap.png"

        case is UIRotationGestureRecognizer:
            imageName = "rotation.png"

        case is UISwipeGestureRecognizer:
            imageName = "swipe.png"
            
        default:
            fatalError("Unexpected recognizer")
        }
        
        imageView.image = UIImage(named:imageName)
        imageView.center = point
        imageView.alpha = 1.0
    }
    
}


/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates different options for manipulating UIStackView content.
*/

import UIKit

class StackViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet var furtherDetailStackView: UIStackView!
    
    @IBOutlet var plusButton: UIButton!
    
    @IBOutlet var addRemoveExampleStackView: UIStackView!
    
    @IBOutlet var addArrangedViewButton: UIButton!
    
    @IBOutlet var removeArrangedViewButton: UIButton!
    
    let maximumArrangedSubviewCount = 3
    
    // MARK: View Life Cycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        furtherDetailStackView.hidden = true
        plusButton.hidden = false
        updateAddRemoveButtons()
    }
    
    // MARK: Actions
    
    @IBAction func showFurtherDetail(_: AnyObject) {
        // Animate the changes by performing them in a `UIView` animation block.
        UIView.animateWithDuration(0.25) {
            // Reveal the further details stack view and hide the plus button.
            self.furtherDetailStackView.hidden = false
            self.plusButton.hidden = true
        }
    }
    
    @IBAction func hideFurtherDetail(_: AnyObject) {
        // Animate the changes by performing them in a `UIView` animation block.
        UIView.animateWithDuration(0.25) {
            // Hide the further details stack view and reveal the plus button.
            self.furtherDetailStackView.hidden = true
            self.plusButton.hidden = false
        }
    }
    
    
    @IBAction func addArrangedSubviewToStack(_: AnyObject) {
        // Create a simple, fixed-size, square view to add to the stack view
        let newViewSize = CGSize(width: 50, height: 50)
        let newView = UIView(frame: CGRect(origin: CGPointZero, size: newViewSize))
        newView.backgroundColor = randomColor()
        newView.widthAnchor.constraintEqualToConstant(newViewSize.width).active = true
        newView.heightAnchor.constraintEqualToConstant(newViewSize.height).active = true
        
        /*
            Adding an arranged subview automatically adds it as a child of the
            stack view.
        */
        addRemoveExampleStackView.addArrangedSubview(newView)
        
        updateAddRemoveButtons()
    }
    
    @IBAction func removeArrangedSubviewFromStack(_: AnyObject) {
        // Make sure there is an arranged view to remove.
        guard let viewToRemove = addRemoveExampleStackView.arrangedSubviews.last else { return }

        addRemoveExampleStackView.removeArrangedSubview(viewToRemove)
        
        /*
            Calling `removeArrangedSubview` does not remove the provided view from
            the stack view's `subviews` array. Since we no longer want the view
            we removed to appear, we have to explicitly remove it from its superview.
        */
        viewToRemove.removeFromSuperview()
        
        updateAddRemoveButtons()
    }
    
    // MARK: Convenience
    
    private func updateAddRemoveButtons() {
        let arrangedSubviewCount = addRemoveExampleStackView.arrangedSubviews.count
        
        addArrangedViewButton.enabled = arrangedSubviewCount < maximumArrangedSubviewCount
        removeArrangedViewButton.enabled = arrangedSubviewCount > 0
    }
    
    private func randomColor() -> UIColor {
        let red = CGFloat(arc4random_uniform(255)) / 255.0
        let green = CGFloat(arc4random_uniform(255)) / 255.0
        let blue = CGFloat(arc4random_uniform(255)) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)

    }
}
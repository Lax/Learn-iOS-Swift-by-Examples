/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates different options for manipulating UIStackView content.
*/

import UIKit

class StackViewController: UIViewController {
    // MARK: - Properties
    
    @IBOutlet var furtherDetailStackView: UIStackView!
    
    @IBOutlet var plusButton: UIButton!
    
    @IBOutlet var addRemoveExampleStackView: UIStackView!
    
    @IBOutlet var addArrangedViewButton: UIButton!
    
    @IBOutlet var removeArrangedViewButton: UIButton!
    
    let maximumArrangedSubviewCount = 3
    
    // MARK: - View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        furtherDetailStackView.isHidden = true
        plusButton.isHidden = false
        updateAddRemoveButtons()
    }
    
    // MARK: - Actions
    
    @IBAction func showFurtherDetail(_: AnyObject) {
        // Animate the changes by performing them in a `UIView` animation block.
        UIView.animate(withDuration: 0.25, animations: {
            // Reveal the further details stack view and hide the plus button.
            self.furtherDetailStackView.isHidden = false
            self.plusButton.isHidden = true
        }) 
    }
    
    @IBAction func hideFurtherDetail(_: AnyObject) {
        // Animate the changes by performing them in a `UIView` animation block.
        UIView.animate(withDuration: 0.25, animations: {
            // Hide the further details stack view and reveal the plus button.
            self.furtherDetailStackView.isHidden = true
            self.plusButton.isHidden = false
        }) 
    }
    
    
    @IBAction func addArrangedSubviewToStack(_: AnyObject) {
        // Create a simple, fixed-size, square view to add to the stack view
        let newViewSize = CGSize(width: 50, height: 50)
        let newView = UIView(frame: CGRect(origin: CGPoint.zero, size: newViewSize))
        newView.backgroundColor = randomColor()
        newView.widthAnchor.constraint(equalToConstant: newViewSize.width).isActive = true
        newView.heightAnchor.constraint(equalToConstant: newViewSize.height).isActive = true
        
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
    
    // MARK: - Convenience
    
    fileprivate func updateAddRemoveButtons() {
        let arrangedSubviewCount = addRemoveExampleStackView.arrangedSubviews.count
        
        addArrangedViewButton.isEnabled = arrangedSubviewCount < maximumArrangedSubviewCount
        removeArrangedViewButton.isEnabled = arrangedSubviewCount > 0
    }
    
    fileprivate func randomColor() -> UIColor {
        let red = CGFloat(arc4random_uniform(255)) / 255.0
        let green = CGFloat(arc4random_uniform(255)) / 255.0
        let blue = CGFloat(arc4random_uniform(255)) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)

    }
}

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's detail view controller showing the accessibility examples.
*/

import Cocoa
import MediaLibrary

class DetailViewController: NSViewController {

    @IBOutlet var descriptionField: NSTextField!
    @IBOutlet var exampleArea: NSView!
    
    var detailItemRecord: Example! {
        didSet {
            // Remove the old child view controller, if any exists.
            if !childViewControllers.isEmpty {
                let vc = childViewControllers[0]
                vc.view.isHidden = true
                vc.removeFromParentViewController()
            }
            
            descriptionField.stringValue = ""
            
            guard detailItemRecord != nil else { return }
            
            // Update the description of the example.
            descriptionField.stringValue = detailItemRecord.desc
            
            // Check if this sample actually has a valid view controller to display.
            guard !detailItemRecord.viewControllerIdentifier.characters.isEmpty else { return }
            
            // Load the example storyboard and embed.
            let storyboard: NSStoryboard =
                NSStoryboard(name: NSStoryboard.Name(rawValue: detailItemRecord.viewControllerIdentifier), bundle: nil)

            let sceneIdentifier = NSStoryboard.SceneIdentifier(rawValue: detailItemRecord.viewControllerIdentifier)

            guard let buttonViewController =
                storyboard.instantiateController(withIdentifier: sceneIdentifier) as? NSViewController else { return }

            insertChildViewController(buttonViewController, at: 0)

            buttonViewController.view.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(buttonViewController.view)
            
            // Add the proper constraints to the detail view controller so it embeds properly with it's parent view controller.
            let top = NSLayoutConstraint(item: buttonViewController.view,
                                         attribute: .top,
                                         relatedBy: .equal,
                                         toItem: exampleArea,
                                         attribute: .top,
                                         multiplier: 1,
                                         constant: 0)
            let left = NSLayoutConstraint(item: buttonViewController.view,
                                          attribute: .left,
                                          relatedBy: .equal,
                                          toItem: exampleArea,
                                          attribute: .left,
                                          multiplier: 1,
                                          constant: 0)
            let height = NSLayoutConstraint(item: buttonViewController.view,
                                            attribute: .height,
                                            relatedBy: .equal,
                                            toItem: exampleArea,
                                            attribute: .height,
                                            multiplier: 1,
                                            constant: 0)
            let width = NSLayoutConstraint(item: buttonViewController.view,
                                           attribute: .width,
                                           relatedBy: .equal,
                                           toItem: exampleArea,
                                           attribute: .width,
                                           multiplier: 1,
                                           constant: 0)
            view.addConstraints([top, left, height, width])
        }
    }

}


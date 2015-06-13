/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Custom segue subclass to support the Form Sheet button.
*/

import UIKit

/**
    This segue subclass demonstrates how to adapt a view controller that has been
    modally presented by a segue. An instance of this segue is triggered by the 
    Form Sheet nav item owned by an OuterViewController. It is configured to show 
    a Form Sheet presentation, but Form Sheets are not permissible in Compact 
    size classes. By default, UIKit will adapt a Form Sheet presentation to a
    full-screen presentation, using the same view controller. We would like to 
    provide an alternative representation in the adapted case.
*/
class AdaptableFormSheetSegue: UIStoryboardSegue, UIAdaptivePresentationControllerDelegate {
    override func perform() {
        /*
            Because this class is used for a Present Modally segue, UIKit will 
            maintain a strong reference to this segue object for the duration of
            the presentation. That way, this segue object will live long enough 
            to act as the presentation controller's delegate and customize any 
            adaptation.
        */
        destinationViewController.presentationController?.delegate = self

        // Call super to get the standard modal presentation behavior.
        super.perform()
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return traitCollection.horizontalSizeClass == .Compact ? .FullScreen : .FormSheet
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        /*
            Load and return the adapted view controller from the Detail storyboard. 
            That storyboard is stored within the same bundle that contains this 
            class.
        */
        let adaptableFormSheetSegueBundle = NSBundle(forClass: AdaptableFormSheetSegue.self)
        
        return UIStoryboard(name: "Detail", bundle: adaptableFormSheetSegueBundle).instantiateViewControllerWithIdentifier("Adapted")
    }
}

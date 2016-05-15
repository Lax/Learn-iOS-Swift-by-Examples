/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the View Controller which manages our Shape Views when editing an individual document.
*/

import UIKit

/**
    The `DocumentViewController` handles opening / closing of our shape document
    as well as managing the UISegmentedControl for selecting new shapes.
*/

class DocumentViewController: UIViewController {
    // MARK: Properties

    var document: ShapeDocument!
    
    var documentURL: NSURL? {
        didSet {
            guard let url = documentURL else { return }

            document = ShapeDocument(fileURL: url)
            
            do {
                var displayName: AnyObject?
                try url.getPromisedItemResourceValue(&displayName, forKey: NSURLLocalizedNameKey)
                title = displayName as? String
            }
            catch {
                // Ignore a failure here. We'll just keep the old display name.
            }
        }
    }

    @IBOutlet var shapeView: ShapeView!
    
    @IBOutlet var shapeSelector: UISegmentedControl!
    
    @IBOutlet var progressView: UIProgressView!
    
    var documentObserver: NSObjectProtocol?

    // MARK: View Controller
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        shapeSelector.selectedSegmentIndex = UISegmentedControlNoSegment
        shapeSelector.userInteractionEnabled = false
        
        progressView.hidden = false
        
        documentObserver = NSNotificationCenter.defaultCenter().addObserverForName(UIDocumentStateChangedNotification, object: document, queue: nil) { _ in
            if self.document.documentState.contains(.ProgressAvailable) {
                self.progressView.observedProgress = self.document.progress
            }
        }

        
        document.openWithCompletionHandler { success in
            if success {
                self.updateView()
                
                guard let navigation = self.navigationController else {
                    return
                }
                
                guard let documentBrowserController = navigation.viewControllers.first as? DocumentBrowserController else {
                    return
                }

                documentBrowserController.documentWasOpenedSuccessfullyAtURL(self.document.fileURL)
            }
            else {
                let title = self.title!

                let alert = UIAlertController(title: "Unable to Load \"\(title)\"", message: "Opening the document failed", preferredStyle: .Alert)

                let alertAction = UIAlertAction(title: "Dismiss", style: .Default) { action in
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
                
                alert.addAction(alertAction)
                    
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
            if let observer = self.documentObserver {
                NSNotificationCenter.defaultCenter().removeObserver(observer)
                self.documentObserver = nil
            }
            
            self.progressView.hidden = true
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        document.closeWithCompletionHandler(nil)
    }
    
    private var segmentedControllerTintColor: UIColor {
        let originalColor = document.color
        
        var red:   CGFloat = 0
        var green: CGFloat = 0
        var blue:  CGFloat = 0
        originalColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        return UIColor(red: red * 0.7, green: green * 0.7, blue: blue * 0.7, alpha: 1)
    }

    @IBAction func shapeChanged(sender: UISegmentedControl?) {
        // The shape was modified using the shapeSelector, so save the selected value.
        let shapeRawValue = shapeSelector.selectedSegmentIndex
        
        guard let shape = ShapeDocument.Shape(rawValue: shapeRawValue) else { return }
        
        document.shape = shape
        document.updateChangeCount(.Done)
        
        shapeSelector.tintColor = segmentedControllerTintColor
        
        updateView()
    }

    func updateView() {
        // Update the selected segment to be what we loaded from disk.
        if let index = document.shape?.rawValue {
            shapeSelector.selectedSegmentIndex = index
            shapeSelector.userInteractionEnabled = true
        }
        else {
            shapeSelector.selectedSegmentIndex = UISegmentedControlNoSegment
        }
        
        shapeSelector.tintColor = segmentedControllerTintColor

        shapeView.document = document
    }
}

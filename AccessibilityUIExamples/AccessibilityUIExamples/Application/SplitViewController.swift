/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's split view managing both the master and detail view controllers.
*/

import Cocoa

class SplitViewController: NSSplitViewController, MasterViewControllerDelegate {
    
    var masterViewController: MasterViewController!
    var detailViewController: DetailViewController!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Note: we keep the left split view item from growing as the window grows by setting its hugging priority to 200,
        // and the right to 199. The view with the lowest priority will be the first to take on additional width if the
        // split view grows or shrinks.
        //
        splitView.adjustSubviews()
        
        masterViewController = splitViewItems[0].viewController as? MasterViewController
        masterViewController.delegate = self   // Listen for table view selection changes
        
        if let detailViewController = splitViewItems[1].viewController as? DetailViewController {
            self.detailViewController = detailViewController
        } else {
            fatalError("SplitViewController is not configured correctly.")
        }
        
        splitView.autosaveName = NSSplitView.AutosaveName(rawValue: "SplitViewAutoSave")   // Remember the split view position.
    }

    // MARK: - MasterViewControllerDelegate
    
    func didChangeExampleSelection(masterViewController: MasterViewController, selection: Example?) {
        detailViewController.detailItemRecord = selection
    }
}

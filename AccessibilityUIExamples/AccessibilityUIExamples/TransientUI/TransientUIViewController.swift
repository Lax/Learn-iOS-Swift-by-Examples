/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller demonstrating an accessible, custom NSView subclass that shows a hidden view on mouse over.
*/

import Cocoa

class TransientUIViewController: NSViewController {

    static let PageCount = 10
    
    var page = 0
    @IBOutlet var pageTextField: NSTextField!
    @IBOutlet var nextPageButton: NSButton!
    @IBOutlet var previousPageButton: NSButton!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePageTextView()
    }
    
    fileprivate func updateButtons() {
        let nextButtonEnabled = page < TransientUIViewController.PageCount - 1
        nextPageButton.isEnabled = nextButtonEnabled
        previousPageButton.isEnabled = page > 0
        
        if !nextButtonEnabled {
            let currentWindow = previousPageButton.window
            currentWindow?.makeFirstResponder(previousPageButton)
        }
    }
    
    fileprivate func updatePageTextView() {
        let formatter = NSLocalizedString("PageCountFormatter", comment: "page count formatter")
        let pageNumber = NumberFormatter.localizedString(from: NSNumber(value: page + 1),
                                                         number: NumberFormatter.Style.decimal)
        let pageCount = NumberFormatter.localizedString(from: NSNumber(value: TransientUIViewController.PageCount),
                                                        number: NumberFormatter.Style.decimal)
        pageTextField.stringValue = String(format: formatter, pageNumber, pageCount)
        updateButtons()
    }
    
    @IBAction func pressNextPageButton(_ sender: Any) {
        if page < TransientUIViewController.PageCount {
            page += 1
        }
        updatePageTextView()
    }
    
    @IBAction func pressPreviousPageButton(_ sender: Any) {
        if page > 0 {
            page -= 1
        }
        updatePageTextView()
    }
    
}


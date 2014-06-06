/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A view controller that demonstrates how to use UIWebView.
            
*/

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate, UITextFieldDelegate {
    // MARK: Properties
    
    @IBOutlet var webView: UIWebView
    @IBOutlet var addressTextField: UITextField

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureWebView()
        loadAddressURL()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        if UIApplication.sharedApplication().networkActivityIndicatorVisible {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }

    // MARK: Convenience

    func loadAddressURL() {
        let requestURL = NSURL(string: addressTextField.text)
        let request = NSURLRequest(URL: requestURL)
        webView.loadRequest(request)
    }

    // MARK: Configuration

    func configureWebView() {
        webView.backgroundColor = UIColor.whiteColor()
        webView.scalesPageToFit = true
        webView.dataDetectorTypes = .All
    }

    // MARK: UIWebViewDelegate

    func webViewDidStartLoad(_: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    func webViewDidFinishLoad(_: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        // Report the error inside the web view.
        let localizedErrorMessage = NSLocalizedString("An error occured:", comment: "")

        let errorHTML = "<!doctype html><html><body><div style=\"width: 100%%; text-align: center; font-size: 36pt;\">\(localizedErrorMessage) \(error.localizedDescription)</div></body></html>"

        webView.loadHTMLString(errorHTML, baseURL: nil)

        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    // MARK: UITextFieldDelegate

    // This helps dismiss the keyboard when the "Done" button is clicked.
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loadAddressURL()

        return true
    }
}

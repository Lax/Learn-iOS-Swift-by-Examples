/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UIWebView.
*/

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate, UITextFieldDelegate {
    // MARK: - Properties
    
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var addressTextField: UITextField!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureWebView()
        loadAddressURL()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    // MARK: - Convenience

    func loadAddressURL() {
        if let text = addressTextField.text, let requestURL = URL(string: text) {
            let request = URLRequest(url: requestURL)
            webView.loadRequest(request)
        }
    }

    // MARK: - Configuration

    func configureWebView() {
        webView.backgroundColor = UIColor.white
        webView.scalesPageToFit = true
        webView.dataDetectorTypes = .all
    }

    // MARK: - UIWebViewDelegate

    func webViewDidStartLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        // Report the error inside the web view.
        let localizedErrorMessage = NSLocalizedString("An error occured:", comment: "")

        let errorHTML = "<!doctype html><html><body><div style=\"width: 100%%; text-align: center; font-size: 36pt;\">\(localizedErrorMessage) \(error.localizedDescription)</div></body></html>"

        webView.loadHTMLString(errorHTML, baseURL: nil)

        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    // MARK: - UITextFieldDelegate

    /// Dismisses the keyboard when the "Done" button is clicked.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        loadAddressURL()

        return true
    }
}

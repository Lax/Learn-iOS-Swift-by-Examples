/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UIWebView.
*/

#import "AAPLWebViewController.h"

@interface AAPLWebViewController()<UIWebViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UITextField *addressTextField;

@end


#pragma mark -

@implementation AAPLWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureWebView];
    [self loadAddressURL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)loadAddressURL {
    NSURL *requestURL = [NSURL URLWithString:self.addressTextField.text];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    [self.webView loadRequest:request];
}


#pragma mark - Configuration

- (void)configureWebView {
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.scalesPageToFit = YES;
    self.webView.dataDetectorTypes = UIDataDetectorTypeAll;
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // Report the error inside the web view.
    NSString *localizedErrorMessage = NSLocalizedString(@"An error occured:", nil);
    NSString *errorFormatString = @"<!doctype html><html><body><div style=\"width: 100%%; text-align: center; font-size: 36pt;\">%@%@</div></body></html>";

    NSString *errorHTML = [NSString stringWithFormat:errorFormatString, localizedErrorMessage, error.localizedDescription];
    [self.webView loadHTMLString:errorHTML baseURL:nil];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


#pragma mark - UITextFieldDelegate

// This helps dismiss the keyboard when the "Done" button is clicked.
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    [self loadAddressURL];
    
    return YES;
}

@end

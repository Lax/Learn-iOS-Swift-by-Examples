/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UIActivityIndicatorView.
*/

#import "AAPLActivityIndicatorViewController.h"

@interface AAPLActivityIndicatorViewController()

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *grayStyleActivityIndicatorView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *tintedActivityIndicatorView;

@end


#pragma mark -

@implementation AAPLActivityIndicatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureGrayActivityIndicatorView];
    [self configureTintedActivityIndicatorView];

    // When activity is done, use -[UIActivityIndicatorView stopAnimating].
}


#pragma mark - Configuration

- (void)configureGrayActivityIndicatorView {
    self.grayStyleActivityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;

    [self.grayStyleActivityIndicatorView startAnimating];
    
    self.grayStyleActivityIndicatorView.hidesWhenStopped = YES;
}

- (void)configureTintedActivityIndicatorView {
    self.tintedActivityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;

    self.tintedActivityIndicatorView.color = [UIColor aapl_applicationPurpleColor];

    [self.tintedActivityIndicatorView startAnimating];
}

@end

/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to tint a UIToolbar.
*/

#import "AAPLTintedToolbarViewController.h"

@interface AAPLTintedToolbarViewController()

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@end


#pragma mark -

@implementation AAPLTintedToolbarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureToolbar];
}


#pragma mark - Configuration

- (void)configureToolbar {
    // See the UIBarStyle enum for more styles, including UIBarStyleDefault.
    self.toolbar.barStyle = UIBarStyleBlackTranslucent;

    self.toolbar.tintColor = [UIColor aapl_applicationGreenColor];
    self.toolbar.backgroundColor = [UIColor aapl_applicationBlueColor];
    
    NSArray *toolbarButtonItems = @[[self refreshBarButtonItem], [self flexibleSpaceBarButtonItem], [self actionBarButtonItem]];
    [self.toolbar setItems:toolbarButtonItems animated:YES];
}


#pragma mark - UIBarButtonItem Creation and Configuration

- (UIBarButtonItem *)refreshBarButtonItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(barButtonItemClicked:)];
}

- (UIBarButtonItem *)flexibleSpaceBarButtonItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
}

- (UIBarButtonItem *)actionBarButtonItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(barButtonItemClicked:)];
}


#pragma mark - Actions

- (void)barButtonItemClicked:(UIBarButtonItem *)barButtonItem {
    NSLog(@"A bar button item on the tinted toolbar was clicked: %@.", barButtonItem);
}

@end

/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use a default UIToolbar.
*/

#import "AAPLDefaultToolbarViewController.h"

@interface AAPLDefaultToolbarViewController()

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@end


#pragma mark -

@implementation AAPLDefaultToolbarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureToolbar];
}


#pragma mark - Configuration

- (void)configureToolbar {
    NSArray *toolbarButtonItems = @[[self trashBarButtonItem], [self flexibleSpaceBarButtonItem], [self customTitleBarButtonItem]];
    [self.toolbar setItems:toolbarButtonItems animated:YES];
}


#pragma mark - UIBarButtonItem Creation and Configuration

- (UIBarButtonItem *)trashBarButtonItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(barButtonItemClicked:)];
}

- (UIBarButtonItem *)flexibleSpaceBarButtonItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
}

- (UIBarButtonItem *)customTitleBarButtonItem {
    NSString *customTitle = NSLocalizedString(@"Action", nil);

    return [[UIBarButtonItem alloc] initWithTitle:customTitle style:UIBarButtonItemStylePlain target:self action:@selector(barButtonItemClicked:)];
}


#pragma mark - Actions

- (void)barButtonItemClicked:(UIBarButtonItem *)barButtonItem {
    NSLog(@"A bar button item on the default toolbar was clicked: %@.", barButtonItem);
}

@end

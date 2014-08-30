/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to customize a UIToolbar.
*/

#import "AAPLCustomToolbarViewController.h"

@interface AAPLCustomToolbarViewController()

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@end


#pragma mark -

@implementation AAPLCustomToolbarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureToolbar];
}


#pragma mark - Configuration

- (void)configureToolbar {
    UIImage *toolbarBackgroundImage = [UIImage imageNamed:@"toolbar_background"];
    [self.toolbar setBackgroundImage:toolbarBackgroundImage forToolbarPosition:UIBarPositionBottom barMetrics:UIBarMetricsDefault];

    NSArray *toolbarButtonItems = @[[self customImageBarButtonItem], [self flexibleSpaceBarButtonItem], [self customBarButtonItem]];
    [self.toolbar setItems:toolbarButtonItems animated:YES];
}


#pragma mark - UIBarButtonItem Creation and Configuration

- (UIBarButtonItem *)customImageBarButtonItem {
    UIImage *customBarButtonItemImage = [UIImage imageNamed:@"tools_icon"];
    UIBarButtonItem *customImageBarButtonItem = [[UIBarButtonItem alloc] initWithImage:customBarButtonItemImage style:UIBarButtonItemStylePlain target:self action:@selector(barButtonItemClicked:)];

    customImageBarButtonItem.tintColor = [UIColor aapl_applicationPurpleColor];

    return customImageBarButtonItem;
}

- (UIBarButtonItem *)flexibleSpaceBarButtonItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
}

- (UIBarButtonItem *)customBarButtonItem {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Button", nil) style:UIBarButtonItemStylePlain target:self action:@selector(barButtonItemClicked:)];

    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [UIColor aapl_applicationPurpleColor]
    };
    [barButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];

    return barButtonItem;
}


#pragma mark - Actions

- (void)barButtonItemClicked:(UIBarButtonItem *)barButtonItem {
    NSLog(@"A bar button item on the custom toolbar was clicked: %@.", barButtonItem);
}

@end

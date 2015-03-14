/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UIPageControl.
*/

#import "AAPLPageControlViewController.h"

@interface AAPLPageControlViewController ()

@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;

@property (nonatomic, weak) IBOutlet UIView *colorView;
@property (nonatomic, strong) NSArray *colors;

@end


#pragma mark -

@implementation AAPLPageControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set a list of colors that correspond to the selected page.
    self.colors = @[[UIColor blackColor], [UIColor grayColor], [UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor cyanColor], [UIColor yellowColor], [UIColor magentaColor], [UIColor orangeColor], [UIColor purpleColor]];

    [self configurePageControl];
    [self pageControlValueDidChange];
}


#pragma mark - Configuration

- (void)configurePageControl {
    // The total number of pages that are available is based on how many available colors we have.
    self.pageControl.numberOfPages = [self.colors count];
    self.pageControl.currentPage = 2;

    self.pageControl.tintColor = [UIColor aapl_applicationBlueColor];
    self.pageControl.pageIndicatorTintColor = [UIColor aapl_applicationGreenColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor aapl_applicationPurpleColor];

    [self.pageControl addTarget:self action:@selector(pageControlValueDidChange) forControlEvents:UIControlEventValueChanged];
}


#pragma mark - Actions

- (void)pageControlValueDidChange {
    NSLog(@"The page control changed its current page to %ld.", (long)self.pageControl.currentPage);

    self.colorView.backgroundColor = self.colors[self.pageControl.currentPage];
}

@end

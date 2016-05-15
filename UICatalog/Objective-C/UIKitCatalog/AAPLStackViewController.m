/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates different options for manipulating UIStackView content.
*/

#import "AAPLStackViewController.h"

static NSInteger AAPLStackViewControllerMaxArrangedSubviewsCount = 3;

@interface AAPLStackViewController ()

@property (nonatomic, weak) IBOutlet UIStackView *furtherDetailStackView;
@property (nonatomic, weak) IBOutlet UIButton *plusButton;
@property (nonatomic, weak) IBOutlet UIStackView *addRemoveExampleStackView;
@property (nonatomic, weak) IBOutlet UIButton *addArrangedViewButton;
@property (nonatomic, weak) IBOutlet UIButton *removeArrangedViewButton;

@end


#pragma mark -

@implementation AAPLStackViewController

#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.furtherDetailStackView.hidden = YES;
    self.plusButton.hidden = NO;
    [self updateAddRemoveButtons];
}

#pragma mark - Actions

- (IBAction)showFurtherDetailTapped:(UIButton *)sender {
    // Animate the changes by performing them in a `UIView` animation block.
    [UIView animateWithDuration:0.25 animations:^{
        // Reveal the further details stack view and hide the plus button.
        self.furtherDetailStackView.hidden = NO;
        self.plusButton.hidden = YES;
    }];
}

- (IBAction)hideFurtherDetailTapped:(UIButton *)sender {
    // Animate the changes by performing them in a `UIView` animation block.
    [UIView animateWithDuration:0.25 animations:^{
        // Hide the further details stack view and reveal the plus button.
        self.furtherDetailStackView.hidden = YES;
        self.plusButton.hidden = NO;
    }];
}

- (IBAction)addArrangedSubviewToStackTapped:(UIButton *)sender {
    // Create a simple, fixed-size, square view to add to the stack view
    CGSize newViewSize = CGSizeMake(50, 50);
    UIView *newView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, newViewSize.width, newViewSize.height)];
    newView.backgroundColor = [self randomColor];
    [newView.widthAnchor constraintEqualToConstant:newViewSize.width].active = YES;
    [newView.heightAnchor constraintEqualToConstant:newViewSize.height].active = YES;
    
    // Adding an arranged subview automatically adds it as a child of the stack view.
    [self.addRemoveExampleStackView addArrangedSubview:newView];
    
    [self updateAddRemoveButtons];
}

- (IBAction)removeArrangedSubviewFromStackTapped:(UIButton *)sender {
    // Make sure there is an arranged view to remove.
    UIView *viewToRemove = [self.addRemoveExampleStackView.arrangedSubviews lastObject];
    if (viewToRemove == nil) {
        return;
    }
    
    [self.addRemoveExampleStackView removeArrangedSubview:viewToRemove];
    
    /*
     Calling `removeArrangedSubview` does not remove the provided view from the
     stack view's `subviews` array. Since we no longer want the view we removed
     to appear, we have to explicitly remove it from its superview.
     */
    [viewToRemove removeFromSuperview];
    
    [self updateAddRemoveButtons];
}

#pragma mark - Convenience

- (void)updateAddRemoveButtons {
    NSInteger arrangedSubviewCount = self.addRemoveExampleStackView.arrangedSubviews.count;
    
    self.addArrangedViewButton.enabled = arrangedSubviewCount < AAPLStackViewControllerMaxArrangedSubviewsCount;
    self.removeArrangedViewButton.enabled = arrangedSubviewCount > 0;
}

- (UIColor*)randomColor {
    CGFloat red = (CGFloat)arc4random_uniform(255) / 255.0;
    CGFloat green = (CGFloat)arc4random_uniform(255) / 255.0;
    CGFloat blue = (CGFloat)arc4random_uniform(255) / 255.0;
    
    return [[UIColor alloc] initWithRed:red green:green blue:blue alpha:1.0];
}

@end
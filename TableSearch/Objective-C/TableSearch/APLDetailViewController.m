/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The detail view controller navigated to from our main and results table.
 */

#import "APLDetailViewController.h"
#import "APLProduct.h"

@interface APLDetailViewController ()

@property (nonatomic, weak) IBOutlet UILabel *yearLabel;
@property (nonatomic, weak) IBOutlet UILabel *priceLabel;

@end


#pragma mark -

@implementation APLDetailViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = self.product.title;
    
    self.yearLabel.text = (self.product.yearIntroduced).stringValue;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    NSString *priceString = [numberFormatter stringFromNumber:self.product.introPrice];
    self.priceLabel.text = priceString;
}


#pragma mark - UIStateRestoration

NSString *const ViewControllerProductKey = @"ViewControllerProductKey";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    // encode the product
    [coder encodeObject:self.product forKey:ViewControllerProductKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    // restore the product
    self.product = [coder decodeObjectForKey:ViewControllerProductKey];
}

@end




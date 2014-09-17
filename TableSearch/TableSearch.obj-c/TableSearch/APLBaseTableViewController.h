/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Base or common view controller to share a common UITableViewCell prototype between subclasses.
  
 */

#import <UIKit/UIKit.h>

@class APLProduct;

static NSString * const kCellIdentifier = @"cellID";

@interface APLBaseTableViewController : UITableViewController

- (void)configureCell:(UITableViewCell *)cell forProduct:(APLProduct *)product;

@end

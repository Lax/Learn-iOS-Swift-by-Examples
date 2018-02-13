/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The table view controller responsible for displaying the filtered products as the user types in the search field.
 */

#import "APLBaseTableViewController.h"

@interface APLResultsTableController : APLBaseTableViewController

@property (nonatomic, strong) NSArray *filteredProducts;

@end

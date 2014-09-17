/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The detail view controller navigated to from our main and results table.
  
 */

#import <UIKit/UIKit.h>

@class APLProduct;

@interface APLDetailViewController : UIViewController

@property (nonatomic, strong) APLProduct *product;

@end

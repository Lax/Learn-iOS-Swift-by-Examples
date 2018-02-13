/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:

Lists the values for all the properties of a single CLLocation object.

*/

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationDetailViewController : UITableViewController

@property (nonatomic, strong) CLLocation *location;

@end

/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Lists all songs in a table view. Also allows sorting and grouping via bottom segmented control.
 */

@import UIKit;

@interface SongsViewController : UITableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)fetch;

@end

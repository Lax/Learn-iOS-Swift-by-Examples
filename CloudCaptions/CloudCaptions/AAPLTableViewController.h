/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Downloads the post and Image records as needed while the user scrolls
  Creates the AAPLPostTableViewCells to display the downloaded information
  
 */

@import UIKit;
#import "AAPLExistingImageViewController.h"
#import "AAPLSubmitPostViewController.h"

@class AAPLPost;

@interface AAPLTableViewController : UITableViewController

- (void) loadNewPostsWithRecordID:(CKRecordID *)recordID;

@end


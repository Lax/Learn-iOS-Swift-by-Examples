/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Custom UITableViewCell used to display the post information
  
 */

@import UIKit;
@class AAPLPost;

@interface AAPLPostTableViewCell : UITableViewCell

- (void) displayInfoForPost:(AAPLPost *)post;

@end

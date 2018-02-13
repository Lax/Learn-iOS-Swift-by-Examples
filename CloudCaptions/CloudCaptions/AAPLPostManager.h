/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Used by AAPLTableViewController to retrieve remote posts and stitch local posts into the tableview
  
 */

#define updateBy 10

@import Foundation;
@import UIKit;

@class AAPLPost;

@interface AAPLPostManager : NSObject

@property (strong, atomic) NSMutableArray *postCells;
@property (weak, atomic) UIRefreshControl *refreshControl;

- (instancetype) initWithReloadHandler:(void(^)(void))reload NS_DESIGNATED_INITIALIZER;
- (void) loadNewPostsWithAAPLPost:(AAPLPost *)post;
- (void) loadNewPosts;
- (void) loadBatch;
- (void) resetWithTagString:(NSString *)tags;

@end

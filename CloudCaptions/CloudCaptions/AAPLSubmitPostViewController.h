/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
 View controller responsible for creating a post record and uploading it along with the Image record in the AAPLImage that was passed in
  
 */

#import "AAPLPost.h"
@import UIKit;

@interface AAPLSubmitPostViewController : UIViewController

@property (weak, atomic) id delegate;

@end

@protocol AAPLSubmitPostViewControllerDelegate <NSObject>

@optional
- (void) AAPLSubmitPostViewController:(AAPLSubmitPostViewController *)controller postedRecord:(AAPLPost *)record;

@end

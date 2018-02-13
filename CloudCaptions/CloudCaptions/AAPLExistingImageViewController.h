/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Responsible for downloading the Image records and sending them to the AAPLExistingImageCollectionView
  Passes the selected AAPLImage to the AAPLTableViewController
  
 */

@import UIKit;
@import CloudKit;

@class AAPLImage;

@interface AAPLExistingImageViewController : UIViewController

@property (weak, atomic) id delegate;

@end

// Delegate with method that returns the selected AAPLImage
@protocol AAPLExistingImageViewControllerDelegate <NSObject>

@optional
- (void) AAPLExisitingImageViewController:(AAPLExistingImageViewController *)controller selectedImage:(AAPLImage *)image;

@end

/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
 Custom collection view cell object used to display the thumbnail for the AAPLImage assigned to it
  
 */

@import UIKit;
#import "AAPLImage.h"

@interface AAPLExistingImageCollectionViewCell : UICollectionViewCell

@property (strong, atomic) IBOutlet UIImageView *thumbnailImage;
- (void) setLoading:(BOOL)loading;

@end

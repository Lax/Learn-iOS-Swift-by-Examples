/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Collection view that creates an AAPLExistingImageCollectionViewCell for each record added to its imageRecords array
  
  
 */

@import CloudKit;
@import UIKit;

@interface AAPLExistingImageCollectionView : UICollectionView <UICollectionViewDataSource>

@property (nonatomic, readonly) NSUInteger count;
- (void) addImageFromRecord:(CKRecord *)toAdd;
- (CKRecordID *) getRecordIDAtIndex:(NSIndexPath *)index;
- (void) cellAtIndex:(NSIndexPath *)index isLoading:(BOOL)loading;

@end

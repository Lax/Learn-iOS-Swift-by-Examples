/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLExistingImageCollectionView.h"
#import "AAPLExistingImageCollectionViewCell.h"
#import "AAPLImage.h"

static NSString * const cellReuseIdentifier = @"imageCell";

@interface AAPLExistingImageCollectionView()

@property (strong, atomic) NSMutableArray *imageRecords;
@property (strong, atomic) dispatch_queue_t updateArrayQueue;
@property (strong, atomic) NSIndexPath *currentLoadingIndex;

@end


#pragma mark -

@implementation AAPLExistingImageCollectionView

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        self.dataSource = self;
        _imageRecords = [[NSMutableArray alloc] init];
        _updateArrayQueue = dispatch_queue_create("UpdateCollectionViewQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSUInteger) count
{
    return [self.imageRecords count];
}

- (void) addImageFromRecord:(CKRecord *)toAdd
{
    AAPLImage *fetchedImage = [[AAPLImage alloc] initWithRecord:toAdd];
    // Ensures that only one object will be added to the imageRecords array at a time
    dispatch_async(self.updateArrayQueue, ^{
        [self.imageRecords addObject:fetchedImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
        });
    });
}

- (void) cellAtIndex:(NSIndexPath *)index isLoading:(BOOL)loading
{
    if(loading == YES) self.currentLoadingIndex = index;
    else self.currentLoadingIndex = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
    });
}

- (CKRecordID *) getRecordIDAtIndex:(NSIndexPath *)index
{
    // returns the recordID of the item in imageRecords at the given index
    AAPLImage *AAPLImageAtIndex = self.imageRecords[index.row];
    return [[AAPLImageAtIndex record] recordID];
}

#pragma mark UICollectionViewDataSource
- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.imageRecords count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (AAPLExistingImageCollectionViewCell *) collectionView:(AAPLExistingImageCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AAPLExistingImageCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil)
    {
        cell = [[AAPLExistingImageCollectionViewCell alloc] init];
    }
    cell.thumbnailImage.image = [self.imageRecords[indexPath.row] thumbnail];
    if(indexPath && [indexPath isEqual:self.currentLoadingIndex]) [cell setLoading:YES];
    else [cell setLoading:NO];
    
    return cell;
}

@end

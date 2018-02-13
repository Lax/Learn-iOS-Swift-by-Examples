/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

@import CloudKit;
#import "AAPLExistingImageViewController.h"
#import "AAPLExistingImageCollectionView.h"
#import "AAPLImage.h"

typedef NS_ENUM(NSInteger, AAPLExistingImageErrorResponse) {
    AAPLExistingImageErrorIgnore,
    AAPLExistingImageErrorRetry,
    AAPLExistingImageErrorSuccess,
};

// This constant determines the number of images to fetch at a time
#define updateBy 24

@interface AAPLExistingImageViewController () <UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet AAPLExistingImageCollectionView *imageCollection;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingImages;
@property (strong, atomic) CKQueryCursor *imageCursor;
@property BOOL isLoadingBatch; // Boolean value used to prevent multiple loadImages methods running
@property BOOL firstThumbnailLoaded; // Boolean value used to permanently lock loadImages when we've grabbed the earliest image
@property BOOL lockSelectThumbnail; // Only lets user select one image at a time

@end


#pragma mark -

@implementation AAPLExistingImageViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.imageCollection.delegate = self;
    self.isLoadingBatch = NO;
    self.firstThumbnailLoaded = NO;
    self.lockSelectThumbnail = NO;
    
    // This ensures that there are always three images per row whether it's an iPhone or an iPad (20 px subtracted to account for four 5 px spaces between thumbnails)
    double smallerDimension = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);   // Works even if iPad is rotated
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *) self.imageCollection.collectionViewLayout;
    double imageWidth = (smallerDimension - 20) / 3;
    flowLayout.itemSize = CGSizeMake(imageWidth, imageWidth);
    
    [self loadImages];
}

- (void) loadImages
{
    // If we're already loading a set of images or there are no images left to load, just return
    @synchronized(self)
    {
        if (self.isLoadingBatch || self.firstThumbnailLoaded) return;
        else self.isLoadingBatch = YES;
    }
    
    // If we have a cursor, continue where we left off, otherwise set up new query
    CKQueryOperation *queryOp = nil; 
    if(self.imageCursor)
    {
        queryOp = [[CKQueryOperation alloc] initWithCursor:self.imageCursor];
    }
    else
    {
        CKQuery *thumbnailQuery = [[CKQuery alloc] initWithRecordType:AAPLImageRecordType predicate:[NSPredicate predicateWithValue:YES]];
        thumbnailQuery.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        queryOp = [[CKQueryOperation alloc] initWithQuery:thumbnailQuery];
    }
    
    // We only want to download the thumbnails, not the full image
    queryOp.desiredKeys = @[AAPLImageThumbnailKey];
    queryOp.resultsLimit = updateBy;
    queryOp.recordFetchedBlock = ^(CKRecord *record) {
        [self.imageCollection addImageFromRecord:record];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loadingImages stopAnimating];
            [self.imageCollection reloadData];
        });
    };
    queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        AAPLExistingImageErrorResponse errorResponse = [self handleError:error];
        
        if(errorResponse == AAPLExistingImageErrorSuccess)
        {
            self.imageCursor = cursor;
            self.isLoadingBatch = NO;
            if (cursor == nil) {
                self.firstThumbnailLoaded = YES; // If cursor is nil, lock this method indefinitely (all images have been loaded)
            }
        }
        else if(errorResponse == AAPLExistingImageErrorRetry)
        {
            // If there's no specific number of seconds we're told to wait, default to 3
            NSNumber *retryAfter = error.userInfo[CKErrorRetryAfterKey] ?: @3;
            NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [error description], retryAfter);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.intValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // Resets so we can load images again and then goes to load
                self.isLoadingBatch = NO;
                [self loadImages];
            });
        }
        else if(errorResponse == AAPLExistingImageErrorIgnore)
        {
            // If we get an ignore error they're not often recoverable. I'll leave loadImages locked indefinitely (this is up to the developer)
            NSLog(@"Error: %@", [error description]);
            NSString *errorTitle = NSLocalizedString(@"ErrorTitle", @"Title of alert notifying of error");
            NSString *dismissButton = NSLocalizedString(@"DismissError", @"Alert dismiss button string");
            NSString *errorMessage = NSLocalizedString(@"ThumbnailErrorMessage", @"Error message when a thumbnail isn't loaded");
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:dismissButton style:UIAlertActionStyleCancel handler:nil]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    };
    [[CKContainer defaultContainer].publicCloudDatabase addOperation:queryOp];
}

- (AAPLExistingImageErrorResponse) handleError:(NSError *)error
{
    if (error == nil) {
        return AAPLExistingImageErrorSuccess;
    }
    switch ([error code])
    {
        case CKErrorNetworkUnavailable:
        case CKErrorNetworkFailure:
            // A reachability check might be appropriate here so we don't just keep retrying if the user has no service
        case CKErrorServiceUnavailable:
        case CKErrorRequestRateLimited:
            return AAPLExistingImageErrorRetry;
            break;
            
        case CKErrorUnknownItem:
            NSLog(@"If an image has never been uploaded, CKErrorUnknownItem will be returned in AAPLExistingImageViewController because it has never seen the Image record type");
            return AAPLExistingImageErrorIgnore;
            break;
        case CKErrorInvalidArguments:
            NSLog(@"If invalid arguments is returned in AAPLExistingImageViewController with a message about not being marked indexable or sortable, go into CloudKit dashboard and set the Image record type as sortable on date created");
            return AAPLExistingImageErrorIgnore;
            break;
        case CKErrorIncompatibleVersion:
        case CKErrorBadContainer:
        case CKErrorMissingEntitlement:
        case CKErrorPermissionFailure:
        case CKErrorBadDatabase:
            // This app uses the publicDB with default world readable permissions
        case CKErrorAssetFileNotFound:
        case CKErrorQuotaExceeded:
            // We should not retry if it'll exceed our quota
        case CKErrorOperationCancelled:
            // Nothing to do here, we intentionally cancelled
        case CKErrorNotAuthenticated:
        case CKErrorResultsTruncated:
        case CKErrorServerRecordChanged:
        case CKErrorAssetFileModified:
        case CKErrorChangeTokenExpired:
        case CKErrorBatchRequestFailed:
        case CKErrorZoneBusy:
        case CKErrorZoneNotFound:
        case CKErrorLimitExceeded:
        case CKErrorUserDeletedZone:
            // All of these errors are irrelevant for this query operation
        case CKErrorInternalError:
        case CKErrorServerRejectedRequest:
        case CKErrorConstraintViolation:
            //Non-recoverable, should not retry
        default:
            return AAPLExistingImageErrorIgnore;
            break;
    }
}

- (IBAction) cancelSelection:(id)sender {
    // If cancel is pressed, dismiss the selection view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIScrollViewDelegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Gets the point at the bottom of the scroll view
    CGPoint bottomRowPoint = CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y + scrollView.bounds.size.height);
    
    // Finds number of rows left (gets height of row and adds 5 px spacing between rows)
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *) self.imageCollection.collectionViewLayout;
    double rowHeight = flowLayout.itemSize.height;
    double rowSpacing = flowLayout.minimumLineSpacing;
    int rowsLeft = (scrollView.contentSize.height - bottomRowPoint.y) / (rowHeight + rowSpacing);
    
    // If we have less five rows left, load the next set
    if(rowsLeft < 5) [self loadImages];
}

#pragma mark UICollectionViewDelegate

// This method fetches the whole ImageRecord that a user taps on and then passes it to the delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // If the user has already tapped on a thumbnail, prevent them from tapping any others
    if(self.lockSelectThumbnail) return;
    else self.lockSelectThumbnail = YES;
    
    // Starts animating the thumbnail to indicate it is loading
    [self.imageCollection cellAtIndex:indexPath isLoading:YES];
    
    // Uses convenience API to fetch the whole image record associated with the thumbnail that was tapped
    CKRecordID *userSelectedRecordID = [self.imageCollection getRecordIDAtIndex:indexPath];
    [[CKContainer defaultContainer].publicCloudDatabase fetchRecordWithID:userSelectedRecordID completionHandler:^(CKRecord *record, NSError *error) {
        // If we get a partial failure, we should unwrap it
        if(error.code == CKErrorPartialFailure) {
            error = error.userInfo[CKPartialErrorsByItemIDKey][userSelectedRecordID];
        }
        AAPLExistingImageErrorResponse errorResponse = [self handleError:error];
        
        if(errorResponse == AAPLExistingImageErrorSuccess &&
           [self.delegate respondsToSelector:@selector(AAPLExisitingImageViewController:selectedImage:)])
        {
            [self.imageCollection cellAtIndex:indexPath isLoading:NO];
            AAPLImage *selectedImage = [[AAPLImage alloc] initWithRecord:record];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate AAPLExisitingImageViewController:self selectedImage:selectedImage];
            });
        }
        else if(errorResponse == AAPLExistingImageErrorRetry)
        {
            NSNumber *retryAfter = error.userInfo[CKErrorRetryAfterKey] ?: @3;
            NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [error description], retryAfter);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.intValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.lockSelectThumbnail = NO;
                [self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
            });
        }
        else if(errorResponse == AAPLExistingImageErrorIgnore)
        {
            NSLog(@"Error: %@", [error description]);
            NSString *errorTitle = NSLocalizedString(@"ErrorTitle", @"Title of alert notifying of error");
            NSString *errorMessage = NSLocalizedString(@"FetchFullFromThumbErrorMessage", @"Error message when a full size isn't loaded from thumbnail");
            NSString *dismissButton = NSLocalizedString(@"DismissError", @"Alert dismiss button string");
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:dismissButton style:UIAlertActionStyleCancel handler:nil]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
            [self.imageCollection cellAtIndex:indexPath isLoading:NO];
            self.lockSelectThumbnail = NO;
        }
    }];
}

@end

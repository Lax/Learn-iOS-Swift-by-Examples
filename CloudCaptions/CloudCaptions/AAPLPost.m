/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

@import CloudKit;
#import "AAPLPost.h"
#import "AAPLImage.h"

typedef NS_ENUM(NSInteger, AAPLPostErrorResponse) {
    AAPLPostErrorIgnore,
    AAPLPostErrorRetry,
    AAPLPostErrorSuccess,
};

@implementation AAPLPost

- (instancetype) initWithRecord:(CKRecord *)postRecord
{
    self = [super init];
    if(self)
    {
        _postRecord = postRecord;
    }
    return self;
}

- (void) loadImageWithKeys:(NSArray *)keys completion:(void(^)())updateBlock
{
    // Fetches the imageRecord this post record references in its ImageRefKey. Only fetches the values associated with the keys passed in to the NSArray
    CKReference *imageRecordReference = self.postRecord[AAPLPostImageRefKey];
    CKFetchRecordsOperation *imageOp = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[imageRecordReference.recordID]];
    imageOp.desiredKeys = keys;
    imageOp.fetchRecordsCompletionBlock = ^(NSDictionary *recordDict, NSError *error) {
        if(error.code == CKErrorPartialFailure) {
            error = error.userInfo[CKPartialErrorsByItemIDKey][[self.postRecord[AAPLPostImageRefKey] recordID]];
        }
        AAPLPostErrorResponse errorResponse = [self handleError:error];
        
        if(errorResponse == AAPLPostErrorSuccess)
        {
            CKRecord *fetchedImageRecord = recordDict[imageRecordReference.recordID];
            self.imageRecord = [[AAPLImage alloc] initWithRecord:fetchedImageRecord];
            updateBlock();
        }
        else if(errorResponse == AAPLPostErrorRetry)
        {
            NSNumber *seconds = error.userInfo[CKErrorRetryAfterKey] ?: @3;
            NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [error description], seconds);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds.integerValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self loadImageWithKeys:keys completion:updateBlock];
            });
            self.imageRecord = nil;
        }
        else if(errorResponse == AAPLPostErrorIgnore)
        {
            NSLog(@"Error: %@", [error description]);
            self.imageRecord = nil;
        }
    };
    CKDatabase *publicDB = [[CKContainer defaultContainer] publicCloudDatabase];
    [publicDB addOperation:imageOp];
}

- (AAPLPostErrorResponse) handleError:(NSError *)error
{
    if(error == nil) return AAPLPostErrorSuccess;
    
    switch ([error code])
    {
        case CKErrorNetworkUnavailable:
        case CKErrorNetworkFailure:
            // A reachability check might be appropriate here so we don't just keep retrying if the user has no service
        case CKErrorServiceUnavailable:
        case CKErrorRequestRateLimited:
            return AAPLPostErrorRetry;
            break;
            
        case CKErrorBadContainer:
        case CKErrorMissingEntitlement:
        case CKErrorPermissionFailure:
        case CKErrorBadDatabase:
            // This app uses the publicDB with default world readable permissions
        case CKErrorUnknownItem:
        case CKErrorAssetFileNotFound:
            // This shouldn't happen. If an Image record is deleted it should delete all Post records that reference it (CKReferenceActionDeleteSelf)
        case CKErrorIncompatibleVersion:
        case CKErrorQuotaExceeded:
            //App quota will be exceeded, cancelling operation
        case CKErrorOperationCancelled:
            // Nothing to do here, we intentionally cancelled
        case CKErrorNotAuthenticated:
        case CKErrorInvalidArguments:
        case CKErrorResultsTruncated:
        case CKErrorServerRecordChanged:
        case CKErrorAssetFileModified:
        case CKErrorChangeTokenExpired:
        case CKErrorBatchRequestFailed:
        case CKErrorZoneBusy:
        case CKErrorZoneNotFound:
        case CKErrorLimitExceeded:
        case CKErrorUserDeletedZone:
            // These errors are pretty irrelevant here
            // We're fetching only one record by its recordID
            // These errors could be hit fetching multiple records, using zones, saving records, or fetching with predicates
        case CKErrorInternalError:
        case CKErrorServerRejectedRequest:
        case CKErrorConstraintViolation:
            NSLog(@"Nonrecoverable error, will not retry");
        default:
            return AAPLPostErrorIgnore;
            break;
    }
}

@end

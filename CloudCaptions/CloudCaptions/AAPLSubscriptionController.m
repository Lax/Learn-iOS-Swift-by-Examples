/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

@import CloudKit;
#import "AAPLSubscriptionController.h"
#import "AAPLPost.h"

static NSString * const subscriptionID = @"autoUpdate";

typedef NS_ENUM(NSInteger, AAPLSubscriptionErrorResponse) {
    AAPLSubscriptionErrorIgnore,
    AAPLSubscriptionErrorRetry,
    AAPLSubscriptionErrorSuccess,
};


@implementation AAPLSubscriptionController

- (instancetype) initWithCustomView:(UIView *)customView
{
    self = [super initWithCustomView:customView];
    if(self)
    {
        self.target = self;
        self.action = @selector(toggleSubscription);
        [self checkSubscription];
    }
    return self;
}

- (void) checkSubscription
{
    CKDatabase *publicDB = [CKContainer defaultContainer].publicCloudDatabase;
    [publicDB fetchSubscriptionWithID:subscriptionID completionHandler:^(CKSubscription *subscription, NSError *error) {
        AAPLSubscriptionErrorResponse errorResult = [self handleError:error];
        if(errorResult == AAPLSubscriptionErrorSuccess)
        {
            if([error code] == CKErrorUnknownItem)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *subscribeButton = NSLocalizedString(@"SubscribeButton", @"Title for button that subscribes to updates when it is pressed");
                    self.title = subscribeButton;
                    self.customView = nil;
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *unsubscribeButton = NSLocalizedString(@"UnsubscribeButton", @"Title for button that unsubscribes to updates when it is pressed");
                    self.title = unsubscribeButton;
                    self.customView = nil;
                });
            }
        }
        else if(errorResult == AAPLSubscriptionErrorRetry)
        {
            NSNumber *retryAfter = error.userInfo[CKErrorRetryAfterKey] ?: @3;
            NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [error description], retryAfter);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.integerValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self checkSubscription];
            });
        }
        else if(errorResult == AAPLSubscriptionErrorIgnore)
        {
            NSLog(@"Ignored error while checking subscription: %@", [error description]);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.title = @"?";
                self.customView = nil;
            });
        }
    }];
}

- (void) toggleSubscription
{
    CKDatabase *publicDB = [CKContainer defaultContainer].publicCloudDatabase;
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    self.customView = indicator;
    
    if([self.title isEqualToString:NSLocalizedString(@"SubscribeButton", @"Title for button that subscribes to updates when it is pressed")])
    {
        CKNotificationInfo *subNotification = [[CKNotificationInfo alloc] init];
        subNotification.alertBody = @"New Post";
        CKSubscription *subscriptionToUpload = [[CKSubscription alloc] initWithRecordType:AAPLPostRecordType predicate:[NSPredicate predicateWithValue:YES] subscriptionID:subscriptionID options:CKSubscriptionOptionsFiresOnRecordCreation];
        subscriptionToUpload.notificationInfo = subNotification;
        
        [publicDB saveSubscription:subscriptionToUpload completionHandler:^(CKSubscription *subscription, NSError *error) {
            AAPLSubscriptionErrorResponse errorResult = [self handleError:error];
            if(errorResult == AAPLSubscriptionErrorSuccess)
            {
                if([error code] == CKErrorUnknownItem) NSLog(@"If you see this it's because you've tried to subscribe to new Post records when CloudKit hasn't seen the Post record type yet. Either manually create the record type in dashboard or upload a post");
                [self checkSubscription];
            }
            else if(errorResult == AAPLSubscriptionErrorRetry)
            {
                NSNumber *retryAfter = error.userInfo[CKErrorRetryAfterKey] ?: @3;
                NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [error description], retryAfter);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.integerValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self toggleSubscription];
                });
            }
            else if(errorResult == AAPLSubscriptionErrorIgnore)
            {
                NSLog(@"Ignored error while saving subscription: %@", [error description]);
            }
        }];
    }
    else if([self.title isEqualToString:NSLocalizedString(@"UnsubscribeButton", @"Title for button that unsubscribes to updates when it is pressed")])
    {
        [publicDB deleteSubscriptionWithID:subscriptionID completionHandler:^(NSString *subscriptionID, NSError *error) {
            AAPLSubscriptionErrorResponse errorResult = [self handleError:error];
            if(errorResult == AAPLSubscriptionErrorSuccess)
            {
                [self checkSubscription];
            }
            else if(errorResult == AAPLSubscriptionErrorRetry)
            {
                NSNumber *retryAfter = error.userInfo[CKErrorRetryAfterKey] ?: @3;
                NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [error description], retryAfter);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.integerValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self toggleSubscription];
                });
            }
            else if(errorResult == AAPLSubscriptionErrorIgnore)
            {
                NSLog(@"Ignored error while deleting subscription: %@", [error description]);
            }
        }];
    }
    else
    {
        [self checkSubscription];
    }
}

- (AAPLSubscriptionErrorResponse) handleError:(NSError *)error
{
    if (error == nil) {
        return AAPLSubscriptionErrorSuccess;
    }
    switch ([error code])
    {
        case CKErrorUnknownItem:
            // This error occurs if it can't find the subscription named autoUpdate. (It tries to delete one that doesn't exits or it searches for one it can't find)
            // This is okay and expected behavior
            return AAPLSubscriptionErrorSuccess;
            break;
        case CKErrorNetworkUnavailable:
        case CKErrorNetworkFailure:
            // A reachability check might be appropriate here so we don't just keep retrying if the user has no service
        case CKErrorServiceUnavailable:
        case CKErrorRequestRateLimited:
            return AAPLSubscriptionErrorRetry;
            break;
            
        case CKErrorBadDatabase:
        case CKErrorIncompatibleVersion:
        case CKErrorBadContainer:
        case CKErrorPermissionFailure:
        case CKErrorMissingEntitlement:
            // This app uses the publicDB with default world readable permissions
        case CKErrorAssetFileNotFound:
        case CKErrorPartialFailure:
            // These shouldn't occur during a subscription operation
        case CKErrorQuotaExceeded:
            // We should not retry if it'll exceed our quota
        case CKErrorOperationCancelled:
            // Nothing to do here, we intentionally cancelled
        case CKErrorNotAuthenticated:
            // User must be logged in
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
            // All of these errors are irrelevant for this subscription operation
        case CKErrorInternalError:
        case CKErrorServerRejectedRequest:
        case CKErrorConstraintViolation:
            //Non-recoverable, should not retry
        default:
            return AAPLSubscriptionErrorIgnore;
            break;
    }
}

@end

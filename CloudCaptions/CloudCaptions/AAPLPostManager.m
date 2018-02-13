/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

@import CloudKit;
#import "AAPLPostManager.h"
#import "AAPLPost.h"

typedef NS_ENUM(NSInteger, AAPLPostManagerErrorResponse) {
    AAPLPostManagerErrorIgnore,
    AAPLPostManagerErrorRetry,
    AAPLPostManagerErrorSuccess,
};

@interface AAPLPostManager ()

@property (strong, atomic) void (^reloadBlock)();
@property (strong, atomic) AAPLPost *lastPostSeenOnServer;
@property (strong, atomic) NSArray *tagArray;
@property (strong, atomic) CKQueryCursor *postCursor;
@property (strong, atomic) NSOperationQueue *fetchRecordQueue;      // Allows for us to cancel loadBatch operation when the tag string has changed
@property (strong, atomic) dispatch_queue_t updateCellArrayQueue;   // Synchronous dispatch queue to synchronously add objects to postCells array
@property (atomic) BOOL isLoadingBatch;                             // Flags when we're loading a batch so we don't try loading a second batch while this one is running
@property (atomic) BOOL haveOldestPost;                             // Flags when we've loaded the earliest post

@end


#pragma mark -

@implementation AAPLPostManager

- (instancetype) initWithReloadHandler:(void (^)(void))reload
{
    self = [super init];
    if (self != nil)
    {
        _reloadBlock = reload;
        _postCells = [[NSMutableArray alloc] init];
        // By setting up these queues, we're able to cancel all udates when the tag string changes
        _updateCellArrayQueue = dispatch_queue_create("UpdateCellQueue", DISPATCH_QUEUE_SERIAL);
        _fetchRecordQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void) resetWithTagString:(NSString *)tags
{
    // Reloads table with new tag settings
    // First, anything the table is updating with now is potentially invalid, cancel any current updates
    [self.fetchRecordQueue cancelAllOperations];
    dispatch_sync(self.updateCellArrayQueue, ^{});  // This should only be filled with array add operations, best to just wait for it to finish

    // Resets the table to be empty
    self.postCells = [[NSMutableArray alloc] init];
    self.lastPostSeenOnServer = nil;
    self.reloadBlock();

    // Sets tag array and prepares table for initial update
    self.tagArray = [tags isEqualToString:@""] ? [[NSArray alloc] init] : [[tags lowercaseString] componentsSeparatedByString:@" "];
    self.postCursor = nil;
    self.isLoadingBatch = NO;
    self.haveOldestPost = NO;
    [self loadBatch];
}

// Called when users pulls to refresh
- (void) loadNewPosts {
    [self loadNewPostsWithAAPLPost:nil];
}

// This adds new items to the beginning of the table
- (void) loadNewPostsWithAAPLPost:(AAPLPost *)post
{
    // If we don't have any posts on our table yet, fetch the first batch instead (we make assumptions in this method that we have other posts to compare to)
    if(self.postCells.count == 0 || self.lastPostSeenOnServer == nil) {
        // We dispatch it after two seconds to give the server time to index the new post
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // If we get here, we must have no posts. That must mean that last time we tried loading a batch nothing came through so we locked the method. Let's unlock it
            self.haveOldestPost = NO;
            [self loadBatch];
        });
        return;
    }
    
    // We want to strip all posts we have that haven't been seen on the server yet from tableview (order isn't guaranteed)
    NSUInteger loc = [self.postCells indexOfObject:self.lastPostSeenOnServer];
    NSMutableArray *newPosts = [[self.postCells subarrayWithRange:NSMakeRange(0, loc)] mutableCopy];
    [self.postCells removeObjectsInArray:newPosts];
    // If we had a post passed in and it matches our tags, we should put that in the array too
    if(post) {
        for (NSString *tag in self.tagArray) {
            if(![post.postRecord[AAPLPostTagsKey] containsObject:tag])
                post = nil;
        }
    }
    if(post) [newPosts addObject:post];
    
    // Creates predicate based on tag string and most recent post from server
    NSMutableArray *subPredicates = [@[[NSPredicate predicateWithFormat:@"creationDate > %@", self.lastPostSeenOnServer.postRecord.creationDate]] mutableCopy];
    for(NSString *tag in self.tagArray) {
        [subPredicates addObject:[NSPredicate predicateWithFormat:@"Tags CONTAINS %@", tag]];
    }
    NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];    // ANDs all subpredicates to make a final predicate
    CKQuery *postQuery = [[CKQuery alloc] initWithRecordType:AAPLPostRecordType predicate:finalPredicate];
    postQuery.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    CKQueryOperation *queryOp = [[CKQueryOperation alloc] initWithQuery:postQuery];
    queryOp.desiredKeys = @[AAPLPostImageRefKey,AAPLPostFontKey,AAPLPostTextKey];
    
    // The last record we see will be the most recent we see on the server, we'll set the property to this in the completion block
    __block AAPLPost *lastRecordInOperation = nil;
    queryOp.recordFetchedBlock = ^(CKRecord *record) {
        // If the record we just fetched doesn't match recordIDs to any item in our newPosts array, let's make an AAPLPost and add it
        NSUInteger matchingRecord = [newPosts indexOfObjectPassingTest:^BOOL(AAPLPost *obj, NSUInteger idx, BOOL *stop) {
            if([obj.postRecord.recordID isEqual:record.recordID]) return YES;
            else return NO;
        }];
        if(matchingRecord == NSNotFound)
        {
            AAPLPost *fetchedPost = [[AAPLPost alloc] initWithRecord:record];
            [newPosts addObject:fetchedPost];
            [fetchedPost loadImageWithKeys:@[AAPLImageFullsizeKey] completion:^void(){
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.reloadBlock();
                });
            }];
            lastRecordInOperation = fetchedPost;
        }
        // If we already have this record we don't have to fetch. We'll still update lastRecordInOperation because we did see it on the server
        else
        {
            lastRecordInOperation = newPosts[matchingRecord];
        }
    };
    queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *operationError){
        AAPLPostManagerErrorResponse error = [self handleError:operationError];
        
        if(error == AAPLPostManagerErrorSuccess)
        {
            // lastRecordCreationDate is the most recent record we've seen on server, let's set our property to that for next time we get a push
            if(lastRecordInOperation) {
                self.lastPostSeenOnServer = lastRecordInOperation;
            }
            // This sorts the newPosts array in ascending order
            [newPosts sortUsingComparator:^NSComparisonResult(AAPLPost *post1, AAPLPost *post2) {
                return [post1.postRecord.creationDate compare:post2.postRecord.creationDate];
            }];
            // Takes our newPosts array and inserts the items into the table array one at a time
            for(AAPLPost *post in newPosts)
            {
                dispatch_async(self.updateCellArrayQueue, ^{
                    [self.postCells insertObject:post atIndex:0];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.reloadBlock();
                    });
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        }
        else if(error == AAPLPostManagerErrorRetry)
        {
            NSNumber *retryAfter = operationError.userInfo[CKErrorRetryAfterKey] ?: @3;
            NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [operationError description], retryAfter);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.intValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self loadNewPostsWithAAPLPost:post];
            });
        }
        else if(error == AAPLPostManagerErrorIgnore)
        {
            NSLog(@"Error: %@", [operationError description]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        }
    };
    
    CKDatabase *publicDB = [[CKContainer defaultContainer] publicCloudDatabase];
    queryOp.database = publicDB;
    [self.fetchRecordQueue addOperation:queryOp];
}

- (void)loadBatch
{
    @synchronized (self)
    {
        // Quickly returns if another loadNextBatch is running or we have the oldest post
        if(self.isLoadingBatch || self.haveOldestPost) return;
        else self.isLoadingBatch = YES;
    }
    CKQueryOperation *queryOp = nil;
    if(self.postCursor)
    {
        // If we have a cursor, go ahead and just continue from where we left off
        queryOp = [[CKQueryOperation alloc] initWithCursor:self.postCursor];
    }
    else
    {
        // Create predicate out of tags. If self.tagArray is empty we should get every post
        NSMutableArray *subPredicates = [[NSMutableArray alloc] init];
        for(NSString *tag in self.tagArray)
        {
            NSPredicate *queryPred = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"Tags CONTAINS \'%@\'",tag]];
            [subPredicates addObject:queryPred];
        }
        // If our tagArray is empty, create a true predicate (as opposed to a predicate containing "Tags CONTAINS ''"
        NSPredicate *finalPredicate = [self.tagArray count] == 0 ? [NSPredicate predicateWithValue:YES] : [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
        
        CKQuery *postQuery = [[CKQuery alloc] initWithRecordType:AAPLPostRecordType predicate:finalPredicate];
        postQuery.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        queryOp = [[CKQueryOperation alloc] initWithQuery:postQuery];
    }
    
    // This query should only fetch so many records and only retrieve the information we need
    queryOp.resultsLimit = updateBy;
    queryOp.desiredKeys = @[AAPLPostImageRefKey,AAPLPostFontKey,AAPLPostTextKey];
    
    NSMutableArray *newPosts = [[NSMutableArray alloc] init];
    queryOp.recordFetchedBlock = ^(CKRecord *record) {
        // When we get a record, use it to create an AAPLPost
        AAPLPost *fetchedPost = [[AAPLPost alloc] initWithRecord:record];
        [fetchedPost loadImageWithKeys:@[AAPLImageFullsizeKey] completion:^void(){
            // Once image is loaded, tell the tableview to reload
            dispatch_async(dispatch_get_main_queue(), ^{
                self.reloadBlock();
            });
        }];
        [newPosts addObject:fetchedPost];
    };
    queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *operationError){
        AAPLPostManagerErrorResponse error = [self handleError:operationError];
        
        if(error == AAPLPostManagerErrorSuccess)
        {
            self.postCursor = cursor;
            self.isLoadingBatch = NO;
            if(cursor == nil) self.haveOldestPost = YES;
            dispatch_sync(self.updateCellArrayQueue, ^{
                [self.postCells addObjectsFromArray:newPosts];
            });
            if(!self.lastPostSeenOnServer && [self.postCells count])
            {
                self.lastPostSeenOnServer = self.postCells[0];
                [self.refreshControl endRefreshing];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.reloadBlock();
            });
        }
        else if(error == AAPLPostManagerErrorRetry)
        {
            NSNumber *retryAfter = operationError.userInfo[CKErrorRetryAfterKey] ?: @3;
            NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [operationError description], retryAfter);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.integerValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.isLoadingBatch = NO;
                [self loadBatch];
            });
        }
        else if(error == AAPLPostManagerErrorIgnore)
        {
            self.isLoadingBatch = NO;
            [self.refreshControl endRefreshing];
            NSLog(@"Error: %@", [operationError description]);
        }
    };
    CKDatabase *publicDB = [[CKContainer defaultContainer] publicCloudDatabase];
    [queryOp setDatabase:publicDB];
    [self.fetchRecordQueue addOperation:queryOp];
}

- (AAPLPostManagerErrorResponse) handleError:(NSError *)error
{
    if (error == nil) {
        return AAPLPostManagerErrorSuccess;
    }
    switch ([error code])
    {
        case CKErrorNetworkUnavailable:
        case CKErrorNetworkFailure:
            // A reachability check might be appropriate here so we don't just keep retrying if the user has no service
        case CKErrorServiceUnavailable:
        case CKErrorRequestRateLimited:
            return AAPLPostManagerErrorRetry;
            break;
            
        case CKErrorUnknownItem:
            NSLog(@"If a post has never been made, CKErrorUnknownItem will be returned in AAPLPostManager because it has never seen the Post record type");
            return AAPLPostManagerErrorIgnore;
            break;
        case CKErrorInvalidArguments:
            NSLog(@"If invalid arguments is returned in AAPLPostManager with a message about not being marked indexable or sortable, go into CloudKit dashboard and set the Post record type as sortable on date created (under metadata index)");
            return AAPLPostManagerErrorIgnore;
            break;
        case CKErrorIncompatibleVersion:
        case CKErrorBadContainer:
        case CKErrorMissingEntitlement:
        case CKErrorPermissionFailure:
        case CKErrorBadDatabase:
            // This app uses the publicDB with default world readable permissions
        case CKErrorAssetFileNotFound:
        case CKErrorPartialFailure:
            // These shouldn't occur during a query operation
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
            return AAPLPostManagerErrorIgnore;
            break;
    }
}

@end


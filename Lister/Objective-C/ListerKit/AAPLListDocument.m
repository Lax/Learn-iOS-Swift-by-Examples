/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListDocument class is a \c UIDocument subclass that represents a list. \c AAPLListDocument also manages the serialization / deserialization of the list object.
*/

#import "AAPLListDocument.h"
#import "AAPLAppConfiguration.h"
#import "AAPLListPresenting.h"
#import "AAPLList.h"
#import "AAPLListColor+UI.h"

@implementation AAPLListDocument

#pragma mark - Initialization

- (instancetype)initWithFileURL:(NSURL *)url listPresenter:(id<AAPLListPresenting>)listPresenter {
    self = [super initWithFileURL:url];
    
    if (self) {
        _listPresenter = listPresenter;
    }
    
    return self;
}

#pragma mark - Serialization / Deserialization

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    AAPLList *unarchivedList = [NSKeyedUnarchiver unarchiveObjectWithData:contents];

    if (unarchivedList) {
        /*
             This method is called on the queue that the openWithCompletionHandler: method was called
             on (typically, the main queue). List presenter operations are main queue only, so explicitly
             call on the main queue.
        */
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.listPresenter setList:unarchivedList];
        });

        return YES;
    }
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Could not read file", @"Read error description"),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"File was in an invalid format", @"Read failure reason")
        }];
    }
    
    return NO;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    AAPLList *archiveableList = self.listPresenter.archiveableList;

    if (archiveableList) {
        return [NSKeyedArchiver archivedDataWithRootObject:archiveableList];
    }
    else {
        return nil;
    }
}

#pragma mark - Deletion

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler {
    [super accommodatePresentedItemDeletionWithCompletionHandler:completionHandler];

    [self.delegate listDocumentWasDeleted:self];
}

#pragma mark - Handoff

- (void)updateUserActivityState:(NSUserActivity *)userActivity {
    [super updateUserActivityState:userActivity];

    [userActivity addUserInfoEntriesFromDictionary:@{
        AAPLAppConfigurationUserActivityListColorUserInfoKey: @(self.listPresenter.color)
    }];
}

@end

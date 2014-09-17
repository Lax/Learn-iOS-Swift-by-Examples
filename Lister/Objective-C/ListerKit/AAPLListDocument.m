/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLListDocument class is a \c UIDocument subclass that represents a list. \c AAPLListDocument also manages the serialization / deserialization of the list object.
            
*/

#import "AAPLAppConfiguration.h"
#import "AAPLListDocument.h"
#import "AAPLList.h"

@implementation AAPLListDocument

#pragma mark - Serialization / Deserialization

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    AAPLList *deserializedList = [NSKeyedUnarchiver unarchiveObjectWithData:contents];

    if (deserializedList) {
        self.list = deserializedList;

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
    return [NSKeyedArchiver archivedDataWithRootObject:self.list];
}

#pragma mark - Deletion

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler {
    [super accommodatePresentedItemDeletionWithCompletionHandler:completionHandler];

    [self.delegate listDocumentWasDeleted:self];
}

#pragma mark - Handoff

- (void)updateUserActivityState:(NSUserActivity *)userActivity {
    [super updateUserActivityState:userActivity];
    [userActivity addUserInfoEntriesFromDictionary:@{ AAPLAppConfigurationUserActivityListColorUserInfoKey: @(self.list.color) }];
}

@end

/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListDocument class is an \c NSDocument subclass that represents a list. It manages the serialization / deserialization of the list object, presentation of window controllers, a list presenter, and more.
*/

#import "AAPLListDocument.h"
#import "AAPlAppConfiguration.h"
#import "AAPLList.h"
#import "AAPLListPresenting.h"

NSString *const AAPLListWindowControllerStoryboardIdentifier = @"AAPLListWindowControllerStoryboardIdentifier";

@interface AAPLListDocument ()

@property (nonatomic) BOOL makesCustomWindowControllers;

@property AAPLList *unarchivedList;

@end

@implementation AAPLListDocument
@synthesize listPresenter = _listPresenter;

#pragma mark - Initialization

- (instancetype)initWithContentsOfURL:(NSURL *)url listPresenter:(id<AAPLListPresenting>)listPresenter makesCustomWindowControllers:(BOOL)makesCustomWindowControllers error:(NSError *__autoreleasing *)error {
    self = [super initWithContentsOfURL:url ofType:AAPLAppConfigurationListerFileExtension error:error];

    if (self) {
        _listPresenter = listPresenter;
        _makesCustomWindowControllers = makesCustomWindowControllers;
    }
    
    return self;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _makesCustomWindowControllers = YES;
    }
    
    return self;
}

#pragma mark - Auto Save and Versions

+ (BOOL)autosavesInPlace {
    return YES;
}

#pragma mark - Property Overrides

- (void)setListPresenter:(id<AAPLListPresenting>)listPresenter {
    _listPresenter = listPresenter;

    if (self.unarchivedList) {
        [_listPresenter setList:self.unarchivedList];
    }
}

#pragma mark - NSDocument Overrides

/*!
    Create window controllers from a storyboard, if desired (based on -makesWindowControllers).
    The window controller that's used is the initial controller set in the storyboard.
 */
- (void)makeWindowControllers {
    [super makeWindowControllers];
    
    if (self.makesCustomWindowControllers) {
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        
        NSWindowController *windowController = [storyboard instantiateControllerWithIdentifier:AAPLListWindowControllerStoryboardIdentifier];

        [self addWindowController:windowController];
    }
}

- (NSString *)defaultDraftName {
    return [AAPLAppConfiguration sharedAppConfiguration].defaultListerDraftName;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    self.unarchivedList = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    if (self.unarchivedList != nil) {
        [self.listPresenter setList:self.unarchivedList];

        return YES;
    }
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Could not read file.", nil),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"File was in an invalid format.", nil)
        }];
    }

    return NO;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    return [NSKeyedArchiver archivedDataWithRootObject:self.listPresenter.archiveableList];
}

#pragma mark - Handoff

- (void)updateUserActivityState:(NSUserActivity *)userActivity {
    [super updateUserActivityState:userActivity];

    // Store the list's color in the user activity to be able to quickly present a list when it's viewed.
    [userActivity addUserInfoEntriesFromDictionary:@{
        AAPLAppConfigurationUserActivityListColorUserInfoKey: @(self.listPresenter.color)
    }];
}

@end

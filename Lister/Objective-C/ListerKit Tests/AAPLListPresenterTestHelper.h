/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class that makes it easier to test \c AAPLListPresenting instance implementations.
*/

@import Foundation;
#import "AAPLList.h"
#import "AAPLListPresenterDelegate.h"

@interface AAPLListPresenterTestHelper : NSObject <AAPLListPresenterDelegate>

/// An array of \c AAPLListPresenterCallbackInfo objects of the inserted list items.
@property (copy) NSArray *didInsertListItemCallbacks;

/// An array of \c AAPLListPresenterCallbackInfo objects of the removed list items.
@property (copy) NSArray *didRemoveListItemCallbacks;

/// An array of \c AAPLListPresenterCallbackInfo objects of the updated list items.
@property (copy) NSArray *didUpdateListItemCallbacks;

/// An array of \c AAPLListPresenterCallbackInfo objects of the moved list items.
@property (copy) NSArray *didMoveListItemCallbacks;

/// An array of \c AAPLListPresenterCallbackInfo objects of the updates to the list presenter's color.
@property (copy) NSArray *didUpdateListColorCallbacks;

/// A helper method run \c assertions once a batch of changes has occured to the list presenter.
- (void)whenNextChangeOccursPerformAssertions:(void (^)(void))assertions;

@end

/// A model class that contains information provided by the \c AAPLListPresenterTestHelper object.
@interface AAPLListPresenterCallbackInfo : NSObject

@property AAPLListItem *listItem;

@property NSInteger index;

@property NSInteger fromIndex;
@property NSInteger toIndex;

@property AAPLListColor color;

@end

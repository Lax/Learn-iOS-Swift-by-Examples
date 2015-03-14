/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class that makes it easier to test \c AAPLListPresenting instance implementations.
*/

#import "AAPLListPresenterTestHelper.h"

@implementation AAPLListPresenterCallbackInfo

- (instancetype)initWithListItem:(AAPLListItem *)listItem index:(NSInteger)index {
    self = [super init];
    
    if (self) {
        _listItem = listItem;

        _index = index;
        
        _fromIndex = NSNotFound;
        
        _toIndex = NSNotFound;
    }
    
    return self;
}

- (instancetype)initWithListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    self = [super init];

    if (self) {
        _listItem = listItem;
        
        _fromIndex = fromIndex;
        
        _toIndex = toIndex;

        _index = NSNotFound;
    }
    
    return self;
}

- (instancetype)initWithColor:(AAPLListColor)color {
    self = [super init];

    if (self) {
        _color = color;
        
        _index = NSNotFound;
        _fromIndex = NSNotFound;
        _toIndex = NSNotFound;
    }
    
    return self;
}

@end

@interface AAPLListPresenterTestHelper ()

@property NSInteger remainingExpectedWillChanges;
@property NSInteger remainingExpectedDidChanges;

@property NSInteger willChangeCallbackCount;
@property NSInteger didChangeCallbackCount;

@property (copy) void (^assertions)(void);

@property (getter=isTesting) BOOL testing;

@end

@implementation AAPLListPresenterTestHelper

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _testing = NO;
        
        _willChangeCallbackCount = NSNotFound;
        _didChangeCallbackCount = NSNotFound;

        _remainingExpectedWillChanges = NSNotFound;
        _remainingExpectedDidChanges = NSNotFound;
        
        _didInsertListItemCallbacks = [NSArray array];
        _didRemoveListItemCallbacks = [NSArray array];
        _didUpdateListItemCallbacks = [NSArray array];
        _didMoveListItemCallbacks = [NSArray array];
        _didUpdateListColorCallbacks = [NSArray array];
    }
    
    return self;
}

#pragma mark - AAPLListPresenterDelegate

- (void)listPresenterDidRefreshCompleteLayout:(id<AAPLListPresenting>)listPresenter {
    // Lister's tests currently do not support testing and `-listPresenterDidRefreshCompleteLayout:` calls.
}

- (void)listPresenterWillChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    if (!self.isTesting) {
        return;
    }
    
    if (self.remainingExpectedWillChanges != NSNotFound) {
        self.remainingExpectedWillChanges--;
    }
    
    self.willChangeCallbackCount--;
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didInsertListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    if (!self.isTesting) {
        return;
    }
    
    AAPLListPresenterCallbackInfo *didInsertListItemCallback = [[AAPLListPresenterCallbackInfo alloc] initWithListItem:listItem index:index];
    
    [[self mutableArrayValueForKey:@"didInsertListItemCallbacks"] addObject:didInsertListItemCallback];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didRemoveListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    if (!self.isTesting) {
        return;
    }
    
    AAPLListPresenterCallbackInfo *didRemoveListItemCallback = [[AAPLListPresenterCallbackInfo alloc] initWithListItem:listItem index:index];
    
    [[self mutableArrayValueForKey:@"didRemoveListItemCallbacks"] addObject:didRemoveListItemCallback];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListItem:(AAPLListItem *)listItem atIndex:(NSInteger)index {
    if (!self.isTesting) {
        return;
    }
    
    AAPLListPresenterCallbackInfo *didUpdateListItemCallback = [[AAPLListPresenterCallbackInfo alloc] initWithListItem:listItem index:index];
    
    [[self mutableArrayValueForKey:@"didUpdateListItemCallbacks"] addObject:didUpdateListItemCallback];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didMoveListItem:(AAPLListItem *)listItem fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    if (!self.isTesting) {
        return;
    }
    
    AAPLListPresenterCallbackInfo *didMoveListItemCallback = [[AAPLListPresenterCallbackInfo alloc] initWithListItem:listItem fromIndex:fromIndex toIndex:toIndex];
    
    [[self mutableArrayValueForKey:@"didMoveListItemCallbacks"] addObject:didMoveListItemCallback];
}

- (void)listPresenter:(id<AAPLListPresenting>)listPresenter didUpdateListColorWithColor:(AAPLListColor)color {
    if (!self.isTesting) {
        return;
    }
    
    AAPLListPresenterCallbackInfo *didUpdateListColorCallback = [[AAPLListPresenterCallbackInfo alloc] initWithColor:color];
    
    [[self mutableArrayValueForKey:@"didUpdateListColorCallbacks"] addObject:didUpdateListColorCallback];
}

- (void)listPresenterDidChangeListLayout:(id<AAPLListPresenting>)listPresenter isInitialLayout:(BOOL)isInitialLayout {
    if (!self.isTesting) {
        return;
    }
    
    if (self.remainingExpectedWillChanges != NSNotFound) {
        self.remainingExpectedWillChanges--;
    }
    
    self.didChangeCallbackCount++;
    
    if (self.remainingExpectedDidChanges == 0) {
        self.assertions();
        
        self.testing = NO;
    }
}

- (void)whenNextChangeOccursPerformAssertions:(void (^)(void))assertions {
    self.testing = YES;
    
    self.assertions = assertions;
    
    self.willChangeCallbackCount = 0;

    self.didInsertListItemCallbacks = @[];
    self.didRemoveListItemCallbacks = @[];
    self.didUpdateListColorCallbacks = @[];
    self.didMoveListItemCallbacks = @[];
    self.didUpdateListColorCallbacks = @[];
    self.didChangeCallbackCount = 0;
    self.remainingExpectedDidChanges = 0;
    
    self.remainingExpectedWillChanges = 0;
    self.remainingExpectedDidChanges = 0;
}

@end

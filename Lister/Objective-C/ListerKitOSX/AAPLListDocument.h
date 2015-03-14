/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListDocument class is an \c NSDocument subclass that represents a list. It manages the serialization / deserialization of the list object, presentation of window controllers, a list presenter, and more.
*/

@import Cocoa;

@class AAPLList;
@protocol AAPLListPresenting;

@interface AAPLListDocument : NSDocument

- (instancetype)initWithContentsOfURL:(NSURL *)url listPresenter:(id<AAPLListPresenting>)listPresenter makesCustomWindowControllers:(BOOL)makesCustomWindowControllers error:(NSError *__autoreleasing *)error;

@property (nonatomic) id<AAPLListPresenting> listPresenter;

@end

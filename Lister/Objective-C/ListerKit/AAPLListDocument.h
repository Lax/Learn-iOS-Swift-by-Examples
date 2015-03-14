/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListDocument class is a \c UIDocument subclass that represents a list. \c AAPLListDocument also manages the serialization / deserialization of the list object.
*/

@import UIKit;

@protocol AAPLListPresenting;
@class AAPLListDocument;

/// Protocol that allows a list document to notify other objects of it being deleted.
@protocol AAPLListDocumentDelegate <NSObject>

- (void)listDocumentWasDeleted:(AAPLListDocument *)document;

@end


@interface AAPLListDocument : UIDocument

@property (nonatomic) id<AAPLListPresenting> listPresenter;
@property (weak) id<AAPLListDocumentDelegate> delegate;

- (instancetype)initWithFileURL:(NSURL *)url listPresenter:(id<AAPLListPresenting>)listPresenter;

@end


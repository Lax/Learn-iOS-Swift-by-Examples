/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                An NSDocument subclass that represents a list. It manages the serialization / deserialization of the list object, presentation of window controllers, and more.
            
*/

@import Cocoa;

@class AAPLList, AAPLListDocument;

@protocol AAPLListDocumentDelegate <NSObject>
- (void)listDocumentDidChangeContents:(AAPLListDocument *)document;
@end


@interface AAPLListDocument : NSDocument

- (instancetype)initWithContentsOfURL:(NSURL *)url makesCustomWindowControllers:(BOOL)makesCustomWindowControllers error:(NSError *__autoreleasing *)error;

@property (weak) id<AAPLListDocumentDelegate> delegate;

@property AAPLList *list;

@end

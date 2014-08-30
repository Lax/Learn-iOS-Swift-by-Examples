/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The \c AAPLListInfo class is a caching abstraction over an \c AAPLList object that contains information about lists (e.g. color and name).
             
*/

#import "AAPLListInfo.h"
#import "AAPLListUtilities.h"

#define AAPLListColorUndefined ((AAPLListColor)-1)

@interface AAPLListInfo ()

@property (nonatomic, strong) dispatch_queue_t fetchQueue;

@end

@implementation AAPLListInfo

#pragma mark - Initializers

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];

    if (self) {
        _color = AAPLListColorUndefined;

        _fetchQueue = dispatch_queue_create("com.example.apple-samplecode.listinfo", DISPATCH_QUEUE_SERIAL);
        _URL = URL;
    }
    
    return self;
}

#pragma mark - Fetch Methods

- (void)fetchInfoWithCompletionHandler:(void (^)(void))completionHandler {
    dispatch_async(self.fetchQueue, ^{
        // If the color hasn't been set yet, the info hasn't been fetched.
        if (self.color != AAPLListColorUndefined) {
            completionHandler();

            return;
        }
        
        [AAPLListUtilities readListAtURL:self.URL withCompletionHandler:^(AAPLList *list, NSError *error) {
            dispatch_async(self.fetchQueue, ^{
                if (list) {
                    self.color = list.color;
                }
                else {
                    self.color = AAPLListColorGray;
                }

                completionHandler();
            });
        }];
    });
}

#pragma mark - Property Overrides

- (NSString *)name {
    NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:self.URL.path];
    
    return displayName.stringByDeletingPathExtension;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[AAPLListInfo class]]) {
        return NO;
    }
    
    return [self.URL isEqual:[object URL]];
}

@end

#undef AAPLListColorUndefined

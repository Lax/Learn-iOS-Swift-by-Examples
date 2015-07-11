/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListInfo class is a caching abstraction over an \c AAPLList object that contains information about lists (e.g. color and name). This object is distinct from the one used by the iOS application.
*/

#import "AAPLListInfo.h"

@implementation AAPLListInfo

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[AAPLListInfo class]]) {
        return NO;
    }
    
    return [self.name isEqualToString:[object name]];
}

@end

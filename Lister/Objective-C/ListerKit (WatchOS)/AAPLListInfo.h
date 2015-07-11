/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListInfo class is a caching abstraction over an \c AAPLList object that contains information about lists (e.g. color and name). This object is distinct from the one used by the iOS application.
*/

@import Foundation;
#import "AAPLList.h"

@interface AAPLListInfo : NSObject

@property (nonatomic, copy) NSString *name;
@property AAPLListColor color;

@end

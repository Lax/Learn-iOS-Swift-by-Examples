/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Test instance which holds the test name details and the selector which should be invoked to perform the test.
*/

#import "AAPLTest.h"

@implementation AAPLTest

- (instancetype)initWithName:(NSString *)name details:(NSString *)details selector:(SEL)method {
    self = [super init];
    
    if (self) {
        _name = [name copy];
        _details = [details copy];
        _method = method;
    }
    
    return self;
}

@end

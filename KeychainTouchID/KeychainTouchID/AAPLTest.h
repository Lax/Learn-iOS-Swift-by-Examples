/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Test instance which holds the test name details and the selector which should be invoked to perform the test.
*/

@import Foundation;

@interface AAPLTest : NSObject

- (instancetype)initWithName:(NSString *)name details:(NSString *)details selector:(SEL)method;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *details;
@property (nonatomic) SEL method;

@end

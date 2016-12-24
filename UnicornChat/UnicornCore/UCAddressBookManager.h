/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The class that manages UnicornChat's own address book.
*/

#import <Foundation/Foundation.h>

@class UCContact;

NS_ASSUME_NONNULL_BEGIN

@interface UCAddressBookManager : NSObject
- (NSArray<UCContact *> *)contactsMatchingName:(NSString *)name;
@end

NS_ASSUME_NONNULL_END

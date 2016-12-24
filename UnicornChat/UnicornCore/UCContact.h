/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Data model class for contact object in UnicornChat.
*/

#import <Foundation/Foundation.h>

@class INPerson;

NS_ASSUME_NONNULL_BEGIN

@interface UCContact : NSObject

@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *unicornName;

@property (nonatomic) BOOL favorite;

- (INPerson *)inPerson;

@end

NS_ASSUME_NONNULL_END

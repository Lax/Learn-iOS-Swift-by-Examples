/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Data model class for contact object in UnicornChat.
*/

#import "UCContact.h"
#import <Intents/Intents.h>

@implementation UCContact

- (INPerson *)inPerson {
    INPersonHandle *handle = [[INPersonHandle alloc] initWithValue:_unicornName type:INPersonHandleTypeUnknown];
    return [[INPerson alloc] initWithPersonHandle:handle nameComponents:nil displayName:_name image:nil contactIdentifier:_unicornName customIdentifier:nil];
}

@end

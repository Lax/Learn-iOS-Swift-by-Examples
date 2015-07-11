/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLList class manages a list of items and the color of the list.
*/

#import "AAPLList.h"
#import "AAPLListItem.h"

NSString *AAPLNameFromListColor(AAPLListColor listColor) {
    switch (listColor) {
        case AAPLListColorGray:     return @"Gray";
        case AAPLListColorBlue:     return @"Blue";
        case AAPLListColorGreen:    return @"Green";
        case AAPLListColorYellow:   return @"Yellow";
        case AAPLListColorOrange:   return @"Orange";
        case AAPLListColorRed:      return @"Red";
    }
}

/*!
    String constants that are used to archive the stored properties of an \c AAPLListItem.
    These constants are used to help implement \c NSCoding.
*/
NSString *const AAPLListEncodingItemsKey = @"items";
NSString *const AAPLListEncodingColorKey = @"color";

@implementation AAPLList

#pragma mark - Initialization

- (instancetype)initWithColor:(AAPLListColor)color items:(NSArray *)items {
    self = [super init];
    
    if (self) {
        _items = [[NSArray alloc] initWithArray:items copyItems:YES];
        _color = color;
    }
    
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    if (self) {
        _items = [[aDecoder decodeObjectForKey:AAPLListEncodingItemsKey] copy];
 
        _color = (AAPLListColor)[aDecoder decodeIntegerForKey:AAPLListEncodingColorKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.items forKey:AAPLListEncodingItemsKey];
    [aCoder encodeInteger:self.color forKey:AAPLListEncodingColorKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    return [[AAPLList alloc] initWithColor:self.color items:self.items];
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[AAPLList class]]) {
        return [self isEqualToList:object];
    }
    
    return NO;
}

- (BOOL)isEqualToList:(AAPLList *)list {
    if (self.color != list.color) {
        return NO;
    }

    return [self.items isEqualToArray:list.items];
}

#pragma mark - Debugging

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"{color: %@, items: %@}", AAPLNameFromListColor(self.color), self.items];
}

@end

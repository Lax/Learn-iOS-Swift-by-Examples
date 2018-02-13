/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Managed object subclass for Category entity.
 */

@import Foundation;
@import CoreData;

@interface Category : NSManagedObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSSet *songs;

@end

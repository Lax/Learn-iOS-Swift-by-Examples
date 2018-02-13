/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Managed object subclass for Song entity.
 */

@import UIKit;
@import CoreData;

@class Category;

@interface Song : NSManagedObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) Category *category;
@property (nonatomic, strong) NSNumber *rank;
@property (nonatomic, strong) NSString *album;
@property (nonatomic, strong) NSDate *releaseDate;
@property (nonatomic, strong) NSString *artist;

@end

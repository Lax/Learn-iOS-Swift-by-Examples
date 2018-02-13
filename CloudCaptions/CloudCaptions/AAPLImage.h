/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Container model used to manage Image records
  
 */

@import UIKit;
@import CloudKit;

static NSString * const AAPLImageRecordType = @"Image";
static NSString * const AAPLImageThumbnailKey = @"Thumb";
static NSString * const AAPLImageFullsizeKey = @"Full";

@interface AAPLImage : NSObject

- (instancetype) initWithImage:(UIImage *)image;
- (instancetype) initWithRecord:(CKRecord *)record;

@property (readonly, getter=isOnServer) BOOL onServer;
@property (strong, readonly, atomic) CKRecord *record;
@property (strong, readonly, atomic) UIImage *fullImage;
@property (strong, readonly, atomic) UIImage *thumbnail;

@end

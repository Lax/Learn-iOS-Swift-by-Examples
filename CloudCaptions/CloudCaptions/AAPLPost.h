/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Container model used to manage post records
  
 */

@import CloudKit;
#import "AAPLImage.h"

static NSString * const AAPLPostRecordType = @"Post";
static NSString * const AAPLPostTextKey = @"ImageText";
static NSString * const AAPLPostFontKey = @"Font";
static NSString * const AAPLPostImageRefKey = @"ImageRef";
static NSString * const AAPLPostTagsKey = @"Tags";

@interface AAPLPost : NSObject

- (instancetype) initWithRecord:(CKRecord *)postRecord NS_DESIGNATED_INITIALIZER;
- (void) loadImageWithKeys:(NSArray *)keys completion:(void(^)())updateBlock;

@property (strong, atomic) CKRecord *postRecord;
@property (strong, atomic) AAPLImage *imageRecord;

@end

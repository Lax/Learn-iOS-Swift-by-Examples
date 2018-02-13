/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLImage.h"

@interface AAPLImage ()

- (instancetype) initWithRecord:(CKRecord *)record isOnServer:(BOOL)onServer;

@end


#pragma mark -

@implementation AAPLImage

// Designated initializer
- (instancetype) initWithRecord:(CKRecord *)record isOnServer:(BOOL)onServer
{
    NSAssert([[record recordType] isEqual:AAPLImageRecordType], @"Wrong type for image record");
    self = [super init];
    if (self != nil)
    {
        _onServer = onServer;
        _record = record;
        
        // Loads thumbnail
        NSURL *thumbFileURL = [_record[AAPLImageThumbnailKey] fileURL];
        NSData *thumbImageData = [NSData dataWithContentsOfURL:thumbFileURL];
        _thumbnail = [[UIImage alloc] initWithData:thumbImageData];
        
        // Loads full size
        NSURL *fullFileURL = [_record[AAPLImageFullsizeKey] fileURL];
        NSData *fullImageData = [NSData dataWithContentsOfURL:fullFileURL];
        _fullImage = [[UIImage alloc] initWithData:fullImageData];
    }
    return self;
}

// Creates an AAPLImage from a UIImage (photo was taken from camera or photo library)
- (instancetype) initWithImage:(UIImage *)image
{    
    CGImageRef CGRawImage = image.CGImage;
    CGImageRef cropped = NULL;
    if(CGImageGetHeight(CGRawImage) > CGImageGetWidth(CGRawImage))
    {
        // Crops from top and bottom evenly
        size_t maxDimen = CGImageGetWidth(CGRawImage);
        size_t offset = (CGImageGetHeight(CGRawImage) - CGImageGetWidth(CGRawImage)) / 2;
        cropped = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(0, offset, maxDimen, maxDimen));
    }
    else if(CGImageGetHeight(CGRawImage) <= CGImageGetWidth(CGRawImage))
    {
        // Crops from left and right evenly
        size_t maxDimen = CGImageGetHeight(CGRawImage);
        size_t offset = (CGImageGetWidth(CGRawImage) - CGImageGetHeight(CGRawImage)) / 2;
        cropped = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(offset, 0, maxDimen, maxDimen));
    }
    // Resizes image to be 1500 x 1500 px and saves it to a temporary file
    UIGraphicsBeginImageContext(CGSizeMake(1500, 1500));
    [[UIImage imageWithCGImage:cropped scale:image.scale orientation:image.imageOrientation] drawInRect:CGRectMake(0,0,1500,1500)];
    UIImage *fullImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"toUploadFull.tmp"];
    NSData *imageData = UIImageJPEGRepresentation(fullImage,0.5);
    [imageData writeToFile:path atomically:YES];
    NSURL *fullURL = [NSURL fileURLWithPath:path];
    
    // Resizes thumbnail to be 200 x 200 px and then saves to different temp file
    UIGraphicsBeginImageContext(CGSizeMake(200, 200));
    [[UIImage imageWithCGImage:cropped scale:image.scale orientation:image.imageOrientation] drawInRect:CGRectMake(0,0,200,200)];
    UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    path = [NSTemporaryDirectory() stringByAppendingString:@"toUploadThumb.tmp"];
    imageData = UIImageJPEGRepresentation(thumbImage,0.5);
    [imageData writeToFile:path atomically:YES];
    NSURL *thumbURL = [NSURL fileURLWithPath:path];
    
    // Cleans up memory that ARC won't touch
    CGImageRelease(cropped);
    
    // Creates Image record type with two assets, full sized image and thumbnail sized image
    CKRecord *newImageRecord = [[CKRecord alloc] initWithRecordType:AAPLImageRecordType];
    newImageRecord[AAPLImageFullsizeKey] = [[CKAsset alloc] initWithFileURL:fullURL];
    newImageRecord[AAPLImageThumbnailKey] = [[CKAsset alloc] initWithFileURL:thumbURL];
    
    // Calls designated initalizer, this is a new image so it is not on the server
    return [self initWithRecord:newImageRecord isOnServer:NO];
}

// Creates an AAPLImage from a CKRecord that has been fetched
- (instancetype) initWithRecord:(CKRecord *)record
{
    return [self initWithRecord:record isOnServer:YES];
}

@end
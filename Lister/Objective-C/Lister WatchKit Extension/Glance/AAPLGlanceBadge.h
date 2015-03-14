/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class that contains all the information needed to display the circular progress indicator badge in the Glance.
*/

@import WatchKit;

/*!
 * The \c AAPLGlanceBadge class is responsible for rendering the glance badge text found in the Glance. It's also
 * responsible for maintaining the image and animation information for the circular indicator displayed in the
 * Glance. The information is calculated based on the percentage of complete items out of the total number
 * of items.
 */
@interface AAPLGlanceBadge : NSObject

- (instancetype)initWithTotalItemCount:(NSInteger)totalItemCount completeItemCount:(NSInteger)completeItemCount;

/// The total number of items.
@property (readonly) NSInteger totalItemCount;

/// The number of complete items.
@property (readonly) NSInteger completeItemCount;

/// The number of incomplete items.
@property (readonly) NSInteger incompleteItemCount;

/// The image name of the image to be used for the Glance badge.
@property (readonly) NSString *imageName;

/// The range of images to display in the Glance badge.
@property (readonly) NSRange imageRange;

/// The length that the Glance badge image will animate.
@property (readonly) NSTimeInterval animationDuration;

/*!
 * The background image to be displayed in the Glance badge. The \c groupBackgroundImage draws the text that
 * containing the number of remaining items to complete.
 */
@property (readonly) UIImage *groupBackgroundImage;

@end

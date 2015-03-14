/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class that contains all the information needed to display the circular progress indicator badge in the Glance.
*/

#import "AAPLGlanceBadge.h"

const NSTimeInterval AAPLGlanceInterfaceControllerMaxDuration = 0.75;

@interface AAPLGlanceBadge ()

@property (readwrite) NSInteger totalItemCount;

@property (readwrite) NSInteger completeItemCount;

@property (readwrite) NSInteger incompleteItemCount;

@property CGFloat percentage;

@property (readonly) NSInteger rangeLength;

/// The color that is used to draw the number of complete items.
@property (readonly) UIColor *completeTextPathColor;

@property (readonly) CGSize groupBackgroundImageSize;

@end

@implementation AAPLGlanceBadge
@dynamic completeTextPathColor;

#pragma mark - Initializers

- (instancetype)initWithTotalItemCount:(NSInteger)totalItemCount completeItemCount:(NSInteger)completeItemCount {
    self = [super init];
    
    if (self) {
        _totalItemCount = totalItemCount;

        _completeItemCount = completeItemCount;
        
        _incompleteItemCount = _totalItemCount - _completeItemCount;
        
        _percentage = _totalItemCount > 0.0 ? (CGFloat)_completeItemCount / (CGFloat)_totalItemCount : 0.0;
        
        _groupBackgroundImageSize = CGSizeMake(136, 101);
    }
    
    return self;
}

#pragma mark - Property Overrides

- (UIColor *)completeTextPathColor {
    return [UIColor colorWithHue:199.0/360.0 saturation:0.64 brightness:0.98 alpha:1.0];
}

- (NSString *)imageName {
    return @"glance-";
}

- (NSRange)imageRange {
    return NSMakeRange(0, self.rangeLength);
}

- (NSTimeInterval)animationDuration {
    return self.percentage * AAPLGlanceInterfaceControllerMaxDuration;
}

- (UIImage *)groupBackgroundImage {
    UIGraphicsBeginImageContextWithOptions(self.groupBackgroundImageSize, false, 2.0);
    
    [self drawCompleteItemsCountInCurrentContext];
    
    UIImage *frame = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return frame;
}

/*!
 * Determines the number of images to animate based on \c percentage. If \c percentage is larger than 1.0,
 * the \c rangeLength is the total number of available images.
 */
- (NSInteger)rangeLength {
    CGFloat normalizedPercentage = self.percentage;
    
    if (normalizedPercentage > 1.0) {
        normalizedPercentage = 1.0;
    }
    else if (normalizedPercentage == 0.0) {
        return 1;
    }
    
    return ceil(self.percentage * 45);
}

#pragma mark - Drawing

/// Draw the text containing the number of complete items.
- (void)drawCompleteItemsCountInCurrentContext {
    CGPoint center = CGPointMake(self.groupBackgroundImageSize.width / 2.0, self.groupBackgroundImageSize.height / 2.0);
    
    NSString *itemsCompleteText = [NSString stringWithFormat:@"%ld", (long)self.completeItemCount];

    NSDictionary *completeAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize: 36],
        NSForegroundColorAttributeName: self.completeTextPathColor
    };
    
    CGSize completeSize = [itemsCompleteText sizeWithAttributes:completeAttributes];
    
    // Build and gather information about the done string.
    NSString *doneText = NSLocalizedString(@"Done", @"");
    NSDictionary *doneAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize: 16],
        NSForegroundColorAttributeName: [UIColor darkGrayColor]
    };
    CGSize doneSize = [doneText sizeWithAttributes:doneAttributes];
    
    CGRect completeRect = CGRectMake(center.x - 0.5 * completeSize.width, center.y - 0.5 * completeSize.height - 0.5 * doneSize.height, completeSize.width, completeSize.height);
    CGRect doneRect = CGRectMake(center.x - 0.5 * doneSize.width, center.y + 0.125 * doneSize.height, doneSize.width, doneSize.height);
    
    [itemsCompleteText drawInRect:CGRectIntegral(completeRect) withAttributes:completeAttributes];

    [doneText drawInRect:CGRectIntegral(doneRect) withAttributes:doneAttributes];
}

@end

/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLPostTableViewCell.h"
#import "AAPLPost.h"

@interface AAPLPostTableViewCell ()

@property (strong, nonatomic) NSString *fontName;
@property (strong, nonatomic) IBOutlet UILabel *textLabelInCell;
@property (strong, nonatomic) IBOutlet UIImageView *imageViewInCell;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end


#pragma mark -

@implementation AAPLPostTableViewCell
- (void)layoutSubviews
{
    [super layoutSubviews];
    UIFont *labelFont = [UIFont fontWithName:self.fontName size:24];
    [self.textLabelInCell setFont:labelFont];
}

- (void) displayInfoForPost:(AAPLPost *)post
{
    // Sets how the cell appears based on the AAPLPost passed in
    [self.activityIndicator startAnimating];
    self.imageViewInCell.image = [post.imageRecord fullImage];
    
    self.fontName = post.postRecord[AAPLPostFontKey];
    self.textLabelInCell.text = post.postRecord[AAPLPostTextKey];
}

@end

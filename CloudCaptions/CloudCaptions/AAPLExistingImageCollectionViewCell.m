/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLExistingImageCollectionViewCell.h"

@interface AAPLExistingImageCollectionViewCell ()

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (strong, atomic) UIVisualEffectView *blurSubview;

@end


#pragma mark -

@implementation AAPLExistingImageCollectionViewCell

- (void) setLoading:(BOOL)loading
{
    if(loading)
    {
        [self.loadingIndicator startAnimating];
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.blurSubview = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.blurSubview.frame = self.thumbnailImage.frame;
        [self.thumbnailImage addSubview:self.blurSubview];
    }
    else
    {
        if(self.blurSubview)
        {
            [self.blurSubview removeFromSuperview];
            self.blurSubview = nil;
        }
        [self.loadingIndicator stopAnimating];
    }
}

@end

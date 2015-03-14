/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UIImageView.
*/

#import "AAPLImageViewController.h"

@implementation AAPLImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // The root view of the view controller set in Interface Builder is a UIImageView.
    UIImageView *imageView = (UIImageView *)self.view;

    imageView.animationImages = @[
        [UIImage imageNamed:@"image_animal_1"],
        [UIImage imageNamed:@"image_animal_2"],
        [UIImage imageNamed:@"image_animal_3"],
        [UIImage imageNamed:@"image_animal_4"],
        [UIImage imageNamed:@"image_animal_5"]
    ];
    
    // We want the image to be scaled to the correct aspect ratio within imageView's bounds.
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // If the image does not have the same aspect ratio as imageView's bounds, then imageView's backgroundColor will be applied to the "empty" space.
    imageView.backgroundColor = [UIColor whiteColor];
    
    imageView.animationDuration = 5;
    [imageView startAnimating];
    
    imageView.isAccessibilityElement = YES;
    imageView.accessibilityLabel = NSLocalizedString(@"Animated", nil);
}

@end

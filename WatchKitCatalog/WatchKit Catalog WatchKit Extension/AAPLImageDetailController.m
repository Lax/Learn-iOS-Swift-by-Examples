/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays images, static and animated. It demonstrates using the image cache to send images from the WatchKit app extension bundle to be stored and used in the WatchKit app bundle. It also demonstrates how to use screenBounds to use the most appropriate sized image for the device at runtime. Finally, this controller demonstrates loading images from the WatchKit Extension bundle and from the WatchKit app bundle.
 */

#import "AAPLImageDetailController.h"

@interface AAPLImageDetailController()

@property (weak, nonatomic) IBOutlet WKInterfaceImage *cachedImage;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *staticImage;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *animatedImage;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *playButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *stopButton;

@end


@implementation AAPLImageDetailController

- (void)awakeWithContext:(id)context {
    // Log the context passed in, if the wearer arrived at this controller via the sample's Glance.
    NSLog(@"Passed in context: %@", context);
    
    // Add image to image cache and then use the cached image.
    UIImage *image = [UIImage imageNamed:@"Bumblebee"];
    if([[WKInterfaceDevice currentDevice] addCachedImage:image name:@"Bumblebee"] == NO) {
        NSLog(@"Image cache full.");
    }
    else {
        [self.cachedImage setImageNamed:@"Bumblebee"];
    }
    
    // Log what's currently residing in the image cache.
    NSLog(@"Currently cached images: %@", [WKInterfaceDevice currentDevice].cachedImages);
    
    // Uses image in WatchKit Extension bundle.
    NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"Walkway"]);
    
    [self.staticImage setImageData:imageData];
}

- (void)willActivate {
    // This method is called when the controller is about to be visible to the wearer.
    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when the controller is no longer visible.
    NSLog(@"%@ did deactivate", self);
}

- (IBAction)playAnimation {
    // Uses images in WatchKit app bundle.
    [self.animatedImage setImageNamed:@"Bus"];
    [self.animatedImage startAnimating];
    
    // Animate with a specific range, duration, and repeat count.
    // [self.animatedImage startAnimatingWithImagesInRange:NSMakeRange(0, 4) duration:2.0 repeatCount:3];
}

- (IBAction)stopAnimation {
    [self.animatedImage stopAnimating];
}

@end

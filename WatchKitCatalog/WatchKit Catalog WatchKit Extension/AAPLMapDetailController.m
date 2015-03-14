/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays a map and demonstrates use of setting its coordinate region, zoom level, and addition and removal of annotations.
 */

#import "AAPLMapDetailController.h"

@interface AAPLMapDetailController()

@property (weak, nonatomic) IBOutlet WKInterfaceMap *map;
@property (nonatomic) MKCoordinateRegion currentRegion;
@property (nonatomic) MKCoordinateSpan currentSpan;

@property (weak, nonatomic) IBOutlet WKInterfaceButton *appleButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *tokyoButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *inButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *outButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *pinsButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *imagesButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *removeAllButton;

@end


@implementation AAPLMapDetailController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        // Initialize variables here.
        // Configure interface objects here.
        
        _currentSpan = MKCoordinateSpanMake(1.0f, 1.0f);
    }

    return self;
}

- (void)willActivate {
    // This method is called when the controller is about to be visible to the wearer.
    NSLog(@"%@ will activate", self);
    
    [self goToApple];
}

- (void)didDeactivate {
    // This method is called when the controller is no longer visible.
    NSLog(@"%@ did deactivate", self);
}

- (IBAction)goToTokyo {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(35.4f, 139.4f);
    
    [self setMapToCoordinate:coordinate];
}

- (IBAction)goToApple {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(37.331793f, -122.029584f);

    [self setMapToCoordinate:coordinate];
}

- (void)setMapToCoordinate:(CLLocationCoordinate2D)coordinate {
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, self.currentSpan);
    self.currentRegion = region;
    
    MKMapPoint newCenterPoint = MKMapPointForCoordinate(coordinate);
    
    [self.map setVisibleMapRect:MKMapRectMake(newCenterPoint.x, newCenterPoint.y, self.currentSpan.latitudeDelta, self.currentSpan.longitudeDelta)];
    [self.map setRegion:region];
}

- (IBAction)zoomOut {
    MKCoordinateSpan span = MKCoordinateSpanMake(self.currentSpan.latitudeDelta * 2, self.currentSpan.longitudeDelta * 2);
    MKCoordinateRegion region = MKCoordinateRegionMake(self.currentRegion.center, span);

    self.currentSpan = span;
    [self.map setRegion:region];
}

- (IBAction)zoomIn {
    MKCoordinateSpan span = MKCoordinateSpanMake(self.currentSpan.latitudeDelta * 0.5f, self.currentSpan.longitudeDelta * 0.5f);
    MKCoordinateRegion region = MKCoordinateRegionMake(self.currentRegion.center, span);
    
    self.currentSpan = span;
    [self.map setRegion:region];
}

- (IBAction)addPinAnnotations {
    [self.map addAnnotation:self.currentRegion.center withPinColor:WKInterfaceMapPinColorRed];
    
    CLLocationCoordinate2D greenCoordinate = CLLocationCoordinate2DMake(self.currentRegion.center.latitude, self.currentRegion.center.longitude - 0.3f);
    [self.map addAnnotation:greenCoordinate withPinColor:WKInterfaceMapPinColorGreen];
    
    CLLocationCoordinate2D purpleCoordinate = CLLocationCoordinate2DMake(self.currentRegion.center.latitude, self.currentRegion.center.longitude + 0.3f);
    [self.map addAnnotation:purpleCoordinate withPinColor:WKInterfaceMapPinColorPurple];
}

- (IBAction)addImageAnnotations {
    CLLocationCoordinate2D firstCoordinate = CLLocationCoordinate2DMake(self.currentRegion.center.latitude, self.currentRegion.center.longitude - 0.3f);
    
    // Uses image in WatchKit app bundle.
    [self.map addAnnotation:firstCoordinate withImageNamed:@"Whale" centerOffset:CGPointZero];
    
    CLLocationCoordinate2D secondCoordinate = CLLocationCoordinate2DMake(self.currentRegion.center.latitude, self.currentRegion.center.longitude + 0.3f);
    
    // Uses image in WatchKit Extension bundle.
    UIImage *image = [UIImage imageNamed:@"Bumblebee"];
    [self.map addAnnotation:secondCoordinate withImage:image centerOffset:CGPointZero];
}

- (IBAction)removeAll {
    [self.map removeAllAnnotations];
}

@end

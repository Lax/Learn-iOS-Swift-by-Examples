/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

*/

#import "SetupViewController.h"
#import <CoreLocation/CoreLocation.h>

NSString * const kSetupInfoKeyAccuracy = @"SetupInfoKeyAccuracy";
NSString * const kSetupInfoKeyDistanceFilter = @"SetupInfoKeyDistanceFilter";
NSString * const kSetupInfoKeyTimeout = @"SetupInfoKeyTimeout";

static NSString * const kAccuracyNameKey = @"AccuracyNameKey";
static NSString * const kAccuracyValueKey = @"AccuracyValueKey";


@interface SetupViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) NSMutableDictionary *setupInfo;
@property (nonatomic, strong) NSArray *accuracyOptions;
@property (nonatomic, assign) BOOL configureForTracking;

@property (nonatomic, weak) IBOutlet UIPickerView *accuracyPicker;
@property (nonatomic, weak) IBOutlet UISlider *slider;

@end


#pragma mark -

@implementation SetupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *options = [NSMutableArray array];
    [options addObject:@{kAccuracyNameKey: NSLocalizedString(@"AccuracyBest", @"AccuracyBest"), kAccuracyValueKey: @(kCLLocationAccuracyBest)}];
    [options addObject:@{kAccuracyNameKey: NSLocalizedString(@"Accuracy10", @"Accuracy10"), kAccuracyValueKey: @(kCLLocationAccuracyNearestTenMeters)}];
    [options addObject:@{kAccuracyNameKey: NSLocalizedString(@"Accuracy100", @"Accuracy100"), kAccuracyValueKey: @(kCLLocationAccuracyHundredMeters)}];
    [options addObject:@{kAccuracyNameKey: NSLocalizedString(@"Accuracy1000", @"Accuracy1000"), kAccuracyValueKey: @(kCLLocationAccuracyKilometer)}];
    [options addObject:@{kAccuracyNameKey: NSLocalizedString(@"Accuracy3000", @"Accuracy3000"), kAccuracyValueKey: @(kCLLocationAccuracyThreeKilometers)}];
    self.accuracyOptions = options;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.accuracyPicker selectRow:2 inComponent:0 animated:NO];
    self.setupInfo = [NSMutableDictionary dictionary];
    self.setupInfo[kSetupInfoKeyDistanceFilter] = @100.0;
    self.setupInfo[kSetupInfoKeyTimeout] = @30.0;
    self.setupInfo[kSetupInfoKeyAccuracy] = @(kCLLocationAccuracyHundredMeters);
}


#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    if ([self.delegate respondsToSelector:@selector(setupViewController:didFinishSetupWithInfo:)]) {
        [self.delegate setupViewController:self didFinishSetupWithInfo:self.setupInfo];
    }
}

- (IBAction)sliderChangedValue:(id)sender {
    if (self.configureForTracking) {
        self.setupInfo[kSetupInfoKeyDistanceFilter] = @(pow(10, [(UISlider *)sender value]));
    } else {
        self.setupInfo[kSetupInfoKeyTimeout] = [NSNumber numberWithDouble:[(UISlider *)sender value]];
    }
}


#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 5;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSDictionary *optionForRow = self.accuracyOptions[row];
    return optionForRow[kAccuracyNameKey];
}


#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSDictionary *optionForRow = self.accuracyOptions[row];
    self.setupInfo[kSetupInfoKeyAccuracy] = optionForRow[kAccuracyValueKey];
}

@end

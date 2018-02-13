/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

*/

#import "TrackLocationViewController.h"
#import "LocationDetailViewController.h"
#import "SetupViewController.h"
#import "CLLocation+Strings.h"

@interface TrackLocationViewController () <SetupViewControllerDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) SetupViewController *setupViewController;
@property (nonatomic, weak) IBOutlet UIButton *startButton;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locationMeasurements;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSString *stateString;

@end


#pragma mark -

@implementation TrackLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _locationMeasurements = [NSMutableArray array];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UINavigationController *nv = segue.destinationViewController;
    _setupViewController = nv.viewControllers[0];
    self.setupViewController.delegate = self;
}

- (NSDateFormatter *)dateFormatter {
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    }
    return _dateFormatter;
}


#pragma mark - Actions

- (IBAction)start:(id)sender {
    [self.navigationController presentViewController:self.setupViewController animated:YES completion:nil];
}

// The reset method allows the user to repeatedly test the location functionality.
// In addition to discarding all of the location measurements from the previous "run",
// it animates a transition in the user interface between the table which displays location
// data and the start button and description label presented at launch.
//
- (void)reset {
    [self.locationMeasurements removeAllObjects];
    
    // fade in the rest of the UI and fade out the table view
    [UIView animateWithDuration:0.6f animations:^(void) {
        self.startButton.alpha = 1.0;
        self.descriptionLabel.alpha = 1.0;
        self.tableView.alpha = 0.0;
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    } completion:^(BOOL finished) {
        if (finished) {
            //..
        }
    }];
}


#pragma mark - Location Manager Interactions

// This method is invoked when the user hits "Done" in the setup view controller.
// The options chosen by the user are passed in as a dictionary. The keys for this dictionary
// are declared in SetupViewController.h.
//
- (void)setupViewController:(SetupViewController *)controller didFinishSetupWithInfo:(NSDictionary *)setupInfo {
    self.startButton.alpha = 0.0;
    self.descriptionLabel.alpha = 0.0;
    self.tableView.alpha = 1.0;
    
    // Create the manager object 
    _locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // This is the most important property to set for the manager. It ultimately determines how the manager will
    // attempt to acquire location and thus, the amount of power that will be consumed.
    self.locationManager.desiredAccuracy = [setupInfo[kSetupInfoKeyAccuracy] doubleValue];
    
    // When "tracking" the user, the distance filter can be used to control the frequency with which location measurements
    // are delivered by the manager. If the change in distance is less than the filter, a location will not be delivered.
    self.locationManager.distanceFilter = [setupInfo[kSetupInfoKeyDistanceFilter] doubleValue];
    
    // Once configured, the location manager must be "started".
    //
    // for iOS 8, specific user level permission is required,
    // "when-in-use" authorization grants access to the user's location
    //
    // important: be sure to include NSLocationWhenInUseUsageDescription along with its
    // explanation string in your Info.plist or startUpdatingLocation will not work.
    //
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    
    self.stateString = NSLocalizedString(@"Tracking", @"Tracking");
    [self.tableView reloadData];
    
    UIBarButtonItem *resetItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reset", @"Reset")
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(reset)];
    [self.navigationItem setLeftBarButtonItem:resetItem animated:YES];
}

// We want to get and store a location measurement that meets the desired accuracy.
// For this example, we are going to use horizontal accuracy as the deciding factor.
// In other cases, you may wish to use vertical accuracy, or both together.
//
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) {
        return;
    }
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    //
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) {
        return;
    }
    
    // store all of the measurements, just so we can see what kind of data we might receive
    [self.locationMeasurements addObject:newLocation];
    
    // update the display with the new location data
    [self.tableView reloadData];    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager is currently unable to get the location.
    if ([error code] != kCLErrorLocationUnknown) {
        [self stopUpdatingLocationWithMessage:NSLocalizedString(@"Error", @"Error")];
    }
}

- (void)stopUpdatingLocationWithMessage:(NSString *)state {
    self.stateString = state;
    [self.tableView reloadData];
    
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}


#pragma mark - UITableViewDataSource

// The table view has two sections. The first has 1 row which displays status information.
// The second has a row for each valid location object received from the location manager.
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return (self.locationMeasurements.count > 0) ? 2 : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *headerTitle = nil;
    switch (section) {
        case 0: {
            headerTitle = NSLocalizedString(@"Status", @"Status");
            break;
        }
        default: {
            headerTitle = NSLocalizedString(@"All Measurements", @"All Measurements");
            break;
        }
    }
    return headerTitle;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    NSInteger numRows = 0;
    switch (section) {
        case 0: {
            numRows = 1;
            break;
        }
        default: {
            numRows = self.locationMeasurements.count;
            break;
        }
    }
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    switch (indexPath.section) {
        case 0: {
            // The cell for the status row uses the cell style "UITableViewCellStyleValue1", which has a label on the left side of the cell with left-aligned and black text; on the right side is a label that has smaller blue text and is right-aligned. An activity indicator has been added to the cell and is animated while the location manager is updating. The cell's text label displays the current state of the manager.
            static NSString * const kStatusCellID = @"StatusCellID";
            static NSInteger const kStatusCellActivityIndicatorTag = 2;
            
            UIActivityIndicatorView *activityIndicator = nil;
            cell = [table dequeueReusableCellWithIdentifier:kStatusCellID];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kStatusCellID];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                CGRect frame = activityIndicator.frame;
                frame.origin = CGPointMake(290.0, 12.0);
                activityIndicator.frame = frame;
                activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                activityIndicator.tag = kStatusCellActivityIndicatorTag;
                [cell.contentView addSubview:activityIndicator];
            } else {
                activityIndicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:kStatusCellActivityIndicatorTag];
            }
            cell.textLabel.text = self.stateString;
            if ([self.stateString isEqualToString:NSLocalizedString(@"Tracking", @"Tracking")]) {
                if (activityIndicator.isAnimating == NO) [activityIndicator startAnimating];
            } else {
                if (activityIndicator.isAnimating) [activityIndicator stopAnimating];
            }
            break;
        }
            
        default: {
            // The cells for the location rows use the cell style "UITableViewCellStyleSubtitle", which has a left-aligned label across the top and a left-aligned label below it in smaller gray text. The text label shows the coordinates for the location and the detail text label shows its timestamp.
            static NSString * const kOtherMeasurementsCellID = @"OtherMeasurementsCellID";
            cell = [table dequeueReusableCellWithIdentifier:kOtherMeasurementsCellID];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kOtherMeasurementsCellID];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            CLLocation *location = self.locationMeasurements[indexPath.row];
            cell.textLabel.text = location.localizedCoordinateString;
            cell.detailTextLabel.text = [self.dateFormatter stringFromDate:location.timestamp];
            break;
        }
    }
    return cell;
}


#pragma mark - UITableViewDelegate

// Delegate method invoked before the user selects a row.
// In this sample, we use it to prevent selection in the first section of the table view.
//
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 0) ? nil : indexPath;
}

// Delegate method invoked after the user selects a row. Selecting a row containing a location object
// will navigate to a new view controller displaying details about that location.
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    CLLocation *location = self.locationMeasurements[indexPath.row];
    
    LocationDetailViewController *locationDetailViewController = [[LocationDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
    locationDetailViewController.location = location;
    [self.navigationController pushViewController:locationDetailViewController animated:YES];
}

@end

/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays details about a song.
 */

#import "SongDetailsController.h"
#import "Song.h"
#import "Category.h"

@interface SongDetailsController ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end


#pragma mark -

@implementation SongDetailsController

- (NSDateFormatter *)dateFormatter {
    
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return _dateFormatter;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localeChanged:)
                                                 name:NSCurrentLocaleDidChangeNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSCurrentLocaleDidChangeNotification
                                                  object:nil];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *kCellIdentifier = @"SongDetailCell";
    
    UITableViewCell *cell = (UITableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = NSLocalizedString(@"album", @"album label");
            cell.detailTextLabel.text = self.song.album;
        } break;
        case 1: {
            cell.textLabel.text = NSLocalizedString(@"artist", @"artist label");
            cell.detailTextLabel.text = self.song.artist;
        } break;
        case 2: {
            cell.textLabel.text = NSLocalizedString(@"category", @"category label");
            cell.detailTextLabel.text = self.song.category.name;
        } break;
        case 3: {
            cell.textLabel.text = NSLocalizedString(@"released", @"released label");
            cell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.song.releaseDate];
        } break;
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section {
    
    return self.song.title;
}


#pragma mark - Locale changes

- (void)localeChanged:(NSNotification *)notif
{
    // The user changed the locale (region format) in Settings, so we are notified here to
    // update the date format in the table view cells.
    //
    [self.tableView reloadData];
}

@end

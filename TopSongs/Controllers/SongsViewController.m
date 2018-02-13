/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Lists all songs in a table view. Also allows sorting and grouping via bottom segmented control.
 */

#import "SongsViewController.h"
#import "SongDetailsController.h"
#import "Song.h"

@interface SongsViewController ()

@property (nonatomic, strong) SongDetailsController *detailController;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) IBOutlet UISegmentedControl *fetchSectioningControl;

@end


#pragma mark -

@implementation SongsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self fetch];   // Start fetching songs from our data store.
}

- (IBAction)changeFetchSectioning:(id)sender {
    
    self.fetchedResultsController = nil;
    [self fetch];
}

- (void)fetch {
    
    NSError *error = nil;
    BOOL success = [self.fetchedResultsController performFetch:&error];
    NSAssert2(success, @"Unhandled error performing fetch at SongsViewController.m, line %d: %@", __LINE__, [error localizedDescription]);
    [self.tableView reloadData];
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:self.managedObjectContext];
        NSArray *sortDescriptors = nil;
        NSString *sectionNameKeyPath = nil;
        if (self.fetchSectioningControl.selectedSegmentIndex == 1) {
            sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"category.name" ascending:YES], [[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES]];
            sectionNameKeyPath = @"category.name";
        } else {
            sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"rank" ascending:YES]];
        }
        fetchRequest.sortDescriptors = sortDescriptors;
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:sectionNameKeyPath
                                                                                   cacheName:nil];
    }    
    return _fetchedResultsController;
}    


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = (self.fetchedResultsController.sections)[section];
    return sectionInfo.numberOfObjects;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = (self.fetchedResultsController.sections)[section];
    if (self.fetchSectioningControl.selectedSegmentIndex == 0) {
        return [NSString stringWithFormat:NSLocalizedString(@"Top %d songs", @"Top %d songs"), sectionInfo.numberOfObjects];
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ - %d songs", @"%@ - %d songs"), sectionInfo.name, sectionInfo.numberOfObjects];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)table {
    
    // Return list of section titles to display in section index view (e.g. "ABCD...Z#").
    return self.fetchedResultsController.sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)table sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    
    // Tell table which section corresponds to section title/index (e.g. "B",1)).
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *kCellIdentifier = @"SongCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    Song *song = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text =
        [NSString stringWithFormat:NSLocalizedString(@"#%d %@", @"#%d %@"), song.rank.integerValue, song.title];
    
    return cell;
}


#pragma mark - Segue support

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showDetail"]) {
        SongDetailsController *detailsController = (SongDetailsController *)segue.destinationViewController;
        NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
        detailsController.song = [self.fetchedResultsController objectAtIndexPath:selectedIndexPath];
    }
}

@end

/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

@import CloudKit;
@import MobileCoreServices;

#import "AAPLTableViewController.h"
#import "AAPLAppDelegate.h"
#import "AAPLPostTableViewCell.h"
#import "AAPLSubmitPostViewController.h"
#import "AAPLSubscriptionController.h"
#import "AAPLPostManager.h"

static NSString * const cellReuseIdentifier = @"post";

@interface AAPLTableViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, UISearchBarDelegate, AAPLExistingImageViewControllerDelegate, AAPLSubmitPostViewControllerDelegate>

@property (strong, atomic) AAPLPostManager *postManager;

@end


#pragma mark -

@implementation AAPLTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // We tell the App Delegate that we're the tableController so it knows to let us know when a push is received
    ((AAPLAppDelegate *)[[UIApplication sharedApplication] delegate]).tableController = self;
    
    // The post manager handles fetching and organizing all the posts. When it finishes a fetch it needs to know how to update the tableView
    self.postManager = [[AAPLPostManager alloc] initWithReloadHandler:^{
        [self.tableView reloadData];
    }];
    [self.postManager loadBatch];
    
    // Creates pull to refresh and tells postManager so it can endRefreshing when updates are done
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self.postManager action:@selector(loadNewPosts) forControlEvents:UIControlEventValueChanged];
    self.postManager.refreshControl = self.refreshControl;
    
    // Sets up navigation bar items
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    self.navigationItem.leftBarButtonItem = [[AAPLSubscriptionController alloc] initWithCustomView:indicator];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(newPostSelection)];
    
}

- (void) loadNewPostsWithRecordID:(CKRecordID *)recordID
{
    // Called when AAPLAppDelegate receives a push notification
    // The post that triggered the push may not be indexed yet, so a fetch on predicate might not see it.
    // We can still fetch by recordID though
    CKDatabase *publicDB = [CKContainer defaultContainer].publicCloudDatabase;
    [publicDB fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
        AAPLPost *postThatFiredPush = [[AAPLPost alloc] initWithRecord:record];
        [postThatFiredPush loadImageWithKeys:@[AAPLImageFullsizeKey] completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
        [self.postManager loadNewPostsWithAAPLPost:postThatFiredPush];
    }];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // One table cell for each post we have
    return self.postManager.postCells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Uses a tableViewCell to display AAPLPost info
    AAPLPostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[AAPLPostTableViewCell alloc] init];
    }
    AAPLPost *tableCellPost = (self.postManager.postCells)[indexPath.row];
    [cell displayInfoForPost:tableCellPost];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Programatically sets cell height to equal the device width, makes all cells square
    return self.view.bounds.size.width;
}

#pragma mark Scroll View Delegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Checks to see if the user has scrolled five posts from the bottom and if we want to update
    CGPoint tableBottom = CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y + scrollView.bounds.size.height);
    if([self.tableView indexPathForRowAtPoint:tableBottom].row + 5 > self.postManager.postCells.count && self.postManager.postCells.count > 0)
    {
        [self.postManager loadBatch];
    }
}

#pragma mark UISearchBarDelegate

- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // Tells the postManager to reset the tag string with the new tag string
    [self.postManager resetWithTagString:searchBar.text];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [self.postManager resetWithTagString:@""];
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
}

#pragma mark - Compose New Post

- (void) newPostSelection {
    NSString *alertTitle = NSLocalizedString(@"ComposeAlertControllerTitle", @"Title of alert controller that lets user compose a post");
    NSString *takePhotoButton = NSLocalizedString(@"CameraButton", @"Title for button opens up camera to take photo");
    NSString *uploadButton = NSLocalizedString(@"UploadButton", @"Title for button that opens photo library to select photo");
    NSString *selectButton = NSLocalizedString(@"ThumbnailButton", @"Title for button that loads thumbnails from CloudKit");
    
    // Shows the user options for selecting an image to post
    UIAlertController *picMethod = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    picMethod.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popPresenter = picMethod.popoverPresentationController;
    popPresenter.barButtonItem = self.navigationItem.rightBarButtonItem;
    
    __weak AAPLTableViewController *weakSelf = self;
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:takePhotoButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = weakSelf;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [weakSelf presentViewController:imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction *uploadPhoto = [UIAlertAction actionWithTitle:uploadButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = weakSelf;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [weakSelf presentViewController:imagePicker animated:YES completion:nil];
    }];
    
    UIAlertAction *selectExisting = [UIAlertAction actionWithTitle:selectButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf performSegueWithIdentifier:@"selectExisting" sender:nil];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [picMethod addAction:takePhoto];
    [picMethod addAction:uploadPhoto];
    [picMethod addAction:selectExisting];
    [picMethod addAction:cancel];
    [self presentViewController:picMethod animated:YES completion:nil];
}

#pragma mark UIImagePickerControllerDelegate

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // UIImagePickerController media types default to kUTTypeImage so we should only get images here
    // Dismisses imagePicker and pulls up SubmitPostViewController
    AAPLImage *imageRecord = [[AAPLImage alloc] initWithImage:info[UIImagePickerControllerOriginalImage]];
    __weak AAPLTableViewController *weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        [weakSelf performSegueWithIdentifier:@"newPost" sender:imageRecord];
    }];
}

#pragma mark AAPLExistingImageViewControllerDelegate
-(void) AAPLExisitingImageViewController:(AAPLExistingImageViewController *)controller selectedImage:(AAPLImage *)image
{
    // Gets called when the user taps on an image in the collection view
    // Dismisses collection view and pulls up a SubmitPostViewController
    __weak AAPLTableViewController *weakSelf = self;
    [controller dismissViewControllerAnimated:YES completion:^{
        [weakSelf performSegueWithIdentifier:@"newPost" sender:image];
    }];
}

#pragma mark - AAPLSubmitPostViewControllerDelegate

- (void) AAPLSubmitPostViewController:(AAPLSubmitPostViewController *)controller postedRecord:(AAPLPost *)post
{
    [self.postManager loadNewPostsWithAAPLPost:post];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"selectExisting"])
    {
        ((AAPLExistingImageViewController *)[segue destinationViewController]).delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"newPost"])
    {
        [[segue destinationViewController] setImageRecord:sender];
        ((AAPLSubmitPostViewController *)[segue destinationViewController]).delegate = self;
    }
    else
    {
        NSLog(@"Unhandled segue");
        abort();
    }
}

@end
/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

@import CloudKit;
#import "AAPLImage.h"
#import "AAPLSubmitPostViewController.h"
#import "AAPLTableViewController.h"

typedef NS_ENUM(NSInteger, AAPLSubmissionErrorResponse) {
    AAPLSubmissionErrorIgnore,
    AAPLSubmissionErrorRetry,
    AAPLSubmissionErrorSuccess,
};

@interface AAPLSubmitPostViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIPickerView *fontPicker;
@property (weak, nonatomic) IBOutlet UITextField *hiddenText;
@property (weak, nonatomic) IBOutlet UITextField *tagField;
@property (weak, nonatomic) IBOutlet UILabel *imageLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (strong, atomic) AAPLImage *imageRecord;

@end


#pragma mark -

@implementation AAPLSubmitPostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Sets the preview to the image record passed in
    self.imageView.image = self.imageRecord.fullImage;
    
    // sets up font picker and picks a random font
    self.fontPicker.delegate = self;
    self.fontPicker.dataSource = self;
    u_int randomFont = arc4random() % [UIFont familyNames].count;
    [self.fontPicker selectRow:randomFont inComponent:0 animated:NO];
 
    // Sets up the label with random font
    self.imageLabel.font = [UIFont fontWithName:[UIFont familyNames][randomFont] size:24];
    
    // sets delegates so enter dimsisses keyboard
    self.tagField.delegate = self;
    self.hiddenText.delegate = self;
    
    // typing into the hiddent text field automatically updates the label on the image
    [self.hiddenText addTarget:self action:@selector(didEditField:) forControlEvents:UIControlEventEditingChanged];
    
    // start editing the text field as soon as the view is done loading
    [self.hiddenText becomeFirstResponder];
}

- (IBAction)editText:(id)sender {
    // Pulls up the keyboard for the hidden text field when photo is tapped
    [self.hiddenText becomeFirstResponder];
}

- (IBAction)cancelPost:(id)sender {
    // Hides the keyboards and then returns back to AAPLSubmitPostViewController
    [self.hiddenText endEditing:YES];
    [self.tagField endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)publishPost:(id)sender {
    // Prevents multiple posting, locks as soon as a post is made
    self.postButton.action = NULL;
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    self.postButton.customView = indicator;
    
    // Hides the keyboards and dispatches a UI update to show the upload progress
    [self.hiddenText endEditing:YES];
    [self.tagField endEditing:YES];
    self.progressBar.hidden = NO;
        
    // Creates post record type and initizalizes all of its values
    CKRecord *newRecord = [[CKRecord alloc] initWithRecordType:AAPLPostRecordType];
    newRecord[AAPLPostFontKey] = self.imageLabel.font.fontName;
    newRecord[AAPLPostImageRefKey] = [[CKReference alloc] initWithRecordID:self.imageRecord.record.recordID action:CKReferenceActionDeleteSelf];
    newRecord[AAPLPostTextKey] = self.hiddenText.text;
    newRecord[AAPLPostTagsKey] = [self.tagField.text.lowercaseString componentsSeparatedByString:@" "];
    
    AAPLPost *newPost = [[AAPLPost alloc] initWithRecord:newRecord];
    newPost.imageRecord = self.imageRecord;
    
    // Only upload image record if it is not on server, otherwise just upload the new post record
    NSArray *recordsToSave = self.imageRecord.isOnServer ? @[newRecord] : @[newRecord, self.imageRecord.record];
    CKModifyRecordsOperation *saveOp = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:recordsToSave recordIDsToDelete:nil];
    saveOp.perRecordProgressBlock = ^(CKRecord *record, double progress)
    {
        // Image record type is probably going to take the longest to upload. Reflect it's progress in the progress bar
        if([record.recordType isEqual:AAPLImageRecordType])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressBar setProgress:progress*0.95 animated:YES];
            });
        }
    };
    
    // When completed it notifies the tableView to add the post we just uploaded, displays error if it didn't work
    saveOp.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *operationError){
        AAPLSubmissionErrorResponse errorResponse = [self handleError:operationError];
        if(errorResponse == AAPLSubmissionErrorSuccess)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
            // Tells delegate to update so it can display our new post
            if([self.delegate respondsToSelector:@selector(AAPLSubmitPostViewController:postedRecord:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate AAPLSubmitPostViewController:self postedRecord:newPost];
                });
            }
        }
        else if(errorResponse == AAPLSubmissionErrorRetry)
        {
            NSNumber *retryAfter = operationError.userInfo[CKErrorRetryAfterKey] ?: @3;
            NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [operationError description], retryAfter);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.intValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self publishPost:sender];
            });
        }
        else if(errorResponse == AAPLSubmissionErrorIgnore)
        {
            NSLog(@"Error saving record: %@", [operationError description]);
            
            NSString *errorTitle = NSLocalizedString(@"ErrorTitle", @"Title of alert notifying of error");
            NSString *dismissButton = NSLocalizedString(@"DismissError", @"Alert dismiss button string");
            NSString *errorMessage;
            if([operationError code] == CKErrorNotAuthenticated) errorMessage = NSLocalizedString(@"NotAuthenticatedErrorMessage", @"Error message, not logged in");
            else errorMessage = NSLocalizedString(@"UploadFailedErrorMessage", @"Non recoverable upload failed error");
                
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:dismissButton style:UIAlertActionStyleCancel handler:nil]];
            
            self.postButton.action = @selector(publishPost:);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
                self.progressBar.hidden = YES;
                self.postButton.customView = nil;
            });
        }
    };
    [[CKContainer defaultContainer].publicCloudDatabase addOperation:saveOp];
}

- (AAPLSubmissionErrorResponse) handleError:(NSError *)error
{
    if (error == nil) {
        return AAPLSubmissionErrorSuccess;
    }
    switch ([error code])
    {
        case CKErrorUnknownItem:
            // This error occurs if it can't find the subscription named autoUpdate. (It tries to delete one that doesn't exits or it searches for one it can't find)
            // This is okay and expected behavior
            return AAPLSubmissionErrorIgnore;
            break;
        case CKErrorNetworkUnavailable:
        case CKErrorNetworkFailure:
            // A reachability check might be appropriate here so we don't just keep retrying if the user has no service
        case CKErrorServiceUnavailable:
        case CKErrorRequestRateLimited:
            return AAPLSubmissionErrorRetry;
            break;
            
        case CKErrorPartialFailure:
            // This shouldn't happen on a query operation
        case CKErrorNotAuthenticated:
        case CKErrorBadDatabase:
        case CKErrorIncompatibleVersion:
        case CKErrorBadContainer:
        case CKErrorPermissionFailure:
        case CKErrorMissingEntitlement:
            // This app uses the publicDB with default world readable permissions
        case CKErrorAssetFileNotFound:
        case CKErrorAssetFileModified:
            // Users don't really have an option to delete files so this shouldn't happen
        case CKErrorQuotaExceeded:
            // We should not retry if it'll exceed our quota
        case CKErrorOperationCancelled:
            // Nothing to do here, we intentionally cancelled
        case CKErrorInvalidArguments:
        case CKErrorResultsTruncated:
        case CKErrorServerRecordChanged:
        case CKErrorChangeTokenExpired:
        case CKErrorBatchRequestFailed:
        case CKErrorZoneBusy:
        case CKErrorZoneNotFound:
        case CKErrorLimitExceeded:
        case CKErrorUserDeletedZone:
            // All of these errors are irrelevant for this save operation. We're only saving new records, not modifying old ones
        case CKErrorInternalError:
        case CKErrorServerRejectedRequest:
        case CKErrorConstraintViolation:
            //Non-recoverable, should not retry
        default:
            return AAPLSubmissionErrorIgnore;
            break;
    }
}

#pragma mark UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    // This method is called to dismiss the keyboard
    [self.view endEditing:YES];
    return YES;
}

-(void)didEditField:(id)sender
{
    // This is called when the user types into a textField. Keeps the label up to date
    self.imageLabel.text = self.hiddenText.text;
}

#pragma mark UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    // Only one column in the font picker
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    // One row for each font in the familyNames array
    return [UIFont familyNames].count;
}

#pragma mark UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    // Sets each item in pickerview as the name of each font with its typeface in its own font
    // (e.g. Helvetica appears in Helvetica, Courier New appears in Courier New
    UILabel *fontLabel = (UILabel *) view;
    if(!fontLabel)
    {
        fontLabel = [[UILabel alloc] init];
    }
    fontLabel.font = [UIFont fontWithName:[UIFont familyNames][row] size:24];
    fontLabel.text = [UIFont familyNames][row];
    return (UIView *)fontLabel;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    // This method sets the height of each row in the pickerView
    return 35;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // Sets the imageLabel font to the selected font
    NSString *fontName = [UIFont familyNames][row];
    self.imageLabel.font = [UIFont fontWithName:fontName size:24];
    
}

@end

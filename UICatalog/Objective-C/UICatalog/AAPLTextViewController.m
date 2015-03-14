/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A view controller that demonstrates how to use UITextView.
 */

#import "AAPLTextViewController.h"

@interface AAPLTextViewController()<UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;

// Used to adjust the text view's height when the keyboard hides and shows.
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textViewBottomLayoutGuideConstraint;

@end


#pragma mark -

@implementation AAPLTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureTextView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Listen for changes to keyboard visibility so that we can adjust the text view accordingly.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}


#pragma mark - Keyboard Event Notifications

- (void)handleKeyboardNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    
    NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // Convert the keyboard frame from screen to view coordinates.
    CGRect keyboardScreenBeginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect keyboardScreenEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGRect keyboardViewBeginFrame = [self.view convertRect:keyboardScreenBeginFrame fromView:self.view.window];
    CGRect keyboardViewEndFrame = [self.view convertRect:keyboardScreenEndFrame fromView:self.view.window];
    CGFloat originDelta = keyboardViewEndFrame.origin.y - keyboardViewBeginFrame.origin.y;
    
    // The text view should be adjusted, update the constant for this constraint.
    self.textViewBottomLayoutGuideConstraint.constant -= originDelta;

    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];

    // Scroll to the selected text once the keyboard frame changes.
    NSRange selectedRange = self.textView.selectedRange;
    [self.textView scrollRangeToVisible:selectedRange];
}


#pragma mark - Configuration

- (void)configureTextView {
    UIFontDescriptor *bodyFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    self.textView.font = [UIFont fontWithDescriptor:bodyFontDescriptor size:0];

    self.textView.textColor = [UIColor blackColor];
    self.textView.backgroundColor = [UIColor whiteColor];
    self.textView.scrollEnabled = YES;

    // Let's modify some of the attributes of the attributed string.
    // You can modify these attributes yourself to get a better feel for what they do.
    // Note that the initial text is visible in the storyboard.
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];

    NSString *text = self.textView.text;

    // Find the range of each element to modify.
    NSRange boldRange = [text rangeOfString:NSLocalizedString(@"bold", nil)];
    NSRange highlightedRange = [text rangeOfString:NSLocalizedString(@"highlighted", nil)];
    NSRange underlinedRange = [text rangeOfString:NSLocalizedString(@"underlined", nil)];
    NSRange tintedRange = [text rangeOfString:NSLocalizedString(@"tinted", nil)];

    // Add bold.
    UIFontDescriptor *boldFontDescriptor = [self.textView.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldFontDescriptor size:0];
    [attributedText addAttribute:NSFontAttributeName value:boldFont range:boldRange];

    // Add highlight.
    [attributedText addAttribute:NSBackgroundColorAttributeName value:[UIColor aapl_applicationGreenColor] range:highlightedRange];

    // Add underline.
    [attributedText addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:underlinedRange];

    // Add tint.
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor aapl_applicationBlueColor] range:tintedRange];
    
    // Add an image attachment.
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    UIImage *image = [UIImage imageNamed:@"text_view_attachment"];
    textAttachment.image = image;
    textAttachment.bounds = CGRectMake(0, 0, image.size.width, image.size.height);

    NSAttributedString *textAttachmentString = [NSAttributedString attributedStringWithAttachment:textAttachment];
    [attributedText appendAttributedString:textAttachmentString];
    
    self.textView.attributedText = attributedText;
}


#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // Provide a "Done" button for the user to select to signify completion with writing text in the text view.
    UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonItemClicked)];

    [self.navigationItem setRightBarButtonItem:doneBarButtonItem animated:YES];
}


#pragma mark - Actions

- (void)doneBarButtonItemClicked {
    // Dismiss the keyboard by removing it as the first responder.
    [self.textView resignFirstResponder];

    [self.navigationItem setRightBarButtonItem:nil animated:YES];
}

@end

/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An \c NSTableCellView subclass that has a few controls that represent the state of a \c AAPLListItem object.
*/

#import "AAPLListItemView.h"
#import "NSColor+AppSpecific.h"
@import ListerKit;

@interface AAPLListItemView()

@property (weak) IBOutlet AAPLCheckBox *statusCheckBox;
@property (weak) IBOutlet NSTextField *textField;

@end

@implementation AAPLListItemView
@synthesize complete = _complete;
@dynamic textField;

#pragma mark - View Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Listen for the NSControlTextDidEndEditingNotification notification to notify the delegate of any
    // updates it has to do its underlying model.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleControlTextDidEndEditingNotification:) name:NSControlTextDidEndEditingNotification object:self.textField];
}

#pragma mark - Lifetime

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidEndEditingNotification object:self.textField];
}


#pragma mark - IBActions

- (IBAction)statusCheckBoxButtonClicked:(NSButton *)sender {
    [self.delegate listItemViewDidToggleCompletionState:self];
}

#pragma mark - Notifications

- (void)handleControlTextDidEndEditingNotification:(NSNotification *)notification {
    [self.delegate listItemViewTextDidEndEditing:self];
}

#pragma mark - Setter Overrides


- (NSString *)stringValue {
    return self.textField.stringValue;
}

- (void)setStringValue:(NSString *)textValue {
    self.textField.stringValue = textValue;
}

- (void)setComplete:(BOOL)complete {
    if (_complete != complete) {
        _complete = complete;
        
        self.statusCheckBox.checked = complete;
        self.textField.textColor = complete ? [NSColor aapl_completeItemTextColor] : [NSColor aapl_incompleteItemTextColor];
        self.textField.enabled = !complete;
    }
}

- (BOOL)isComplete {
    return _complete;
}

- (void)setTintColor:(NSColor *)tintColor {
    self.statusCheckBox.tintColor = tintColor;
}

- (NSColor *)tintColor {
    return self.statusCheckBox.tintColor;
}

@end

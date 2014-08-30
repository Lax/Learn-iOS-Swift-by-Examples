/*
     Copyright (C) 2014 Apple Inc. All Rights Reserved.
     See LICENSE.txt for this sample’s licensing information
     
     Abstract:
     
                  An NSTableCellView subclass that has a few controls that represent the state of a ListItem object.
              
 */

#import "AAPLListItemView.h"
#import "NSColor+AppSpecific.h"
@import ListerKitOSX;

@interface AAPLListItemView()

@property (weak) IBOutlet AAPLCheckBox *statusCheckBox;
@property (weak) IBOutlet NSTextField *textField;

@end

@implementation AAPLListItemView
@synthesize completed = _completed;

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

- (void)setCompleted:(BOOL)completed {
    if (_completed != completed) {
        _completed = completed;
        
        self.statusCheckBox.checked = completed;
        self.textField.textColor = completed ? [NSColor aapl_completeItemTextColor] : [NSColor aapl_incompleteItemTextColor];
    }
}

- (BOOL)isComplete {
    return _completed;
}

- (void)setTintColor:(NSColor *)tintColor {
    self.statusCheckBox.tintColor = tintColor;
}

- (NSColor *)tintColor {
    return self.statusCheckBox.tintColor;
}

@end

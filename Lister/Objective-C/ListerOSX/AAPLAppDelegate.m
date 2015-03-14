/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application delegate.
*/

#import "AAPLAppDelegate.h"
@import ListerKit;

@interface AAPLAppDelegate()

@property (weak) IBOutlet NSMenuItem *todayListMenuItem;

@property (readonly, getter=isCloudEnabled) BOOL cloudEnabled;

@end


@implementation AAPLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[AAPLAppConfiguration sharedAppConfiguration] runHandlerOnFirstLaunch:^{

        // If iCloud is enabled and it's the first launch, we'll show the Today document initially.
        if ([AAPLAppConfiguration sharedAppConfiguration].isCloudAvailable) {
        
            // Make sure that no other documents are visible except for the Today document.
            [[NSDocumentController sharedDocumentController] closeAllDocumentsWithDelegate:nil didCloseAllSelector:NULL contextInfo:NULL];
            
            [self openTodayDocument:nil];
        }
    }];
    
    [self handleUbiquityIdentityDidChangeNotification:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUbiquityIdentityDidChangeNotification:) name:NSUbiquityIdentityDidChangeNotification object:nil];
}

/*!
 * Note that there are two possibile callers for this method. The first is the application delegate if it's
 * the first launch. The other possibility is if you use the keyboard shortcut (Command-T) to open your Today
 * document.
 */
- (IBAction)openTodayDocument:(id)sender {
    [[AAPLTodayListManager sharedTodayListManager] fetchTodayDocumentURLWithCompletionHandler:^(NSURL *url) {
        if (!url) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:true completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                // Configuration of the document can go here...
            }];
        });
    }];
}

- (void)handleUbiquityIdentityDidChangeNotification:(NSNotification *)notification {
    if ([AAPLAppConfiguration sharedAppConfiguration].isCloudAvailable) {
        self.todayListMenuItem.action = @selector(openTodayDocument:);
        self.todayListMenuItem.target = self;
    }
    else {
        self.todayListMenuItem.action = NULL;
        self.todayListMenuItem.target = nil;
    }
}

@end

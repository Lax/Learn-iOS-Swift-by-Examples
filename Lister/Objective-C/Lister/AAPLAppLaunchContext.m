/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A data object for storing context information relevant to how the app was launched.
*/

#import "AAPLAppLaunchContext.h"

@implementation AAPLAppLaunchContext

- (instancetype)initWithUserActivity:(NSUserActivity *)userActivity {
    self = [super init];
    
    if (self) {
        NSParameterAssert(userActivity.userInfo != nil);
        /*
            The URL may be provided as either a URL or a URL path via separate keys. Check first for
            `NSUserActivityDocumentURLKey`, if not provided, obtain the path and create a file URL from it.
        */
        _listURL = userActivity.userInfo[NSUserActivityDocumentURLKey];
        
        if (!_listURL) {
            NSString *listInfoFilePath = userActivity.userInfo[AAPLAppConfigurationUserActivityListURLPathUserInfoKey];
            
            NSAssert(listInfoFilePath != nil, @"The `userInfo` dictionary provided did not contain a URL or a URL path.");
            
            _listURL = [NSURL fileURLWithPath:listInfoFilePath isDirectory:NO];
        }
        
        NSAssert(_listURL != nil, @"`listURL must not be `nil`.");
        
        NSNumber *listInfoColorNumber = userActivity.userInfo[AAPLAppConfigurationUserActivityListColorUserInfoKey];
        
        NSAssert(listInfoColorNumber != nil && listInfoColorNumber.integerValue >= 0 && listInfoColorNumber.integerValue < 6, @"The `userInfo` dictionary provided contains an invalid entry for the list color.");
        // Set the `listColor` by converting the `NSNumber` to an NSInteger and casting to `AAPLListColor`.
        _listColor = (AAPLListColor)listInfoColorNumber.integerValue;
    }
    
    return self;
}

- (instancetype)initWithListerURL:(NSURL *)listerURL {
    self = [super init];
    
    if (self) {
        NSParameterAssert(listerURL.scheme != nil && [listerURL.scheme isEqualToString:@"lister"]);
        
        NSParameterAssert(listerURL.path != nil);
        // Construct a file URL from the path of the lister:// URL.
        _listURL = [NSURL fileURLWithPath:listerURL.path isDirectory:NO];
        
        NSAssert(_listURL != nil, @"`listURL must not be `nil`.");
        
        // Extract the query items to initialize the `listColor` property from the `color` query item.
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:listerURL resolvingAgainstBaseURL:NO];
        NSArray *queryItems = urlComponents.queryItems;
        
        // Construct a predicate to extract the `color` query item.
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", AAPLAppConfigurationListerColorQueryKey];
        NSArray *colorQueryItems = [queryItems filteredArrayUsingPredicate:predicate];
        
        NSAssert(colorQueryItems.count == 1, @"URL provided should contain only one `color` query item.");
        
        NSURLQueryItem *colorQueryItem = colorQueryItems.firstObject;
        
        NSAssert(colorQueryItem.value != nil, @"URL provided contains an invalid value for `color`.");
        // Set the `listColor` by converting the `NSString` value to an NSInteger and casting to `AAPLListColor`.
        _listColor = colorQueryItem.value.integerValue;
    }
    
    return self;
}

@end

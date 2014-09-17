/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Handles application configuration logic and information.
            
*/

#import "AAPLAppConfiguration.h"

NSString *const AAPLAppConfigurationFirstLaunchUserDefaultsKey = @"AAPLAppConfigurationFirstLaunchUserDefaultsKey";
NSString *const AAPLAppConfigurationStorageOptionUserDefaultsKey = @"AAPLAppConfigurationStorageOptionUserDefaultsKey";
NSString *const AAPLAppConfigurationStoredUbiquityIdentityTokenKey = @"com.example.apple-samplecode.Lister.UbiquityIdentityToken";

NSString *const AAPLAppConfigurationUserActivityListColorUserInfoKey = @"listColor";

NSString *const AAPLAppConfigurationListerFileUTI = @"com.example.apple-samplecode.Lister";
NSString *const AAPLAppConfigurationListerFileExtension = @"list";

#if TARGET_OS_IPHONE
NSString *const AAPLAppConfigurationWidgetBundleIdentifier = @"com.example.apple-samplecode.Lister.ListerToday";
#elif TARGET_OS_MAC
NSString *const AAPLAppConfigurationWidgetBundleIdentifier = @"com.example.apple-samplecode.ListerOSX.ListerTodayOSX";

NSString *const AAPLAppConfigurationListerOSXBundleIdentifier = @"com.example.apple-samplecode.ListerOSX";
#endif

@implementation AAPLAppConfiguration

+ (AAPLAppConfiguration *)sharedAppConfiguration {
    static AAPLAppConfiguration *sharedAppConfiguration;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAppConfiguration = [[AAPLAppConfiguration alloc] init];
    });
    
    return sharedAppConfiguration;
}

- (NSString *)localizedTodayDocumentName {
    return NSLocalizedString(@"Today", @"");
}

- (NSString *)localizedTodayDocumentNameAndExtension {
    return [NSString stringWithFormat:@"%@.%@", self.localizedTodayDocumentName, AAPLAppConfigurationListerFileExtension];
}

- (NSString *)defaultListerDraftName {
    return NSLocalizedString(@"List", @"");
}

#pragma mark - Property Overrides

- (AAPLAppStorage)storageOption {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:AAPLAppConfigurationStorageOptionUserDefaultsKey];

    return (AAPLAppStorage)value;
}

- (void)setStorageOption:(AAPLAppStorage)storageOption {
    [[NSUserDefaults standardUserDefaults] setInteger:storageOption forKey:AAPLAppConfigurationStorageOptionUserDefaultsKey];
}

- (BOOL)isCloudAvailable {
    return [[NSFileManager defaultManager] ubiquityIdentityToken] != nil;
}

- (AAPLAppStorageState)storageState {
    return (AAPLAppStorageState) {
        .storageOption = self.storageOption,
        .accountDidChange = [self hasUbiquityIdentityChanged],
        .cloudAvailable = self.isCloudAvailable
    };
}

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults registerDefaults:@{
        AAPLAppConfigurationFirstLaunchUserDefaultsKey: @YES,
#if TARGET_PLATFORM_IPHONE
        AAPLAppConfigurationStorageOptionUserDefaultsKey: @(AAPLAppStorageNotSet)
#endif
    }];

    if ([defaults boolForKey:AAPLAppConfigurationFirstLaunchUserDefaultsKey]) {
        [defaults setBool:NO forKey:AAPLAppConfigurationFirstLaunchUserDefaultsKey];
        
        firstLaunchHandler();
    }
}

#pragma mark - Ubiquity Identity Token Handling (Account Change Info)

- (BOOL)hasUbiquityIdentityChanged {
    BOOL hasChanged = NO;

    id<NSObject, NSCopying, NSCoding> currentToken = [NSFileManager defaultManager].ubiquityIdentityToken;
    id<NSObject, NSCopying, NSCoding> storedToken = [self storedUbiquityIdentityToken];
    
    BOOL currentTokenNilStoredNonNil = !currentToken && storedToken;
    BOOL storedTokenNilCurrentNonNil = !storedToken && currentToken;
    BOOL currentNotEqualStored = currentToken && storedToken && ![currentToken isEqual:storedToken];
    
    if (currentTokenNilStoredNonNil || storedTokenNilCurrentNonNil || currentNotEqualStored) {
        [self persistAccount];

        hasChanged = YES;
    }
    
    return hasChanged;
}

- (void)persistAccount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id<NSObject, NSCopying, NSCoding> token = [NSFileManager defaultManager].ubiquityIdentityToken;

    if (token) {
        // The account has changed.
        NSData *ubiquityIdentityTokenArchive = [NSKeyedArchiver archivedDataWithRootObject:token];

        [defaults setObject:ubiquityIdentityTokenArchive forKey:AAPLAppConfigurationStoredUbiquityIdentityTokenKey];
    }
    else {
        // There is no signed-in account.
        [defaults removeObjectForKey:AAPLAppConfigurationStoredUbiquityIdentityTokenKey];
    }
}

- (id<NSObject, NSCopying, NSCoding>)storedUbiquityIdentityToken {
    id<NSObject, NSCopying, NSCoding> storedToken = nil;
    
    // Determine if the iCloud account associated with this device has changed since the last time the user launched the app.
    NSData *ubiquityIdentityTokenArchive = [[NSUserDefaults standardUserDefaults] objectForKey:AAPLAppConfigurationStoredUbiquityIdentityTokenKey];

    if (ubiquityIdentityTokenArchive) {
        storedToken = [NSKeyedUnarchiver unarchiveObjectWithData:ubiquityIdentityTokenArchive];
    }
    
    return storedToken;
}


@end

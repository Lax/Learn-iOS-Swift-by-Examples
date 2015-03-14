/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Handles application configuration logic and information.
*/

#import "AAPLAppConfiguration.h"

#if TARGET_OS_IPHONE
#import "AAPLListsController.h"
#import "AAPLListInfo.h"
#import "AAPLLocalListCoordinator.h"
#import "AAPLCloudListCoordinator.h"
#endif

NSString *const AAPLAppConfigurationFirstLaunchUserDefaultsKey = @"AAPLAppConfigurationFirstLaunchUserDefaultsKey";
NSString *const AAPLAppConfigurationStorageOptionUserDefaultsKey = @"AAPLAppConfigurationStorageOptionUserDefaultsKey";
NSString *const AAPLAppConfigurationStoredUbiquityIdentityTokenKey = @"com.example.apple-samplecode.Lister.UbiquityIdentityToken";

NSString *const AAPLAppConfigurationUserActivityTypeEditing = @"com.example.apple-samplecode.Lister.editing";
NSString *const AAPLAppConfigurationUserActivityTypeWatch = @"com.example.apple-samplecode.Lister.watch";

NSString *const AAPLAppConfigurationUserActivityListURLPathUserInfoKey = @"listURLUserInfoKey";
NSString *const AAPLAppConfigurationUserActivityListColorUserInfoKey = @"listColorUserInfoKey";

NSString *const AAPLAppConfigurationListerSchemeName = @"lister";
NSString *const AAPLAppConfigurationListerColorQueryKey = @"color";

/*!
 * The \c LISTER_BUNDLE_PREFIX_STRING preprocessor macro is used below to concatenate the value of the
 * \c LISTER_BUNDLE_PREFIX user-defined build setting with other strings. This avoids the need for developers
 * to edit both LISTER_BUNDLE_PREFIX and the code below. \c LISTER_BUNDLE_PREFIX_STRING is equal to
 * \c @"LISTER_BUNDLE_PREFIX", i.e. an \c NSString literal for the value of \c LISTER_BUNDLE_PREFIX. (Multiple
 * \c NSString literals can be concatenated at compile-time to create a new string literal.)
*/
NSString *const AAPLAppConfigurationApplicationGroupsPrimary = @"group."LISTER_BUNDLE_PREFIX_STRING@".Lister.Documents";

NSString *const AAPLAppConfigurationListerFileUTI = @"com.example.apple-samplecode.Lister";
NSString *const AAPLAppConfigurationListerFileExtension = @"list";

#if TARGET_OS_IPHONE
NSString *const AAPLAppConfigurationWidgetBundleIdentifier = LISTER_BUNDLE_PREFIX_STRING@".Lister.ListerToday";
#elif TARGET_OS_MAC
NSString *const AAPLAppConfigurationWidgetBundleIdentifier = LISTER_BUNDLE_PREFIX_STRING@".ListerOSX.ListerTodayOSX";

NSString *const AAPLAppConfigurationListerOSXBundleIdentifier = LISTER_BUNDLE_PREFIX_STRING@".ListerOSX";
#endif

@interface AAPLAppConfiguration ()

@property (nonatomic, readonly) NSUserDefaults *applicationUserDefaults;

@property (nonatomic, readwrite, getter=isFirstLaunch) BOOL firstLaunch;

@end

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

- (NSUserDefaults *)applicationUserDefaults {
    return [[NSUserDefaults alloc] initWithSuiteName:AAPLAppConfigurationApplicationGroupsPrimary];
}

- (NSString *)defaultListerDraftName {
    return NSLocalizedString(@"List", @"");
}

#pragma mark - Property Overrides

- (AAPLAppStorage)storageOption {
    NSInteger value = [self.applicationUserDefaults integerForKey:AAPLAppConfigurationStorageOptionUserDefaultsKey];

    return (AAPLAppStorage)value;
}

- (void)setStorageOption:(AAPLAppStorage)storageOption {
    [self.applicationUserDefaults setInteger:storageOption forKey:AAPLAppConfigurationStorageOptionUserDefaultsKey];
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

- (BOOL)isFirstLaunch {
    [self registerDefaults];
    
    return [self.applicationUserDefaults boolForKey:AAPLAppConfigurationFirstLaunchUserDefaultsKey];
}

- (void)setFirstLaunch:(BOOL)firstLaunch {
    [self.applicationUserDefaults setBool:firstLaunch forKey:AAPLAppConfigurationFirstLaunchUserDefaultsKey];
}

- (void)registerDefaults {
    NSUserDefaults *defaults = self.applicationUserDefaults;
    
    [defaults registerDefaults:@{
    	AAPLAppConfigurationFirstLaunchUserDefaultsKey: @YES,
#if TARGET_PLATFORM_IPHONE
        AAPLAppConfigurationStorageOptionUserDefaultsKey: @(AAPLAppStorageNotSet)
#endif
    }];
}

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler {
    if (self.isFirstLaunch) {
        self.firstLaunch = NO;
        
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
    NSUserDefaults *defaults = self.applicationUserDefaults;
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
    NSData *ubiquityIdentityTokenArchive = [self.applicationUserDefaults objectForKey:AAPLAppConfigurationStoredUbiquityIdentityTokenKey];

    if (ubiquityIdentityTokenArchive) {
        storedToken = [NSKeyedUnarchiver unarchiveObjectWithData:ubiquityIdentityTokenArchive];
    }
    
    return storedToken;
}

#pragma mark - Conveience Methods

#if TARGET_OS_IPHONE

- (id<AAPLListCoordinator>)listsCoordinatorForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler; {
    if ([AAPLAppConfiguration sharedAppConfiguration].storageOption != AAPLAppStorageCloud) {
        // This will be called if the storage option is either `AAPLAppStorageLocal` or `AAPLAppStorageNotSet`.
        return [[AAPLLocalListCoordinator alloc] initWithPathExtension:pathExtension firstQueryUpdateHandler:firstQueryHandler];
    }
    else {
        return [[AAPLCloudListCoordinator alloc] initWithPathExtension:pathExtension firstQueryUpdateHandler:firstQueryHandler];
    }
}

- (id<AAPLListCoordinator>)listsCoordinatorForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler {
    if ([AAPLAppConfiguration sharedAppConfiguration].storageOption != AAPLAppStorageCloud) {
        // This will be called if the storage option is either `AAPLAppStorageLocal` or `AAPLAppStorageNotSet`.
        return [[AAPLLocalListCoordinator alloc] initWithLastPathComponent:lastPathComponent firstQueryUpdateHandler:firstQueryHandler];
    }
    else {
        return [[AAPLCloudListCoordinator alloc] initWithLastPathComponent:lastPathComponent firstQueryUpdateHandler:firstQueryHandler];
    }
}

- (AAPLListsController *)listsControllerForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler {
    id<AAPLListCoordinator> listCoordinator = [self listsCoordinatorForCurrentConfigurationWithPathExtension:pathExtension firstQueryHandler:firstQueryHandler];

    return [[AAPLListsController alloc] initWithListCoordinator:listCoordinator delegateQueue:[NSOperationQueue mainQueue] sortComparator:^NSComparisonResult(AAPLListInfo *lhs, AAPLListInfo *rhs) {
        return [lhs.name localizedCaseInsensitiveCompare:rhs.name];
    }];
}

- (AAPLListsController *)listsControllerForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler {
    id<AAPLListCoordinator> listCoordinator = [self listsCoordinatorForCurrentConfigurationWithLastPathComponent:lastPathComponent firstQueryHandler:firstQueryHandler];
    
    return [[AAPLListsController alloc] initWithListCoordinator:listCoordinator delegateQueue:[NSOperationQueue mainQueue] sortComparator:^NSComparisonResult(AAPLListInfo *lhs, AAPLListInfo *rhs) {
        return [lhs.name localizedCaseInsensitiveCompare:rhs.name];
    }];
}

#endif

@end

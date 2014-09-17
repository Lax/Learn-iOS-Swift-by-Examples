/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Handles application configuration logic and information.
            
*/

@import Foundation;

typedef NS_ENUM(NSInteger, AAPLAppStorage) {
    AAPLAppStorageNotSet = 0,
    AAPLAppStorageCloud,
    AAPLAppStorageLocal
};

typedef struct AAPLAppStorageState {
    AAPLAppStorage storageOption;
    BOOL accountDidChange;
    BOOL cloudAvailable;
} AAPLAppStorageState;

extern NSString *const AAPLAppConfigurationUserActivityListColorUserInfoKey;

extern NSString *const AAPLAppConfigurationListerFileUTI;
extern NSString *const AAPLAppConfigurationListerFileExtension;
extern NSString *const AAPLAppConfigurationWidgetBundleIdentifier;

#if TARGET_OS_MAC
extern NSString *const AAPLAppConfigurationListerOSXBundleIdentifier;
#endif

@interface AAPLAppConfiguration : NSObject

+ (AAPLAppConfiguration *)sharedAppConfiguration;

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler;

@property (nonatomic, readonly, copy) NSString *localizedTodayDocumentName;
@property (nonatomic, readonly, copy) NSString *localizedTodayDocumentNameAndExtension;

@property (nonatomic, readonly, getter=isCloudAvailable) BOOL cloudAvailable;

@property (nonatomic, readonly, copy) NSString *defaultListerDraftName;

@property (nonatomic, readonly) AAPLAppStorageState storageState;

@property (nonatomic) AAPLAppStorage storageOption;

@end

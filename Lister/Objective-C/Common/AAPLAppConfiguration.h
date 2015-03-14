/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
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

// User activity type names used by the Lister app.
extern NSString *const AAPLAppConfigurationUserActivityTypeEditing;
extern NSString *const AAPLAppConfigurationUserActivityTypeWatch;

// Keys used to store relevant list data in the userInfo dictionary of an NSUserActivity for continuation.
extern NSString *const AAPLAppConfigurationUserActivityListURLPathUserInfoKey;
extern NSString *const AAPLAppConfigurationUserActivityListColorUserInfoKey;

// Constants used in assembling and handling the custom lister:// URL scheme.
extern NSString *const AAPLAppConfigurationListerSchemeName;
extern NSString *const AAPLAppConfigurationListerColorQueryKey;

// The identifier for the primary shared application group used for document and defaults storage.
extern NSString *const AAPLAppConfigurationApplicationGroupsPrimary;

// Constants used when indentifying the file types supported by Lister.
extern NSString *const AAPLAppConfigurationListerFileUTI;
extern NSString *const AAPLAppConfigurationListerFileExtension;

// The bundle identifier for the Today widget. Used in communication from the app to the widget.
extern NSString *const AAPLAppConfigurationWidgetBundleIdentifier;

#if TARGET_OS_MAC
extern NSString *const AAPLAppConfigurationListerOSXBundleIdentifier;
#endif

#if TARGET_OS_IPHONE
@protocol AAPLListCoordinator;
@class AAPLListsController;
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

@property (nonatomic, readonly, getter=isFirstLaunch) BOOL firstLaunch;

#if TARGET_OS_IPHONE

/*!
 * Returns an \c AAPLListCoordinator based on the current configuration that queries based on \c pathExtension.
 * For example, if the user has chosen local storage, a local \c AAPLListCoordinator object will be returned.
 */
- (id<AAPLListCoordinator>)listsCoordinatorForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler;

/*!
 * Returns an \c AAPLListCoordinator based on the current configuration that queries based on \c lastPathComponent.
 * For example, if the user has chosen local storage, a local \c AAPLListCoordinator object will be returned.
 */
- (id<AAPLListCoordinator>)listsCoordinatorForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler;

/*!
 * Returns an \c AAPLListsController instance based on the current configuration. For example, if the user has
 * chosen local storage, an \c AAPLListsController object will be returned that uses a local list coordinator.
 * \c pathExtension is passed down to the list coordinator to filter results.
 */
- (AAPLListsController *)listsControllerForCurrentConfigurationWithPathExtension:(NSString *)pathExtension firstQueryHandler:(void (^)(void))firstQueryHandler;

/*!
 * Returns an \c AAPLListsController instance based on the current configuration. For example, if the user has
 * chosen local storage, an \c AAPLListsController object will be returned that uses a local list coordinator.
 * \c lastPathComponent is passed down to the list coordinator to filter results.
 */
- (AAPLListsController *)listsControllerForCurrentConfigurationWithLastPathComponent:(NSString *)lastPathComponent firstQueryHandler:(void (^)(void))firstQueryHandler;

#endif

@end

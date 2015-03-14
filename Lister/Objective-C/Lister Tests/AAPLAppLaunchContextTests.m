/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The test case class for the `AAPLAppLaunchContext` class.
*/

#import "AAPLAppLaunchContext.h"
@import ListerKit;
@import UIKit;
@import XCTest;

NSString *const AAPLAppLaunchContextTestsUserActivityType = @"com.example.apple-samplecode.Lister.testing";

@interface AAPLAppLaunchContextTests : XCTestCase

@property (nonatomic, copy) NSArray *listURLs;
@property (nonatomic) AAPLListColor color;

@end

@implementation AAPLAppLaunchContextTests

- (void)setUp {
    [super setUp];
    
    self.color = AAPLListColorBlue;
    
    self.listURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:AAPLAppConfigurationListerFileExtension subdirectory:@""];
}

- (void)testUserActivityInitializerWithNSUserActivityDocumentURLKey {
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:AAPLAppLaunchContextTestsUserActivityType];
    
    [userActivity addUserInfoEntriesFromDictionary:@{
        NSUserActivityDocumentURLKey: self.listURLs.firstObject,
        AAPLAppConfigurationUserActivityListColorUserInfoKey: @(self.color)
    }];
    
    AAPLAppLaunchContext *launchContext = [[AAPLAppLaunchContext alloc] initWithUserActivity:userActivity];
    
    XCTAssertEqualObjects(launchContext.listURL.absoluteURL, ((NSURL *)self.listURLs.firstObject).absoluteURL);
    XCTAssertEqual(launchContext.listColor, self.color);
}

- (void)testUserActivityInitializerWithAppConfigurationUserActivityListURLUserInfoKey {
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:AAPLAppLaunchContextTestsUserActivityType];
    
    [userActivity addUserInfoEntriesFromDictionary:@{
        AAPLAppConfigurationUserActivityListURLPathUserInfoKey: ((NSURL *)self.listURLs.firstObject).path,
        AAPLAppConfigurationUserActivityListColorUserInfoKey: @(self.color)
    }];
    
    AAPLAppLaunchContext *launchContext = [[AAPLAppLaunchContext alloc] initWithUserActivity:userActivity];
    
    XCTAssertEqualObjects(launchContext.listURL.absoluteURL, ((NSURL *)self.listURLs.firstObject).absoluteURL);
    XCTAssertEqual(launchContext.listColor, self.color);
}

- (void)testUserActivityInitializerPrefersNSUserActivityDocumentURLKey {
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:AAPLAppLaunchContextTestsUserActivityType];
    
    [userActivity addUserInfoEntriesFromDictionary:@{
        NSUserActivityDocumentURLKey: self.listURLs.firstObject,
        AAPLAppConfigurationUserActivityListURLPathUserInfoKey: self.listURLs.lastObject,
        AAPLAppConfigurationUserActivityListColorUserInfoKey: @(self.color)
    }];
    
    AAPLAppLaunchContext *launchContext = [[AAPLAppLaunchContext alloc] initWithUserActivity:userActivity];
    
    XCTAssertEqualObjects(launchContext.listURL.absoluteURL, ((NSURL *)self.listURLs.firstObject).absoluteURL);
    XCTAssertEqual(launchContext.listColor, self.color);
}

- (void)testListerURLSchemeInitializer {
    // Construct a URL with the lister scheme and the file path of the document.
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    urlComponents.scheme = AAPLAppConfigurationListerSchemeName;
    urlComponents.path = ((NSURL *)self.listURLs.firstObject).path;
    
    // Add a query item to encode the color associated with the list.
    NSString *colorQueryValue = [NSString stringWithFormat:@"%ld", (long)self.color];
    NSURLQueryItem *colorQueryItem = [NSURLQueryItem queryItemWithName:AAPLAppConfigurationListerColorQueryKey value:colorQueryValue];
    urlComponents.queryItems = @[colorQueryItem];
    
    AAPLAppLaunchContext *launchContext = [[AAPLAppLaunchContext alloc] initWithListerURL:urlComponents.URL];
    
    XCTAssertEqualObjects(launchContext.listURL.absoluteURL, ((NSURL *)self.listURLs.firstObject).absoluteURL);
    XCTAssertEqual(launchContext.listColor, self.color);
}

@end

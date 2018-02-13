# KeychainTouchID: Using Touch ID with Keychain and LocalAuthentication

The KeychainTouchID sample shows how to store Touch ID protected items to the keychain and how to query for those items with custom message prompts. You’ll see how to use the keychain item accessibility class, which invalidates items when the passcode is removed. You’ll also find out how to use the LocalAuthentication class to invoke Touch ID verification without involving the keychain.

The LocalAuthentication sample is implemented in AAPLLocalAuthenticationTestsViewController while the keychain sample is implemented in AAPLKeychainTestsViewController. Both classes are inherited from AAPLBasicTestViewController which just implements the shared table view handling and launching of the tests defined in AAPLLocalAuthenticationTestsViewController and AAPLKeychainTestsViewController.

Note that the LocalAuthentication framework requires Touch ID. You can implement your own authentication to support devices without Touch ID.

## Requirements

This sample requires a device with Touch ID and passcode enabled. The keychain test will work on devices without Touch ID; iOS will fall back to the passcode prompt in that case. The LocalAuthentication test on the other hand requires Touch ID.

This sample does not support the simulator.

### Build

Xcode 8.0, iOS 10 SDK

### Runtime

iOS 10

Copyright (C) 2016 Apple Inc. All rights reserved.

/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Keychain with Touch ID demo implementation.
*/

#import "AAPLKeychainTestsViewController.h"
#import "AAPLTest.h"

@import Security;
@import LocalAuthentication;

@implementation AAPLKeychainTestsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // prepare the actions which can be tested in this class
    self.tests = @[
        [[AAPLTest alloc] initWithName:@"Add item" details:@"Using SecItemAdd()" selector:@selector(addItemAsync)],
        [[AAPLTest alloc] initWithName:@"Add item (TouchID only)" details:@"Using SecItemAdd()" selector:@selector(addTouchIDItemAsync)],
        [[AAPLTest alloc] initWithName:@"Add item (TouchID and password)" details:@"Using SecItemAdd()" selector:@selector(addPwdItem)],
        [[AAPLTest alloc] initWithName:@"Query for item" details:@"Using SecItemCopyMatching()" selector:@selector(copyMatchingAsync)],
        [[AAPLTest alloc] initWithName:@"Update item" details:@"Using SecItemUpdate()" selector:@selector(updateItemAsync)],
        [[AAPLTest alloc] initWithName:@"Delete item" details:@"Using SecItemDelete()" selector:@selector(deleteItemAsync)],
        [[AAPLTest alloc] initWithName:@"Add protected key" details:@"Using SecKeyCreateRandomKey()" selector:@selector(generateKeyAsync)],
        [[AAPLTest alloc] initWithName:@"Use protected key" details:@"Using SecKeyCreateSignature()" selector:@selector(useKeyAsync)],
        [[AAPLTest alloc] initWithName:@"Delete protected key" details:@"Using SecItemDelete()" selector:@selector(deleteKeyAsync)]
    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length, 0)];
}

- (void)viewDidLayoutSubviews {
    // Set the proper size for the table view based on its content.
    CGFloat height = MIN(self.view.bounds.size.height, self.tableView.contentSize.height);
    self.dynamicViewHeight.constant = height;

    [self.view layoutIfNeeded];
}

#pragma mark - Tests

- (void)copyMatchingAsync {
    NSDictionary *query = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: @"SampleService",
        (id)kSecReturnData: @YES,
        (id)kSecUseOperationPrompt: @"Authenticate to access service password",
    };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTypeRef dataTypeRef = NULL;
        NSString *message;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &dataTypeRef);
        if (status == errSecSuccess) {
            NSData *resultData = (__bridge_transfer NSData *)dataTypeRef;

            NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
        
            message = [NSString stringWithFormat:@"Result: %@\n", result];
        }
        else {
            message = [NSString stringWithFormat:@"SecItemCopyMatching status: %@", [self keychainErrorToString:status]];
        }

        [self printMessage:message inTextView:self.textView];
    });
}

- (void)updateItemAsync {
    NSDictionary *query = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: @"SampleService",
        (id)kSecUseOperationPrompt: @"Authenticate to update your password"
    };
    
    NSData *updatedSecretPasswordTextData = [@"UPDATED_SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *changes = @{
        (id)kSecValueData: updatedSecretPasswordTextData
    };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
        
        NSString *errorString = [self keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemUpdate status: %@", errorString];

        [super printMessage:message inTextView:self.textView];
    });
}

- (void)addItemAsync {
    CFErrorRef error = NULL;
    
    // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocked
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlUserPresence, &error);

    if (sacObject == NULL || error != NULL) {
        NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
        
        self.textView.text = [self.textView.text stringByAppendingString:errorString];
        
        return;
    }
    
    // we want the operation to fail if there is an item which needs authentication so we will use
    // kSecUseNoAuthenticationUI
    NSDictionary *attributes = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: @"SampleService",
        (id)kSecValueData: [@"SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding],
        (id)kSecUseAuthenticationUI: (id)kSecUseAuthenticationUIAllow,
        (id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
    };
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
        
        NSString *errorString = [self keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemAdd status: %@", errorString];

        [self printMessage:message inTextView:self.textView];
    });
}

- (void)addTouchIDItemAsync {
    CFErrorRef error = NULL;

    // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocked
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlTouchIDAny, &error);
    if (sacObject == NULL || error != NULL) {
        NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
        
        self.textView.text = [self.textView.text stringByAppendingString:errorString];
       
        return;
    }

    /*
        We want the operation to fail if there is an item which needs authentication so we will use
        `kSecUseNoAuthenticationUI`.
    */
    NSData *secretPasswordTextData = [@"SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *attributes = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: @"SampleService",
        (id)kSecValueData: secretPasswordTextData,
        (id)kSecUseAuthenticationUI: (id)kSecUseAuthenticationUIAllow,
        (id)kSecAttrAccessControl: (__bridge_transfer id)sacObject
    };

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);

        NSString *message = [NSString stringWithFormat:@"SecItemAdd status: %@", [self keychainErrorToString:status]];

        [self printMessage:message inTextView:self.textView];
    });
}

- (void)addPwdItem {
    CFErrorRef error = NULL;
    
    // Should be the secret invalidated when passcode is removed? If not then use kSecAttrAccessibleWhenUnlocke.
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlTouchIDAny | kSecAccessControlApplicationPassword, &error);
    
    if (sacObject == NULL || error != NULL) {
        NSString *errorString = [NSString stringWithFormat:@"SecItemAdd can't create sacObject: %@", error];
        
        self.textView.text = [self.textView.text stringByAppendingString:errorString];
        
        return;
    }

    LAContext *context = [[LAContext alloc] init];

    [context evaluateAccessControl:sacObject operation:LAAccessControlOperationCreateItem localizedReason:@"Create Item" reply:^(BOOL success, NSError * error) {
        if (success) {
            /*
                We want the operation to fail if there is an item which needs authentication so we will use
                `kSecUseNoAuthenticationUI`.
            */
            NSData *secretPasswordTextData = [@"SECRET_PASSWORD_TEXT" dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *attributes = @{
                (id)kSecClass: (id)kSecClassGenericPassword,
                (id)kSecAttrService: @"SampleService",
                (id)kSecValueData: secretPasswordTextData,
                (id)kSecUseAuthenticationUI: (id)kSecUseAuthenticationUIAllow,
                (id)kSecAttrAccessControl: (__bridge_transfer id)sacObject,
                (id)kSecUseAuthenticationContext: context
            };

            OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
            NSString *error = [self keychainErrorToString:status];
            NSString *message = [NSString stringWithFormat:@"SecItemAdd status: %@", error];

            [self printMessage:message inTextView:self.textView];
        }
        else {
            [self printMessage:error.description inTextView:self.textView];

            CFRelease(sacObject);
        }
    }];
}

- (void)deleteItemAsync {
    NSDictionary *query = @{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrService: @"SampleService"
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        
        NSString *errorString = [self keychainErrorToString:status];
        NSString *message = [NSString stringWithFormat:@"SecItemDelete status: %@", errorString];

        [super printMessage:message inTextView:self.textView];
    });
}

- (void)generateKeyAsync {
    CFErrorRef error = NULL;
    SecAccessControlRef sacObject;

    // Should be the secret invalidated when passcode is removed? If not then use `kSecAttrAccessibleWhenUnlocked`.
    sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                kSecAccessControlTouchIDAny | kSecAccessControlPrivateKeyUsage, &error);

    // Create parameters dictionary for key generation.
    NSDictionary *parameters = @{
        (id)kSecAttrTokenID: (id)kSecAttrTokenIDSecureEnclave,
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
        (id)kSecAttrKeySizeInBits: @256,
        (id)kSecAttrLabel: @"my-se-key",
        (id)kSecPrivateKeyAttrs: @{
            (id)kSecAttrAccessControl: (__bridge_transfer id)sacObject,
            (id)kSecAttrIsPermanent: @YES,
        }
    };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Generate key pair.
        NSError *gen_error = nil;


        id privateKey = CFBridgingRelease(SecKeyCreateRandomKey((__bridge CFDictionaryRef)parameters, (void *)&gen_error));

        if(privateKey != nil) {
            // use the private key in your code
            [self printMessage:@"Key generation success" inTextView:self.textView];
        }
        else {
            NSString *message = [NSString stringWithFormat:@"Key generation error: %@", gen_error];
            [self printMessage:message inTextView:self.textView];
        }
    });

}

- (void)useKeyAsync {
    // Query private key object from the keychain.
    NSDictionary *params = @{
               (id)kSecClass: (id)kSecClassKey,
               (id)kSecAttrKeyType: (id)kSecAttrKeyTypeECSECPrimeRandom,
               (id)kSecAttrKeySizeInBits: @256,
               (id)kSecAttrLabel: @"my-se-key",
               (id)kSecReturnRef: @YES,
               (id)kSecUseOperationPrompt: @"Authenticate to sign data"
               };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Retrieve the key from the keychain.  No authentication is needed at this point.
        SecKeyRef privateKey;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)params, (CFTypeRef *)&privateKey);

        if (status == errSecSuccess) {
            NSError *error;
            NSData *dataToSign = [@"message" dataUsingEncoding:NSUTF8StringEncoding];
            NSData *signature = CFBridgingRelease(SecKeyCreateSignature(privateKey, kSecKeyAlgorithmECDSASignatureMessageX962SHA256, (CFDataRef)dataToSign, (void *)&error));

            NSString *message = [NSString stringWithFormat:@"Key used: %@", error];
            [self printMessage:message inTextView:self.textView];
             
            if (status == errSecSuccess) {
                // In your own code, here is where you'd continue with the signature of the digest.
                id publicKey = CFBridgingRelease(SecKeyCopyPublicKey((SecKeyRef)privateKey));
                Boolean verified = SecKeyVerifySignature((SecKeyRef)publicKey, kSecKeyAlgorithmECDSASignatureMessageX962SHA256, (CFDataRef)dataToSign, (CFDataRef)signature, (void *)&error);
                message = [NSString stringWithFormat:@"signature:%@ verified:%d error:%@", signature, verified, error];
                [self printMessage:message inTextView:self.textView];
            }
            
            CFRelease(privateKey);
        }
        else {
            NSString *message = [NSString stringWithFormat:@"Key not found: %@",[self keychainErrorToString:status]];
            
            [self printMessage:message inTextView:self.textView];
        }
    });
}

- (void)deleteKeyAsync {
    NSDictionary *query = @{
        (id)kSecAttrTokenID: (id)kSecAttrTokenIDSecureEnclave,
        (id)kSecClass: (id)kSecClassKey,
        (id)kSecAttrKeyClass: (id)kSecAttrKeyClassPrivate,
        (id)kSecAttrLabel: @"my-se-key",
        (id)kSecReturnRef: @YES,
    };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);

        NSString *message = [NSString stringWithFormat:@"SecItemDelete status: %@", [self keychainErrorToString:status]];

        [self printMessage:message inTextView:self.textView];
    });
}

#pragma mark - Tools

- (NSString *)keychainErrorToString:(OSStatus)error {
    NSString *message = [NSString stringWithFormat:@"%ld", (long)error];
    
    switch (error) {
        case errSecSuccess:
            message = @"success";
            break;

        case errSecDuplicateItem:
            message = @"error item already exists";
            break;
        
        case errSecItemNotFound :
            message = @"error item not found";
            break;
        
        case errSecAuthFailed:
            message = @"error item authentication failed";
            break;

        default:
            break;
    }
    
    return message;
}

@end
